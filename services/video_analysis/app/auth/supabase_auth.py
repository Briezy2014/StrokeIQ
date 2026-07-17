"""Validate Supabase JWT for Flutter → analysis API (Milestone 9)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx
from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import Settings

_bearer = HTTPBearer(auto_error=False)


@dataclass
class AuthUser:
    user_id: str
    email: str | None = None
    role: str | None = None
    claims: dict[str, Any] | None = None


async def get_settings_dep(request: Request) -> Settings:
    return request.app.state.settings


async def require_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    settings: Settings = Depends(get_settings_dep),
) -> AuthUser:
    """
    Require a valid Supabase user JWT.

    When auth is disabled (local M1–M8 tests), returns a synthetic user.
    """
    if not settings.supabase_auth_required:
        return AuthUser(user_id="local-dev-user", email="dev@localhost", role="authenticated")

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=401,
            detail={
                "error_code": "AUTHENTICATION_EXPIRED",
                "message": "Missing bearer token. Sign in again.",
            },
        )

    token = credentials.credentials
    user = await _verify_supabase_jwt(token, settings)
    _assert_allowlisted(user, settings)
    request.state.auth_user = user
    request.state.access_token = token
    return user


def _assert_allowlisted(user: AuthUser, settings: Settings) -> None:
    """Mirror Flutter VIDEO_ENGINE_V2_ALLOWLIST when set on the backend."""
    raw = (settings.video_engine_v2_allowlist or "").strip()
    if not raw:
        return
    allowed = {part.strip().lower() for part in raw.split(",") if part.strip()}
    email = (user.email or "").strip().lower()
    if email not in allowed:
        raise HTTPException(
            status_code=403,
            detail={
                "error_code": "FORBIDDEN",
                "message": "Video Engine V2 is not enabled for this account yet.",
            },
        )


async def _verify_supabase_jwt(token: str, settings: Settings) -> AuthUser:
    base = (settings.supabase_url or "").rstrip("/")
    anon = settings.supabase_anon_key or ""
    if not base or not anon:
        raise HTTPException(
            status_code=503,
            detail={
                "error_code": "SERVER_UNAVAILABLE",
                "message": "Supabase auth is not configured on the analysis service.",
            },
        )

    # Prefer Auth getUser endpoint (validates signature/expiry server-side).
    url = f"{base}/auth/v1/user"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                url,
                headers={
                    "Authorization": f"Bearer {token}",
                    "apikey": anon,
                },
            )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=503,
            detail={
                "error_code": "SERVER_UNAVAILABLE",
                "message": f"Auth service unavailable: {exc}",
            },
        ) from exc

    if resp.status_code in (401, 403):
        raise HTTPException(
            status_code=401,
            detail={
                "error_code": "AUTHENTICATION_EXPIRED",
                "message": "Session expired. Please sign in again.",
            },
        )
    if resp.status_code >= 500:
        raise HTTPException(
            status_code=503,
            detail={
                "error_code": "SERVER_UNAVAILABLE",
                "message": "Auth service error.",
            },
        )
    if resp.status_code != 200:
        raise HTTPException(
            status_code=401,
            detail={
                "error_code": "AUTHENTICATION_EXPIRED",
                "message": "Invalid authentication token.",
            },
        )

    data = resp.json()
    user_id = data.get("id")
    if not user_id:
        raise HTTPException(
            status_code=401,
            detail={
                "error_code": "AUTHENTICATION_EXPIRED",
                "message": "Invalid authentication token payload.",
            },
        )
    return AuthUser(
        user_id=str(user_id),
        email=data.get("email"),
        role=(data.get("role") or "authenticated"),
        claims=data,
    )
