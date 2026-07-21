// SwimIQ — shrink large phone clips (incl. iPhone HEVC/MOV) for cloud Gemini.
(function () {
  'use strict';

  var ffmpegLoading = null;
  var ffmpegInstance = null;

  function pickMime() {
    var types = ['video/webm;codecs=vp8', 'video/webm;codecs=vp9', 'video/webm'];
    for (var i = 0; i < types.length; i++) {
      if (window.MediaRecorder && MediaRecorder.isTypeSupported(types[i])) {
        return types[i];
      }
    }
    return '';
  }

  function blobToUint8(blob) {
    return blob.arrayBuffer().then(function (buf) {
      return new Uint8Array(buf);
    });
  }

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      if (document.querySelector('script[src="' + src + '"]')) {
        resolve();
        return;
      }
      var s = document.createElement('script');
      s.src = src;
      s.async = true;
      s.onload = function () { resolve(); };
      s.onerror = function () {
        reject(new Error('Could not load video shrink engine. Check internet and try again.'));
      };
      document.head.appendChild(s);
    });
  }

  function getFFmpeg() {
    if (ffmpegInstance) return Promise.resolve(ffmpegInstance);
    if (ffmpegLoading) return ffmpegLoading;
    // 0.11 UMD API is reliable from a plain script tag.
    ffmpegLoading = loadScript(
      'https://cdn.jsdelivr.net/npm/@ffmpeg/ffmpeg@0.11.6/dist/ffmpeg.min.js'
    ).then(async function () {
      if (!window.FFmpeg || !window.FFmpeg.createFFmpeg) {
        throw new Error('FFmpeg failed to load');
      }
      var createFFmpeg = window.FFmpeg.createFFmpeg;
      var fetchFile = window.FFmpeg.fetchFile;
      var ff = createFFmpeg({
        log: false,
        corePath: 'https://cdn.jsdelivr.net/npm/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js',
      });
      await ff.load();
      ffmpegInstance = { ff: ff, fetchFile: fetchFile };
      return ffmpegInstance;
    });
    return ffmpegLoading;
  }

  async function shrinkWithFfmpeg(videoBytes, maxBytes) {
    var pack = await getFFmpeg();
    var ff = pack.ff;
    var fetchFile = pack.fetchFile;
    var inName = 'input.mov';
    var outName = 'output.mp4';
    ff.FS('writeFile', inName, await fetchFile(new Blob([videoBytes])));

    // Aim for ≤10 MB so live sync-v9 uses the fast inline Gemini path (≤12 MB).
    var runs = [
      ['-i', inName, '-vf', 'scale=854:-2', '-c:v', 'libx264', '-preset', 'veryfast', '-b:v', '600k', '-an', '-movflags', '+faststart', outName],
      ['-i', inName, '-vf', 'scale=640:-2', '-c:v', 'libx264', '-preset', 'ultrafast', '-b:v', '350k', '-an', '-movflags', '+faststart', outName],
      ['-i', inName, '-vf', 'scale=640:-2', '-c:v', 'libx264', '-preset', 'ultrafast', '-b:v', '250k', '-t', '45', '-an', '-movflags', '+faststart', outName],
      ['-i', inName, '-vf', 'scale=480:-2', '-c:v', 'libx264', '-preset', 'ultrafast', '-b:v', '180k', '-t', '35', '-an', '-movflags', '+faststart', outName],
    ];

    var last = null;
    for (var i = 0; i < runs.length; i++) {
      try {
        try { ff.FS('unlink', outName); } catch (_) {}
        await ff.run.apply(ff, runs[i]);
        last = ff.FS('readFile', outName);
        if (last && last.byteLength > 0 && last.byteLength <= maxBytes) {
          return last;
        }
      } catch (err) {
        // try next compress level
      }
    }
    if (last && last.byteLength > 0) return last;
    throw new Error(
      'Could not shrink this clip under ' +
        Math.round(maxBytes / (1024 * 1024)) +
        ' MB'
    );
  }

  async function shrinkWithRecorder(videoBytes, maxBytes) {
    var mime = pickMime();
    if (!mime) throw new Error('no recorder');

    var blob = new Blob([videoBytes], { type: 'video/mp4' });
    var url = URL.createObjectURL(blob);
    var video = document.createElement('video');
    video.muted = true;
    video.playsInline = true;
    video.preload = 'auto';
    video.src = url;

    try {
      await new Promise(function (resolve, reject) {
        var t = setTimeout(function () {
          reject(new Error('decode timeout'));
        }, 15000);
        video.onloadedmetadata = function () {
          clearTimeout(t);
          resolve();
        };
        video.onerror = function () {
          clearTimeout(t);
          reject(new Error('decode failed'));
        };
      });

      var maxW = 960;
      var scale = Math.min(1, maxW / (video.videoWidth || maxW));
      var w = Math.max(2, Math.round((video.videoWidth || 960) * scale / 2) * 2);
      var h = Math.max(2, Math.round((video.videoHeight || 540) * scale / 2) * 2);
      var canvas = document.createElement('canvas');
      canvas.width = w;
      canvas.height = h;
      var ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('no canvas');

      var bitrates = [1000000, 600000, 350000, 220000];
      var last = null;
      for (var b = 0; b < bitrates.length; b++) {
        video.currentTime = 0;
        await new Promise(function (resolve) {
          if (video.readyState >= 2) resolve();
          else video.oncanplay = function () { resolve(); };
        });
        var stream = canvas.captureStream(24);
        var recorder = new MediaRecorder(stream, {
          mimeType: mime,
          videoBitsPerSecond: bitrates[b],
        });
        var chunks = [];
        recorder.ondataavailable = function (ev) {
          if (ev.data && ev.data.size) chunks.push(ev.data);
        };
        var stopped = new Promise(function (resolve) {
          recorder.onstop = function () { resolve(); };
        });
        recorder.start(200);
        await video.play();
        var drawing = true;
        function draw() {
          if (!drawing) return;
          ctx.drawImage(video, 0, 0, w, h);
          if (!video.paused && !video.ended) requestAnimationFrame(draw);
        }
        draw();
        await new Promise(function (resolve) {
          video.onended = function () { resolve(); };
          video.onerror = function () { resolve(); };
        });
        drawing = false;
        if (recorder.state !== 'inactive') recorder.stop();
        await stopped;
        stream.getTracks().forEach(function (t) { t.stop(); });
        last = await blobToUint8(new Blob(chunks, { type: mime.split(';')[0] }));
        if (last.byteLength > 0 && last.byteLength <= maxBytes) return last;
      }
      if (last && last.byteLength > 0) return last;
      throw new Error('recorder failed');
    } finally {
      try { video.pause(); } catch (_) {}
      URL.revokeObjectURL(url);
    }
  }

  window.swimiqFitVideoForCloud = async function swimiqFitVideoForCloud(
    videoBytes,
    maxBytes
  ) {
    maxBytes = maxBytes || 10 * 1024 * 1024;
    if (!videoBytes || videoBytes.byteLength <= maxBytes) {
      return videoBytes;
    }

    try {
      var rec = await shrinkWithRecorder(videoBytes, maxBytes);
      if (rec && rec.byteLength > 0 && rec.byteLength <= maxBytes) return rec;
      if (rec && rec.byteLength > 0) videoBytes = rec;
    } catch (_) {}

    return shrinkWithFfmpeg(videoBytes, maxBytes);
  };
})();
