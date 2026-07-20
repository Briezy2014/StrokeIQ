"""Unit tests for streamed Supabase storage downloads."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import httpx
import pytest

from app.config import Settings
from app.services.supabase_bridge import SupabaseBridge, SupabaseBridgeError


def test_write_streamed_response_reports_progress(tmp_path: Path) -> None:
    bridge = SupabaseBridge(
        Settings(supabase_url="https://example.supabase.co", supabase_service_role_key="svc")
    )
    payload = b"abcdefghij" * 30_000  # ~300 KB
    request = httpx.Request("GET", "https://example.supabase.co/storage/v1/object/b/p")
    response = httpx.Response(
        200,
        headers={"content-length": str(len(payload))},
        content=payload,
        request=request,
    )

    updates: list[tuple[float, str]] = []
    dest = tmp_path / "clip.mp4"
    bridge._write_streamed_response(
        response,
        dest,
        progress_callback=lambda fraction, label: updates.append((fraction, label)),
    )

    assert dest.read_bytes() == payload
    assert updates[0][0] == 0.0
    assert updates[-1][0] == 1.0
    assert any(0.0 < fraction < 1.0 for fraction, _ in updates)


def test_write_streamed_response_404(tmp_path: Path) -> None:
    bridge = SupabaseBridge(
        Settings(supabase_url="https://example.supabase.co", supabase_service_role_key="svc")
    )
    request = httpx.Request("GET", "https://example.supabase.co/storage/v1/object/b/p")
    response = httpx.Response(404, content=b"missing", request=request)
    with pytest.raises(SupabaseBridgeError) as exc:
        bridge._write_streamed_response(response, tmp_path / "clip.mp4")
    assert exc.value.code == "INVALID_VIDEO"


def test_download_storage_object_streams(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    bridge = SupabaseBridge(
        Settings(supabase_url="https://example.supabase.co", supabase_service_role_key="svc")
    )
    payload = b"video-bytes-12345"
    request = httpx.Request("GET", "https://example.supabase.co/x")
    response = httpx.Response(
        200,
        headers={"content-length": str(len(payload))},
        content=payload,
        request=request,
    )

    class _FakeClient:
        def __init__(self, *args, **kwargs) -> None:
            pass

        def __enter__(self) -> "_FakeClient":
            return self

        def __exit__(self, *args) -> None:
            return None

        def build_request(self, method: str, url: str, headers=None):
            return httpx.Request(method, url, headers=headers)

        def send(self, req, stream: bool = False):
            assert stream is True
            return response

    monkeypatch.setattr("app.services.supabase_bridge.httpx.Client", _FakeClient)

    dest = tmp_path / "out.mp4"
    seen: list[float] = []
    bridge.download_storage_object(
        bucket="swim-videos",
        storage_path="user/clip.mp4",
        dest=dest,
        progress_callback=lambda fraction, _label: seen.append(fraction),
    )
    assert dest.read_bytes() == payload
    assert seen[0] == 0.0
    assert seen[-1] == 1.0
