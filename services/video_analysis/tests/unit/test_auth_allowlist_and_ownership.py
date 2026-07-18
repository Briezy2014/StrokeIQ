"""Unit tests for V2 allowlist + storage ownership guards."""

from __future__ import annotations

import pytest
from fastapi import HTTPException

from app.auth.supabase_auth import AuthUser, _assert_allowlisted
from app.config import Settings
from app.services.supabase_bridge import SupabaseBridge


def test_allowlist_empty_allows_all() -> None:
    settings = Settings(video_engine_v2_allowlist="")
    user = AuthUser(user_id="u1", email="anyone@example.com")
    _assert_allowlisted(user, settings)  # does not raise


def test_allowlist_blocks_non_member() -> None:
    settings = Settings(video_engine_v2_allowlist="coach@example.com,athlete@example.com")
    user = AuthUser(user_id="u1", email="other@example.com")
    with pytest.raises(HTTPException) as exc:
        _assert_allowlisted(user, settings)
    assert exc.value.status_code == 403
    assert exc.value.detail["error_code"] == "FORBIDDEN"


def test_allowlist_allows_member_case_insensitive() -> None:
    settings = Settings(video_engine_v2_allowlist="Coach@Example.com")
    user = AuthUser(user_id="u1", email="coach@example.com")
    _assert_allowlisted(user, settings)


def test_allowlist_always_allows_master_and_demo() -> None:
    settings = Settings(video_engine_v2_allowlist="someone-else@example.com")
    _assert_allowlisted(
        AuthUser(user_id="m1", email="briezy682014@gmail.com"),
        settings,
    )
    _assert_allowlisted(
        AuthUser(user_id="d1", email="demo@swimiqapp.com"),
        settings,
    )


def test_user_owns_storage_path_by_prefix() -> None:
    bridge = SupabaseBridge(Settings(supabase_url=None, supabase_service_role_key=None))
    assert bridge.user_owns_storage_path(
        user_id="user-123",
        storage_path="user-123/clip.mp4",
    )
    assert not bridge.user_owns_storage_path(
        user_id="user-123",
        storage_path="other-user/clip.mp4",
    )


def test_download_headers_prefer_service_role() -> None:
    bridge = SupabaseBridge(
        Settings(
            supabase_url="https://example.supabase.co",
            supabase_anon_key="anon",
            supabase_service_role_key="service",
        )
    )
    headers = bridge._download_headers(user_access_token="user-jwt")
    assert headers["Authorization"] == "Bearer service"


def test_download_headers_fall_back_to_user_token() -> None:
    bridge = SupabaseBridge(
        Settings(
            supabase_url="https://example.supabase.co",
            supabase_anon_key="anon",
            supabase_service_role_key=None,
        )
    )
    headers = bridge._download_headers(user_access_token="user-jwt")
    assert headers["Authorization"] == "Bearer user-jwt"
    assert headers["apikey"] == "anon"


def test_download_headers_error_when_unconfigured() -> None:
    from app.services.supabase_bridge import SupabaseBridgeError

    bridge = SupabaseBridge(
        Settings(supabase_url=None, supabase_anon_key=None, supabase_service_role_key=None)
    )
    with pytest.raises(SupabaseBridgeError) as exc:
        bridge._download_headers(user_access_token=None)
    assert "storage download" in exc.value.message.lower()
