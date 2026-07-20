"""Supabase Storage + DB bridge for Video Engine V2 (backend secrets only)."""

from __future__ import annotations

import json
import time
from collections.abc import Callable
from pathlib import Path
from typing import Any
from uuid import UUID

import httpx

from app.config import Settings
from app.domain.jobs import AnalysisJob
from app.utils.logging import get_logger

logger = get_logger("video_analysis.supabase")

# Fail-fast for Elite local analysis: short phone clips must not sit for minutes.
_DOWNLOAD_CONNECT_S = 10.0
_DOWNLOAD_READ_IDLE_S = 20.0
_DOWNLOAD_OVERALL_S = 90.0
_DOWNLOAD_TIMEOUT_MESSAGE = (
    "Elite could not finish downloading your video from cloud storage in time. "
    "Even short clips need a working internet link from this PC to Supabase. "
    "Check Wi-Fi, keep START-SWIMIQ-WITH-ELITE.bat open, stay signed in, "
    "then Run Elite Analysis again."
)


class SupabaseBridgeError(Exception):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


class SupabaseBridge:
    """Service-role client. Never expose keys to Flutter."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.base = (settings.supabase_url or "").rstrip("/")
        self.service_key = settings.supabase_service_role_key or ""
        self.anon_key = settings.supabase_anon_key or ""

    @property
    def enabled(self) -> bool:
        return bool(self.base and self.service_key)

    def can_download(self, user_access_token: str | None = None) -> bool:
        """True when service-role OR (url + anon + user session) is available."""
        if self.enabled:
            return True
        return bool(self.base and self.anon_key and user_access_token)

    def _headers(self) -> dict[str, str]:
        if not self.service_key:
            raise SupabaseBridgeError("SERVER_UNAVAILABLE", "SUPABASE_SERVICE_ROLE_KEY missing")
        return {
            "apikey": self.service_key,
            "Authorization": f"Bearer {self.service_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    def download_storage_object(
        self,
        *,
        bucket: str,
        storage_path: str,
        dest: Path,
        user_access_token: str | None = None,
        progress_callback: Callable[[float, str], None] | None = None,
        cancel_check: Callable[[], bool] | None = None,
        overall_timeout_s: float = _DOWNLOAD_OVERALL_S,
    ) -> Path:
        """
        Download a private storage object.

        Prefer the service-role key when configured. For local Windows Elite,
        fall back to the signed-in Flutter user's JWT + anon key so analysis
        works without putting SUPABASE_SERVICE_ROLE_KEY on the machine.

        Streams to disk with short idle/overall timeouts so a hung cloud
        download fails in under ~90s instead of looking stuck forever —
        length of the swim clip does not matter (15s clips re-download too).
        """
        mode, headers = self._download_auth(user_access_token=user_access_token)
        dest.parent.mkdir(parents=True, exist_ok=True)
        # Service role uses /object/... ; user JWT must use /object/authenticated/...
        if mode == "service":
            urls = [f"{self.base}/storage/v1/object/{bucket}/{storage_path}"]
        else:
            urls = [
                (
                    f"{self.base}/storage/v1/object/authenticated/"
                    f"{bucket}/{storage_path}"
                ),
                f"{self.base}/storage/v1/object/{bucket}/{storage_path}",
            ]

        timeout = httpx.Timeout(
            connect=_DOWNLOAD_CONNECT_S,
            read=_DOWNLOAD_READ_IDLE_S,
            write=30.0,
            pool=30.0,
        )
        deadline = time.monotonic() + max(15.0, float(overall_timeout_s))
        started_at = time.monotonic()
        last_error: Exception | None = None

        try:
            with httpx.Client(timeout=timeout) as client:
                for index, url in enumerate(urls):
                    if cancel_check is not None and cancel_check():
                        raise SupabaseBridgeError(
                            "CANCELLED",
                            "Download cancelled",
                        )
                    if time.monotonic() > deadline:
                        raise SupabaseBridgeError(
                            "DOWNLOAD_TIMEOUT",
                            _DOWNLOAD_TIMEOUT_MESSAGE,
                        )
                    try:
                        if progress_callback is not None:
                            progress_callback(
                                0.0,
                                "Connecting to cloud storage",
                            )
                        request = client.build_request("GET", url, headers=headers)
                        resp = client.send(request, stream=True)
                        try:
                            # Authenticated path may 4xx — try plain /object/ once.
                            if (
                                mode == "user"
                                and resp.status_code in {400, 401, 403}
                                and index == 0
                                and len(urls) > 1
                            ):
                                resp.close()
                                continue
                            self._write_streamed_response(
                                resp,
                                dest,
                                progress_callback=progress_callback,
                                cancel_check=cancel_check,
                                deadline=deadline,
                                started_at=started_at,
                            )
                            return dest
                        finally:
                            resp.close()
                    except SupabaseBridgeError:
                        raise
                    except httpx.TimeoutException as exc:
                        last_error = exc
                        logger.warning(
                            "storage download timeout url=%s err=%s",
                            url,
                            exc,
                        )
                        continue
                    except httpx.HTTPError as exc:
                        last_error = exc
                        logger.warning(
                            "storage download http error url=%s err=%s",
                            url,
                            exc,
                        )
                        continue

                # Service-role path: try a signed URL once (often more reliable).
                if mode == "service" and self.enabled:
                    try:
                        if progress_callback is not None:
                            progress_callback(0.0, "Retrying download via signed URL")
                        signed = self.create_signed_url(
                            bucket=bucket,
                            storage_path=storage_path,
                            expires_in=600,
                        )
                        request = client.build_request("GET", signed)
                        resp = client.send(request, stream=True)
                        try:
                            self._write_streamed_response(
                                resp,
                                dest,
                                progress_callback=progress_callback,
                                cancel_check=cancel_check,
                                deadline=deadline,
                                started_at=started_at,
                            )
                            return dest
                        finally:
                            resp.close()
                    except SupabaseBridgeError:
                        raise
                    except httpx.HTTPError as exc:
                        last_error = exc
        except SupabaseBridgeError:
            raise
        except httpx.HTTPError as exc:
            last_error = exc

        if isinstance(last_error, httpx.TimeoutException):
            raise SupabaseBridgeError(
                "DOWNLOAD_TIMEOUT",
                _DOWNLOAD_TIMEOUT_MESSAGE,
            ) from last_error
        raise SupabaseBridgeError(
            "UPLOAD_FAILED",
            f"Storage download failed: {last_error or 'unknown error'}",
        ) from last_error

    def _write_streamed_response(
        self,
        resp: httpx.Response,
        dest: Path,
        *,
        progress_callback: Callable[[float, str], None] | None = None,
        cancel_check: Callable[[], bool] | None = None,
        deadline: float | None = None,
        started_at: float | None = None,
    ) -> None:
        if resp.status_code == 404:
            raise SupabaseBridgeError("INVALID_VIDEO", "Video object not found in storage")
        if resp.status_code >= 400:
            # Body may still be streamed — read a short error snippet.
            detail = ""
            try:
                detail = resp.read().decode("utf-8", errors="replace")[:180]
            except Exception:
                detail = resp.reason_phrase or ""
            raise SupabaseBridgeError(
                "UPLOAD_FAILED",
                f"Storage download HTTP {resp.status_code}: {detail}",
            )

        total = int(resp.headers.get("content-length") or 0)
        downloaded = 0
        last_fraction_reported = -1.0
        last_bytes_reported = 0
        last_heartbeat = time.monotonic()
        started = started_at if started_at is not None else time.monotonic()
        if progress_callback is not None:
            progress_callback(0.0, "Downloading video from cloud")

        with dest.open("wb") as handle:
            for chunk in resp.iter_bytes(chunk_size=256 * 1024):
                if cancel_check is not None and cancel_check():
                    raise SupabaseBridgeError("CANCELLED", "Download cancelled")
                if deadline is not None and time.monotonic() > deadline:
                    raise SupabaseBridgeError(
                        "DOWNLOAD_TIMEOUT",
                        _DOWNLOAD_TIMEOUT_MESSAGE,
                    )
                if not chunk:
                    # Time-based heartbeat while waiting on the socket.
                    now = time.monotonic()
                    if progress_callback is not None and now - last_heartbeat >= 2.0:
                        last_heartbeat = now
                        elapsed = int(now - started)
                        progress_callback(
                            min(0.05, downloaded / max(total, 1) if total else 0.02),
                            f"Waiting on cloud download… {max(0, elapsed)}s",
                        )
                    continue
                handle.write(chunk)
                downloaded += len(chunk)
                last_heartbeat = time.monotonic()
                if progress_callback is None:
                    continue
                if total > 0:
                    fraction = min(1.0, downloaded / total)
                    # Throttle UI/DB updates (~2% steps).
                    if fraction - last_fraction_reported >= 0.02 or fraction >= 1.0:
                        last_fraction_reported = fraction
                        mb = downloaded / (1024 * 1024)
                        total_mb = total / (1024 * 1024)
                        progress_callback(
                            fraction,
                            f"Downloading video · {mb:.1f}/{total_mb:.1f} MB",
                        )
                elif downloaded - last_bytes_reported >= 512 * 1024:
                    # No Content-Length: heartbeat every ~0.5 MB (phone clips).
                    last_bytes_reported = downloaded
                    mb = downloaded / (1024 * 1024)
                    progress_callback(
                        min(0.95, mb / 20.0),
                        f"Downloading video · {mb:.1f} MB",
                    )

        if downloaded <= 0:
            raise SupabaseBridgeError(
                "UPLOAD_FAILED",
                "Cloud storage returned an empty video file.",
            )
        if progress_callback is not None:
            progress_callback(1.0, "Download complete")

    def _download_auth(
        self, *, user_access_token: str | None
    ) -> tuple[str, dict[str, str]]:
        if self.enabled:
            return "service", self._headers()
        if self.base and self.anon_key and user_access_token:
            return "user", {
                "apikey": self.anon_key,
                "Authorization": f"Bearer {user_access_token}",
            }
        missing = []
        if not self.base:
            missing.append("SUPABASE_URL")
        if not self.anon_key:
            missing.append("SUPABASE_ANON_KEY")
        if not user_access_token:
            missing.append("signed-in session token")
        raise SupabaseBridgeError(
            "SERVER_UNAVAILABLE",
            "Elite cannot download your video from Supabase storage. "
            f"Missing: {', '.join(missing)}. "
            "Close ALL Elite server windows, run START-SWIMIQ-WITH-ELITE.bat, "
            "confirm /health has storage_download_configured:true, stay signed in, "
            "then Run Elite Analysis again (do not retry an old failed job).",
        )

    def _download_headers(self, *, user_access_token: str | None) -> dict[str, str]:
        _mode, headers = self._download_auth(user_access_token=user_access_token)
        return headers

    def create_signed_url(
        self,
        *,
        bucket: str,
        storage_path: str,
        expires_in: int = 3600,
    ) -> str:
        if not self.enabled:
            raise SupabaseBridgeError("SERVER_UNAVAILABLE", "Supabase not configured")
        url = f"{self.base}/storage/v1/object/sign/{bucket}/{storage_path}"
        with httpx.Client(timeout=30.0) as client:
            resp = client.post(
                url,
                headers=self._headers(),
                json={"expiresIn": expires_in},
            )
        if resp.status_code >= 400:
            raise SupabaseBridgeError(
                "SERVER_UNAVAILABLE",
                f"Signed URL failed HTTP {resp.status_code}: {resp.text[:200]}",
            )
        data = resp.json()
        signed = data.get("signedURL") or data.get("signedUrl") or data.get("url")
        if not signed:
            raise SupabaseBridgeError("SERVER_UNAVAILABLE", "Signed URL missing in response")
        if signed.startswith("http"):
            return signed
        return f"{self.base}/storage/v1{signed}"

    def upsert_job_row(self, job: AnalysisJob, *, user_id: str, swimmer_key: str) -> None:
        if not self.enabled or not settings_persist(self.settings):
            return
        payload = {
            "id": job.job_id if _is_uuid(job.job_id) else None,
            "user_id": user_id,
            "swimmer_key": swimmer_key,
            "swim_video_id": job.video_id if _is_uuid(job.video_id) else None,
            "video_id": job.video_id,
            "storage_bucket": job.storage_bucket or "swim-videos",
            "storage_path": job.storage_path or "",
            "status": job.status.value if hasattr(job.status, "value") else str(job.status),
            "stage": job.stage,
            "progress": job.progress,
            "engine_version": job.engine_version,
            "engine_name": "video_engine_v2",
            "request_payload": job.request_payload or {},
            "error_code": job.error.error_code if job.error else None,
            "error_message": job.error.message if job.error else None,
            "retry_count": job.retry_count,
            "limitations": job.limitations or [],
            "model_versions": job.model_versions or {},
            "updated_at": job.updated_at.isoformat(),
        }
        # Remove null id so DB can generate when job_id is not uuid
        if payload["id"] is None:
            payload.pop("id")
            # Store mapping in request_payload
        self._rest_upsert("video_analysis_jobs", payload, on_conflict="id")

    def replace_job_children(self, job: AnalysisJob, *, user_id: str) -> None:
        if not self.enabled or not settings_persist(self.settings):
            return
        if not _is_uuid(job.job_id):
            return
        job_id = job.job_id
        # Clear prior children then insert current snapshot
        self._rest_delete("video_analysis_metrics", f"job_id=eq.{job_id}")
        self._rest_delete("video_analysis_events", f"job_id=eq.{job_id}")

        metrics_rows = []
        events_rows = []
        for source, block in (
            ("butterfly", job.butterfly),
            ("underwater", job.underwater),
            ("turn", job.turn),
            ("finish", job.finish),
        ):
            if not block:
                continue
            for m in block.get("metrics") or []:
                name = str(m.get("name") or "metric")
                metrics_rows.append(
                    {
                        "job_id": job_id,
                        "user_id": user_id,
                        "metric_id": str(m.get("metric_id") or f"{source}:{name}"),
                        "name": name,
                        "display_name": m.get("display_name"),
                        "value": m.get("value"),
                        "unit": m.get("unit"),
                        "confidence": m.get("confidence"),
                        "confidence_label": m.get("confidence_label"),
                        "classification": m.get("classification"),
                        "method": m.get("method"),
                        "unavailable_reason": m.get("unavailable_reason"),
                        "supporting_frame_numbers": m.get("supporting_frame_numbers") or [],
                        "supporting_timestamps_ms": m.get("supporting_timestamps_ms") or [],
                        "quality_flags": m.get("quality_flags") or [],
                        "limitations": m.get("limitations") or [],
                        "payload": m,
                    }
                )
            for e in block.get("events") or []:
                et = str(e.get("event_type") or "event")
                frame = e.get("frame_number")
                events_rows.append(
                    {
                        "job_id": job_id,
                        "user_id": user_id,
                        "event_id": str(e.get("event_id") or f"{source}:{et}:{frame}"),
                        "event_type": et,
                        "timestamp_ms": e.get("timestamp_ms"),
                        "frame_number": frame,
                        "confidence": e.get("confidence"),
                        "confidence_label": e.get("confidence_label"),
                        "method": e.get("method"),
                        "unavailable_reason": e.get("unavailable_reason"),
                        "supporting_frames": e.get("supporting_frames") or [],
                        "quality_flags": e.get("quality_flags") or [],
                        "payload": e,
                    }
                )
        if metrics_rows:
            self._rest_insert("video_analysis_metrics", metrics_rows)
        if events_rows:
            self._rest_insert("video_analysis_events", events_rows)

        if job.report is not None:
            report = job.report.get("report") if isinstance(job.report, dict) else None
            self._rest_upsert(
                "video_analysis_reports",
                {
                    "job_id": job_id,
                    "user_id": user_id,
                    "status": "validated"
                    if (job.report or {}).get("gemini_succeeded")
                    else "failed",
                    "model_name": (report or {}).get("model_name")
                    if isinstance(report, dict)
                    else None,
                    "model_version": (report or {}).get("model_version")
                    if isinstance(report, dict)
                    else None,
                    "prompt_version": (report or {}).get("prompt_version")
                    if isinstance(report, dict)
                    else None,
                    "schema_version": (report or {}).get("schema_version")
                    if isinstance(report, dict)
                    else None,
                    "report_json": report,
                    "failure_code": (report or {}).get("failure_code")
                    if isinstance(report, dict)
                    else (job.report or {}).get("limitations"),
                    "failure_reason": (report or {}).get("failure_reason")
                    if isinstance(report, dict)
                    else None,
                    "referenced_metric_ids": (report or {}).get("referenced_metric_ids") or []
                    if isinstance(report, dict)
                    else [],
                    "referenced_event_ids": (report or {}).get("referenced_event_ids") or []
                    if isinstance(report, dict)
                    else [],
                },
                on_conflict="job_id",
            )

        # artifacts from known paths
        artifact_rows = []
        for block in (job.tracking, job.pose, job.butterfly, job.underwater, job.turn, job.finish, job.report):
            if not isinstance(block, dict):
                continue
            paths = block.get("artifact_paths") or {}
            for key, path in paths.items():
                artifact_rows.append(
                    {
                        "job_id": job_id,
                        "user_id": user_id,
                        "artifact_key": str(key),
                        "local_path": str(path),
                        "metadata": {},
                    }
                )
        if artifact_rows:
            self._rest_delete("video_analysis_artifacts", f"job_id=eq.{job_id}")
            self._rest_insert("video_analysis_artifacts", artifact_rows)

    def soft_delete_job(self, job_id: str, *, user_id: str) -> bool:
        if not self.enabled:
            return False
        url = f"{self.base}/rest/v1/video_analysis_jobs?id=eq.{job_id}&user_id=eq.{user_id}"
        with httpx.Client(timeout=30.0) as client:
            resp = client.patch(
                url,
                headers=self._headers(),
                json={"deleted_at": _now_iso(), "status": "cancelled"},
            )
        return resp.status_code < 400

    def insert_feedback(
        self,
        *,
        job_id: str,
        user_id: str,
        feedback_type: str,
        message: str,
        incorrect_fields: list[str] | None = None,
        payload: dict[str, Any] | None = None,
    ) -> None:
        if not self.enabled:
            raise SupabaseBridgeError("SERVER_UNAVAILABLE", "Supabase not configured")
        self._rest_insert(
            "video_analysis_feedback",
            [
                {
                    "job_id": job_id,
                    "user_id": user_id,
                    "feedback_type": feedback_type,
                    "message": message,
                    "incorrect_fields": incorrect_fields or [],
                    "payload": payload or {},
                }
            ],
        )

    def list_jobs_for_user(self, *, user_id: str, swimmer_key: str | None = None) -> list[dict]:
        if not self.enabled:
            return []
        query = f"user_id=eq.{user_id}&deleted_at=is.null&order=created_at.desc"
        if swimmer_key:
            query += f"&swimmer_key=eq.{swimmer_key}"
        return self._rest_select("video_analysis_jobs", query)

    def get_job_row(self, job_id: str) -> dict | None:
        if not self.enabled:
            return None
        rows = self._rest_select("video_analysis_jobs", f"id=eq.{job_id}&limit=1")
        return rows[0] if rows else None

    def user_owns_storage_path(
        self,
        *,
        user_id: str,
        storage_path: str,
        video_id: str | None = None,
    ) -> bool:
        """
        Ownership check before service-role download.

        Accepts either `{user_id}/...` object prefixes or a swim_videos row
        owned by the caller.
        """
        path = (storage_path or "").lstrip("/")
        if not path or not user_id:
            return False
        if path.startswith(f"{user_id}/"):
            return True
        if not self.enabled:
            return False
        from urllib.parse import quote

        encoded = quote(path, safe="")
        if video_id and _is_uuid(video_id):
            rows = self._rest_select(
                "swim_videos",
                f"id=eq.{video_id}&user_id=eq.{user_id}&limit=1",
            )
            if rows and str(rows[0].get("storage_path") or "").lstrip("/") == path:
                return True
        rows = self._rest_select(
            "swim_videos",
            f"storage_path=eq.{encoded}&user_id=eq.{user_id}&limit=1",
        )
        return bool(rows)

    def _rest_select(self, table: str, query: str) -> list[dict]:
        url = f"{self.base}/rest/v1/{table}?{query}"
        with httpx.Client(timeout=30.0) as client:
            resp = client.get(url, headers=self._headers())
        if resp.status_code >= 400:
            logger.warning("supabase select failed table=%s status=%s", table, resp.status_code)
            return []
        data = resp.json()
        return data if isinstance(data, list) else []

    def _rest_insert(self, table: str, rows: list[dict]) -> None:
        url = f"{self.base}/rest/v1/{table}"
        with httpx.Client(timeout=60.0) as client:
            resp = client.post(url, headers=self._headers(), content=json.dumps(rows))
        if resp.status_code >= 400:
            logger.warning(
                "supabase insert failed table=%s status=%s body=%s",
                table,
                resp.status_code,
                resp.text[:300],
            )

    def _rest_upsert(self, table: str, row: dict, *, on_conflict: str) -> None:
        url = f"{self.base}/rest/v1/{table}?on_conflict={on_conflict}"
        headers = {**self._headers(), "Prefer": "resolution=merge-duplicates,return=representation"}
        with httpx.Client(timeout=60.0) as client:
            resp = client.post(url, headers=headers, content=json.dumps(row))
        if resp.status_code >= 400:
            logger.warning(
                "supabase upsert failed table=%s status=%s body=%s",
                table,
                resp.status_code,
                resp.text[:300],
            )

    def _rest_delete(self, table: str, query: str) -> None:
        url = f"{self.base}/rest/v1/{table}?{query}"
        with httpx.Client(timeout=30.0) as client:
            client.delete(url, headers=self._headers())


def settings_persist(settings: Settings) -> bool:
    return bool(settings.supabase_persist_results)


def _is_uuid(value: str | None) -> bool:
    if not value:
        return False
    try:
        UUID(str(value))
        return True
    except Exception:  # noqa: BLE001
        return False


def _now_iso() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).isoformat()
