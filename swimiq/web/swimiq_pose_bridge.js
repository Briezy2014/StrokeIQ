// MediaPipe Pose Landmarker for SwimIQ web (Chrome) — no Flutter native plugins.
// Loaded from index.html; called from Dart via swimiqPoseFromVideoBytes().

const LANDMARK_MAP = {
  0: 'nose',
  11: 'leftShoulder',
  12: 'rightShoulder',
  13: 'leftElbow',
  14: 'rightElbow',
  15: 'leftWrist',
  16: 'rightWrist',
  23: 'leftHip',
  24: 'rightHip',
  25: 'leftKnee',
  26: 'rightKnee',
  27: 'leftAnkle',
  28: 'rightAnkle',
};

let poseLandmarkerPromise = null;

const POSE_TIMEOUT_MS = 12000;

function withTimeout(promise, ms, label) {
  return Promise.race([
    promise,
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`${label} timed out after ${ms / 1000}s`)), ms)
    ),
  ]);
}

async function ensurePoseLandmarker() {
  if (!poseLandmarkerPromise) {
    poseLandmarkerPromise = (async () => {
      const { FilesetResolver, PoseLandmarker } = await import(
        'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/+esm'
      );
      const vision = await FilesetResolver.forVisionTasks(
        'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm'
      );
      return PoseLandmarker.createFromOptions(vision, {
        baseOptions: {
          modelAssetPath:
            'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task',
          delegate: 'GPU',
        },
        runningMode: 'IMAGE',
        numPoses: 1,
      });
    })();
  }
  return poseLandmarkerPromise;
}

async function sampleVideoFrames(videoBytes, maxFrames) {
  const blob = new Blob([videoBytes], { type: 'video/mp4' });
  const url = URL.createObjectURL(blob);
  const video = document.createElement('video');
  video.src = url;
  video.muted = true;
  video.preload = 'auto';

  await new Promise((resolve, reject) => {
    video.onloadedmetadata = resolve;
    video.onerror = () => reject(new Error('Could not load video for pose sampling.'));
  });

  const duration = Number.isFinite(video.duration) ? video.duration : 0;
  const canvas = document.createElement('canvas');
  canvas.width = video.videoWidth || 640;
  canvas.height = video.videoHeight || 360;
  const ctx = canvas.getContext('2d');
  const frames = [];

  if (!ctx || canvas.width === 0) {
    URL.revokeObjectURL(url);
    return frames;
  }

  for (let i = 0; i < maxFrames; i++) {
    const target = duration > 0 ? (duration * (i + 1)) / (maxFrames + 1) : i * 0.5;
    video.currentTime = target;
    await new Promise((resolve) => {
      video.onseeked = resolve;
    });
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    frames.push(canvas.toDataURL('image/jpeg', 0.82));
  }

  URL.revokeObjectURL(url);
  return frames;
}

function landmarksFromResult(result, timestampSec) {
  if (!result?.landmarks?.length) return null;
  const points = result.landmarks[0];
  const landmarks = {};
  for (const [index, name] of Object.entries(LANDMARK_MAP)) {
    const lm = points[Number(index)];
    if (!lm) continue;
    landmarks[name] = {
      x: lm.x,
      y: lm.y,
      visibility: lm.visibility ?? lm.presence ?? 1,
    };
  }
  if (Object.keys(landmarks).length < 6) return null;
  return { timestampSec, landmarks };
}

window.swimiqPoseFromVideoBytes = async function swimiqPoseFromVideoBytes(videoBytes) {
  try {
    const landmarker = await withTimeout(
      ensurePoseLandmarker(),
      POSE_TIMEOUT_MS,
      'MediaPipe model load'
    );
    const frames = await withTimeout(
      sampleVideoFrames(videoBytes, 10),
      POSE_TIMEOUT_MS,
      'Video frame sampling'
    );
    const snapshots = [];

    for (let i = 0; i < frames.length; i++) {
      const image = new Image();
      image.src = frames[i];
      await new Promise((resolve, reject) => {
        image.onload = resolve;
        image.onerror = reject;
      });
      const result = landmarker.detect(image);
      const snapshot = landmarksFromResult(result, i);
      if (snapshot) snapshots.push(snapshot);
    }

    return {
      ok: true,
      framesSampled: frames.length,
      framesWithPose: snapshots.length,
      snapshots,
    };
  } catch (error) {
    return {
      ok: false,
      error: error?.message || String(error),
      framesSampled: 0,
      framesWithPose: 0,
      snapshots: [],
    };
  }
};
