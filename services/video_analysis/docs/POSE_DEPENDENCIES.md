# Milestone 3 — RTMPose / MMPose dependency matrix

Verified in this environment (CPU-only cloud VM):

| Package | Version | Notes |
|---------|---------|-------|
| Python | 3.12.3 | Also targets 3.11 in Docker |
| NumPy | 1.26.4 | Pin `<2` for SciPy 1.11 / torch 2.2 |
| SciPy | 1.11.4 | Required by MMPose dataset imports |
| OpenCV | 4.10.0.84 | `opencv-python` + headless |
| PyTorch | 2.2.2+cpu | CPU-safe mode |
| TorchVision | 0.17.2+cpu | Matches torch 2.2.2 |
| CUDA | unavailable here | GPU mode uses `pose_device=cuda:0` when present |
| MMEngine | 0.10.7 | |
| MMCV | 2.2.0 | CPU wheel for torch2.2 / cp312 |
| MMDetection | 3.3.0 | Patched max mmcv to 2.3.0 for import |
| MMPose | 1.3.2 | Primary pose framework |
| ONNX Runtime | 1.27.x | Used by Milestone 2 RTMDet |

## Model checkpoint

- **Name:** RTMPose-m COCO-WholeBody
- **File:** `models/rtmpose/rtmpose-m_simcc-coco-wholebody_pt-aic-coco_270e-256x192-cd5e845c_20230123.pth`
- **Config:** `models/rtmpose/rtmpose-m_8xb64-270e_coco-wholebody-256x192.py`
- **Input:** 256×192
- **Keypoints:** 133 (COCO-WholeBody)
- **Source:** OpenMMLab MMPose RTMPose project (Apache-2.0)

## CPU vs GPU

- Development default: `POSE_DEVICE=cpu`
- Deployment: `POSE_DEVICE=auto` or `cuda:0`
- Unavailable GPU falls back to CPU with an explicit warning in compat report

## Install (CPU)

```bash
cd services/video_analysis
source .venv/bin/activate
pip install -r requirements.txt
pip install torch==2.2.2 torchvision==0.17.2 --index-url https://download.pytorch.org/whl/cpu
pip install numpy==1.26.4 scipy==1.11.4 opencv-python==4.10.0.84
pip install mmengine==0.10.7
pip install mmcv==2.2.0 -f https://download.openmmlab.com/mmcv/dist/cpu/torch2.2.0/index.html
pip install mmdet==3.3.0 mmpose==1.3.2
# apply mmdet mmcv max-version patch if assert fires (mmcv_maximum_version -> 2.3.0)
python scripts/download_rtmpose.py
```

MediaPipe is **not** a production dependency.
