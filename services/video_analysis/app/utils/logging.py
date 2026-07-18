"""Structured logging helpers for analysis stages."""

from __future__ import annotations

import logging
import traceback
from typing import Any


def configure_logging(level: str = "INFO") -> None:
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    )


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)


def log_stage(
    logger: logging.Logger,
    *,
    stage: str,
    job_id: str | None = None,
    video_id: str | None = None,
    message: str,
    level: int = logging.INFO,
    **extra: Any,
) -> None:
    payload = {
        "stage": stage,
        "job_id": job_id,
        "video_id": video_id,
        "message": message,
        **extra,
    }
    logger.log(level, "%s", payload)


def log_exception(
    logger: logging.Logger,
    *,
    stage: str,
    job_id: str | None,
    video_id: str | None,
    error: BaseException,
) -> None:
    log_stage(
        logger,
        stage=stage,
        job_id=job_id,
        video_id=video_id,
        message=str(error),
        level=logging.ERROR,
        error_type=type(error).__name__,
        stack_trace="".join(
            traceback.format_exception(type(error), error, error.__traceback__)
        ),
    )
