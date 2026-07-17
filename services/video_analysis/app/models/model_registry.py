"""Model weight registry — populated in later milestones."""

from __future__ import annotations

KNOWN_MODELS = {
    "detector": None,  # RTMDet — Milestone 2
    "pose": None,  # RTMPose WholeBody — Milestone 3
}


def list_registered_models() -> dict[str, str | None]:
    return dict(KNOWN_MODELS)
