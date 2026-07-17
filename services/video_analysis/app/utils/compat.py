"""Dependency / hardware compatibility checks for Milestone 3."""

from __future__ import annotations

import platform
import sys
from typing import Any


def collect_compat_report() -> dict[str, Any]:
    report: dict[str, Any] = {
        "python": sys.version.split()[0],
        "platform": platform.platform(),
        "torch": None,
        "torch_cuda_available": False,
        "cuda_version": None,
        "device_mode": "cpu",
        "mmcv": None,
        "mmdet": None,
        "mmpose": None,
        "mmengine": None,
        "onnxruntime": None,
        "opencv": None,
        "numpy": None,
        "errors": [],
        "warnings": [],
    }

    try:
        import numpy as np

        report["numpy"] = np.__version__
    except Exception as exc:  # noqa: BLE001
        report["errors"].append(f"numpy: {exc}")

    try:
        import cv2

        report["opencv"] = cv2.__version__
    except Exception as exc:  # noqa: BLE001
        report["errors"].append(f"opencv: {exc}")

    try:
        import torch

        report["torch"] = torch.__version__
        report["torch_cuda_available"] = bool(torch.cuda.is_available())
        report["cuda_version"] = getattr(torch.version, "cuda", None)
        report["device_mode"] = "gpu" if torch.cuda.is_available() else "cpu"
        if not torch.cuda.is_available():
            report["warnings"].append("CUDA unavailable; using CPU inference mode")
    except Exception as exc:  # noqa: BLE001
        report["errors"].append(f"torch: {exc}")

    for name in ("mmcv", "mmdet", "mmpose", "mmengine", "onnxruntime"):
        try:
            mod = __import__(name)
            report[name] = getattr(mod, "__version__", "unknown")
        except Exception as exc:  # noqa: BLE001
            report["errors"].append(f"{name}: {exc}")

    return report


def assert_pose_stack_ready() -> dict[str, Any]:
    report = collect_compat_report()
    required = ("torch", "mmcv", "mmpose", "mmengine", "numpy", "opencv")
    missing = [k for k in required if not report.get(k)]
    if missing or report["errors"]:
        raise RuntimeError(
            "Pose dependency stack not ready: "
            f"missing={missing} errors={report['errors']}"
        )
    # Import APIs explicitly
    from mmpose.apis import inference_topdown, init_model  # noqa: F401

    return report
