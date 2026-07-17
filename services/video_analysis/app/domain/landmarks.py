"""COCO-WholeBody 133 landmark names for RTMPose WholeBody."""

from __future__ import annotations

# Standard COCO-WholeBody ordering used by MMPose RTMPose WholeBody.
BODY_NAMES = [
    "nose",
    "left_eye",
    "right_eye",
    "left_ear",
    "right_ear",
    "left_shoulder",
    "right_shoulder",
    "left_elbow",
    "right_elbow",
    "left_wrist",
    "right_wrist",
    "left_hip",
    "right_hip",
    "left_knee",
    "right_knee",
    "left_ankle",
    "right_ankle",
]

FOOT_NAMES = [
    "left_big_toe",
    "left_small_toe",
    "left_heel",
    "right_big_toe",
    "right_small_toe",
    "right_heel",
]

FACE_NAMES = [f"face_{i}" for i in range(68)]
LEFT_HAND_NAMES = [f"left_hand_{i}" for i in range(21)]
RIGHT_HAND_NAMES = [f"right_hand_{i}" for i in range(21)]

COCO_WHOLEBODY_KEYPOINT_NAMES: list[str] = (
    BODY_NAMES + FOOT_NAMES + FACE_NAMES + LEFT_HAND_NAMES + RIGHT_HAND_NAMES
)

WHOLEBODY_LANDMARK_COUNT = len(COCO_WHOLEBODY_KEYPOINT_NAMES)  # 133

# Core body joints used for "insufficient visible body parts" checks.
CORE_BODY_INDICES = list(range(17))

# Skeleton edges for diagnostic overlays (body + feet only; face/hands omitted).
BODY_EDGES: list[tuple[str, str]] = [
    ("left_shoulder", "right_shoulder"),
    ("left_shoulder", "left_elbow"),
    ("left_elbow", "left_wrist"),
    ("right_shoulder", "right_elbow"),
    ("right_elbow", "right_wrist"),
    ("left_shoulder", "left_hip"),
    ("right_shoulder", "right_hip"),
    ("left_hip", "right_hip"),
    ("left_hip", "left_knee"),
    ("left_knee", "left_ankle"),
    ("right_hip", "right_knee"),
    ("right_knee", "right_ankle"),
    ("nose", "left_eye"),
    ("nose", "right_eye"),
    ("left_eye", "left_ear"),
    ("right_eye", "right_ear"),
    ("left_ankle", "left_heel"),
    ("left_ankle", "left_big_toe"),
    ("right_ankle", "right_heel"),
    ("right_ankle", "right_big_toe"),
]
