// SwimIQ — shrink large phone clips in Chrome before cloud Gemini analysis.
// Loaded from index.html; called from Dart via swimiqFitVideoForCloud().
(function () {
  'use strict';

  function pickMime() {
    var types = [
      'video/webm;codecs=vp9',
      'video/webm;codecs=vp8',
      'video/webm',
    ];
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

  /**
   * @param {Uint8Array} videoBytes
   * @param {number} maxBytes target ceiling (e.g. 22MB for live 25MB Edge Function)
   * @returns {Promise<Uint8Array>}
   */
  window.swimiqFitVideoForCloud = async function swimiqFitVideoForCloud(
    videoBytes,
    maxBytes
  ) {
    maxBytes = maxBytes || 22 * 1024 * 1024;
    if (!videoBytes || videoBytes.byteLength <= maxBytes) {
      return videoBytes;
    }
    if (!window.MediaRecorder) {
      throw new Error('This browser cannot shrink videos. Use Chrome on desktop.');
    }
    var mime = pickMime();
    if (!mime) {
      throw new Error('This browser cannot shrink videos. Use Chrome on desktop.');
    }

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
          reject(new Error('Video took too long to load for shrinking.'));
        }, 45000);
        video.onloadedmetadata = function () {
          clearTimeout(t);
          resolve();
        };
        video.onerror = function () {
          clearTimeout(t);
          reject(new Error('Could not read this video for shrinking.'));
        };
      });

      var maxW = 1280;
      var scale = Math.min(1, maxW / (video.videoWidth || maxW));
      var w = Math.max(2, Math.round((video.videoWidth || 1280) * scale / 2) * 2);
      var h = Math.max(2, Math.round((video.videoHeight || 720) * scale / 2) * 2);
      var canvas = document.createElement('canvas');
      canvas.width = w;
      canvas.height = h;
      var ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('Could not prepare video shrink canvas.');

      var bitrates = [2500000, 1500000, 900000, 500000];
      var last = null;

      for (var b = 0; b < bitrates.length; b++) {
        var bitrate = bitrates[b];
        video.currentTime = 0;
        await new Promise(function (resolve) {
          if (video.readyState >= 2) resolve();
          else video.oncanplay = function () { resolve(); };
        });

        var stream = canvas.captureStream(30);
        var recorder = new MediaRecorder(stream, {
          mimeType: mime,
          videoBitsPerSecond: bitrate,
        });
        var chunks = [];
        recorder.ondataavailable = function (ev) {
          if (ev.data && ev.data.size) chunks.push(ev.data);
        };

        var stopped = new Promise(function (resolve) {
          recorder.onstop = function () { resolve(); };
        });

        recorder.start(250);
        await video.play();

        var drawing = true;
        var draw = function () {
          if (!drawing) return;
          ctx.drawImage(video, 0, 0, w, h);
          if (!video.paused && !video.ended) {
            requestAnimationFrame(draw);
          }
        };
        draw();

        await new Promise(function (resolve) {
          video.onended = function () { resolve(); };
          video.onerror = function () { resolve(); };
        });
        drawing = false;
        if (recorder.state !== 'inactive') recorder.stop();
        await stopped;
        stream.getTracks().forEach(function (t) { t.stop(); });

        var outBlob = new Blob(chunks, { type: mime.split(';')[0] });
        last = await blobToUint8(outBlob);
        if (last.byteLength > 0 && last.byteLength <= maxBytes) {
          return last;
        }
      }

      if (last && last.byteLength > 0 && last.byteLength < videoBytes.byteLength) {
        return last;
      }
      throw new Error(
        'Could not shrink this clip under ' +
          Math.round(maxBytes / (1024 * 1024)) +
          ' MB. Trim a shorter section and try again.'
      );
    } finally {
      try { video.pause(); } catch (_) {}
      URL.revokeObjectURL(url);
    }
  };
})();
