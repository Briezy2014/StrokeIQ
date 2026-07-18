#!/usr/bin/env python3
"""Download RTMPose WholeBody config + checkpoint for Milestone 3."""

from __future__ import annotations

import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "models" / "rtmpose"
CKPT = (
    "rtmpose-m_simcc-coco-wholebody_pt-aic-coco_270e-256x192-cd5e845c_20230123.pth"
)
CFG = "rtmpose-m_8xb64-270e_coco-wholebody-256x192.py"
CKPT_URL = (
    "https://download.openmmlab.com/mmpose/v1/projects/rtmposev1/" + CKPT
)
CFG_URL = (
    "https://raw.githubusercontent.com/open-mmlab/mmpose/main/projects/rtmpose/"
    "rtmpose/wholebody_2d_keypoint/" + CFG
)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    ckpt_path = OUT / CKPT
    cfg_path = OUT / CFG
    if not ckpt_path.is_file() or ckpt_path.stat().st_size < 1_000_000:
        print(f"Downloading {CKPT_URL}")
        urllib.request.urlretrieve(CKPT_URL, ckpt_path)
    else:
        print(f"Checkpoint present: {ckpt_path}")
    if not cfg_path.is_file():
        print(f"Downloading {CFG_URL}")
        urllib.request.urlretrieve(CFG_URL, cfg_path)
    else:
        print(f"Config present: {cfg_path}")
    print(f"Saved under {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
