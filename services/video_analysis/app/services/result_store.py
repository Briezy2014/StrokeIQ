"""JSON file-backed job store for Milestone 1."""

from __future__ import annotations

import json
import threading
from pathlib import Path
from typing import Any

from app.domain.jobs import AnalysisJob


class ResultStore:
    def __init__(self, path: Path) -> None:
        self._path = path
        self._lock = threading.RLock()
        self._path.parent.mkdir(parents=True, exist_ok=True)
        if not self._path.exists():
            self._write({})

    def _read(self) -> dict[str, Any]:
        if not self._path.exists():
            return {}
        raw = self._path.read_text(encoding="utf-8").strip()
        if not raw:
            return {}
        return json.loads(raw)

    def _write(self, data: dict[str, Any]) -> None:
        tmp = self._path.with_suffix(".tmp")
        tmp.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
        tmp.replace(self._path)

    def save(self, job: AnalysisJob) -> None:
        with self._lock:
            data = self._read()
            data[job.job_id] = job.to_dict()
            self._write(data)

    def get(self, job_id: str) -> AnalysisJob | None:
        with self._lock:
            data = self._read()
            raw = data.get(job_id)
            if raw is None:
                return None
            return AnalysisJob.from_dict(raw)

    def list_ids(self) -> list[str]:
        with self._lock:
            return list(self._read().keys())

    def clear(self) -> None:
        with self._lock:
            self._write({})
