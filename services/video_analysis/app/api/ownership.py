"""Job ownership helpers for authenticated Flutter clients."""

from __future__ import annotations

from fastapi import HTTPException

from app.auth.supabase_auth import AuthUser
from app.domain.jobs import AnalysisJob


def assert_can_access(job: AnalysisJob, user: AuthUser) -> None:
    # Local/dev synthetic user can access all when auth not required path uses local-dev-user
    if user.user_id == "local-dev-user":
        return
    if job.owner_user_id and job.owner_user_id != user.user_id:
        raise HTTPException(
            status_code=403,
            detail={
                "error_code": "UNAUTHORIZED_RESULT_ACCESS",
                "message": "You do not have access to this analysis.",
                "job_id": job.job_id,
            },
        )


def attach_owner(job: AnalysisJob, user: AuthUser, body_athlete_key: str | None) -> None:
    job.owner_user_id = user.user_id
    job.swimmer_key = body_athlete_key or job.swimmer_key
