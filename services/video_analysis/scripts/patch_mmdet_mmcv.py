#!/usr/bin/env python3
"""Allow mmdet==3.3.0 to import with mmcv==2.2.0 (documented compatibility patch)."""

from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    try:
        import mmdet
    except Exception as exc:  # noqa: BLE001
        print(f"mmdet not importable yet: {exc}")
        # Patch file directly
        pass

    candidates = list(Path(sys.prefix).glob("**/site-packages/mmdet/__init__.py"))
    if not candidates:
        print("mmdet __init__.py not found")
        return 1
    path = candidates[0]
    text = path.read_text(encoding="utf-8")
    if "mmcv_maximum_version = '2.3.0'" in text:
        print(f"Already patched: {path}")
        return 0
    if "mmcv_maximum_version = '2.2.0'" not in text:
        print(f"Unexpected mmdet init content at {path}")
        return 1
    path.write_text(
        text.replace(
            "mmcv_maximum_version = '2.2.0'",
            "mmcv_maximum_version = '2.3.0'",
        ),
        encoding="utf-8",
    )
    print(f"Patched {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
