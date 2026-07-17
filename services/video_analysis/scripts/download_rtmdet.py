#!/usr/bin/env python3
"""Download Apache-2.0 RTMDet-n person ONNX weights used by Milestone 2."""

from __future__ import annotations

import sys
import urllib.request
from pathlib import Path

URL = "https://huggingface.co/bukuroo/RTMDet-ONNX/resolve/main/rtmdet-n-person.onnx"
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "models" / "rtmdet-n-person.onnx"


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    if OUT.is_file() and OUT.stat().st_size > 1_000_000:
        print(f"Already present: {OUT} ({OUT.stat().st_size} bytes)")
        return 0
    print(f"Downloading {URL}")
    urllib.request.urlretrieve(URL, OUT)
    print(f"Saved {OUT} ({OUT.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
