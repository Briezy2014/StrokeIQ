import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const BUCKET = "swim-videos";
/** Inline Gemini for clips ≤12 MB — skips File API upload wait (fixes 504 IDLE_TIMEOUT). */
const MAX_INLINE_BYTES = 12 * 1024 * 1024;
/** Edge-safe max clip size (Supabase worker memory limit). */
const MAX_FILE_API_BYTES = 25 * 1024 * 1024;
const DEFAULT_GEMINI_MODEL = "gemini-2.5-flash";
/** Tried in order when ListModels is unavailable; otherwise only API-listed models are used. */
const PREFERRED_GEMINI_MODELS = [
  "gemini-2.5-flash",
  "gemini-2.5-flash-lite",
  "gemini-2.5-pro",
];
const CURRENT_FUNCTION_VERSION = "2026-gemini-sync-v9";
/** Never call these — retired or wrong for new API keys. */
const BLOCKED_GEMINI_MODELS = [
  "gemini-1.5-flash",
  "gemini-1.5-flash-8b",
  "gemini-1.5-pro",
  "gemini-2.0-flash",
  "gemini-2.0-flash-lite",
];
const GEMINI_RETRY_DELAYS_MS = [1500, 3000, 5000];
const GEMINI_FILE_POLL_MS = 2000;
const GEMINI_FILE_MAX_WAIT_MS = 90_000;
const MAX_VIDEO_GEMINI_MODELS = 6;

declare const EdgeRuntime: {
  waitUntil(promise: Promise<unknown>): void;
};
// EdgeRuntime unused in v9 sync path — kept for future background jobs.
void EdgeRuntime;

const GEMINI_SAFETY_SETTINGS = [
  {
    category: "HARM_CATEGORY_HARASSMENT",
    threshold: "BLOCK_MEDIUM_AND_ABOVE",
  },
  {
    category: "HARM_CATEGORY_HATE_SPEECH",
    threshold: "BLOCK_MEDIUM_AND_ABOVE",
  },
  {
    category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
    threshold: "BLOCK_MEDIUM_AND_ABOVE",
  },
  {
    category: "HARM_CATEGORY_DANGEROUS_CONTENT",
    threshold: "BLOCK_MEDIUM_AND_ABOVE",
  },
];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type CoachContext = {
  display_name?: string;
  team?: string;
  personal_bests?: string[];
  goals?: string[];
  recent_sessions?: string[];
};

type PoseMetrics = {
  engine?: string;
  frames_sampled?: number;
  frames_with_pose?: number;
  detection_rate?: number;
  avg_body_line_angle_deg?: number;
  hip_drop_degrees?: number;
  head_lift_score?: number;
  avg_elbow_angle_deg?: number;
  estimated_stroke_cycles?: number;
  kick_symmetry_score?: number;
  body_mechanics_pro?: string;
  body_mechanics_con?: string;
  body_mechanics_suggestions?: string[];
  observations?: string[];
};

type AnalyzeRequest = {
  health_check?: boolean;
  storage_path?: string;
  video_id?: string;
  swimmer?: string;
  event_label?: string;
  title?: string;
  notes?: string;
  pose_metrics?: PoseMetrics;
  coach_context?: CoachContext;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      return jsonError(
        "GEMINI_API_KEY is not configured in Supabase Edge Function secrets.",
        503,
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonError("Missing Authorization header.", 401);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth
      .getUser();
    if (userError || !userData.user) {
      return jsonError("Unauthorized.", 401);
    }

    const body = (await req.json()) as AnalyzeRequest;

    if (body.health_check === true) {
      const model = DEFAULT_GEMINI_MODEL;
      let modelProbeOk = false;
      let modelProbeError: string | null = null;
      try {
        await probeGeminiModel(geminiApiKey, model);
        modelProbeOk = true;
      } catch (error) {
        modelProbeError = error instanceof Error ? error.message : String(error);
      }
      return new Response(
        JSON.stringify({
          ok: modelProbeOk,
          gemini_configured: true,
          function_version: CURRENT_FUNCTION_VERSION,
          gemini_model: model,
          available_models: PREFERRED_GEMINI_MODELS,
          model_probe_ok: modelProbeOk,
          model_probe_error: modelProbeError,
          max_video_mb: 25,
          inline_max_mb: Math.round(MAX_INLINE_BYTES / (1024 * 1024)),
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        },
      );
    }

    const storagePath = body.storage_path?.trim();
    if (!storagePath) {
      return jsonError("storage_path is required.", 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // Synchronous path (worked reliably before) — returns full analysis in one response.
    // Inline video for clips <=12 MB keeps this under Supabase's 150s limit.
    try {
      const analysis = await buildVideoAnalysis(admin, geminiApiKey, body);
      return new Response(JSON.stringify(analysis), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      if (message.toLowerCase().includes("timed out")) {
        return jsonError(message, 504, CURRENT_FUNCTION_VERSION);
      }
      if (message.toLowerCase().includes("too large")) {
        return jsonError(message, 413, CURRENT_FUNCTION_VERSION);
      }
      return jsonError(message, 502, CURRENT_FUNCTION_VERSION);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonError(message, 500);
  }
});

async function buildVideoAnalysis(
  admin: ReturnType<typeof createClient>,
  geminiApiKey: string,
  body: AnalyzeRequest,
): Promise<Record<string, unknown>> {
  const storagePath = body.storage_path?.trim();
  if (!storagePath) {
    throw new Error("storage_path is required.");
  }

  const mimeType = mimeTypeForPath(storagePath);
  const displayName = body.title?.trim() ||
    storagePath.split("/").pop() ||
    "swim-video";

  const objectSize = await getStorageObjectSize(admin, storagePath);
  if (objectSize > MAX_FILE_API_BYTES) {
    throw new Error(
      `Video is too large for analysis (max ~25 MB on server, yours is ~${Math.ceil(objectSize / (1024 * 1024))} MB). Trim the clip and try again.`,
    );
  }

  let geminiJson: Record<string, unknown>;
  let geminiModelUsed = DEFAULT_GEMINI_MODEL;
  let uploadMethod: GeminiUploadMethod = "file_api";
  let geminiFileName: string | null = null;

  try {
    const prompt = buildPrompt(body);
    const inlineEligible = objectSize > 0 && objectSize <= MAX_INLINE_BYTES;

    if (inlineEligible) {
      uploadMethod = "inline";
      const videoBytes = await downloadStorageVideoBytes(admin, storagePath);
      const base64 = bytesToBase64(videoBytes);
      const result = await callGeminiGenerateContentWithFallback(
        geminiApiKey,
        { inline_data: { mime_type: mimeType, data: base64 } },
        prompt,
        MAX_VIDEO_GEMINI_MODELS,
      );
      geminiJson = result.json;
      geminiModelUsed = result.model;
    } else {
      const streamed = await openStorageVideoStream(admin, storagePath);
      if (streamed.byteLength > MAX_FILE_API_BYTES) {
        throw new Error(
          "Video is too large for analysis (max ~25 MB on server). Trim the clip and try again.",
        );
      }

      const uploaded = await uploadVideoStreamToGeminiFile(
        geminiApiKey,
        streamed.body,
        streamed.byteLength,
        mimeType,
        displayName,
      );
      geminiFileName = uploaded.name;
      await waitForGeminiFileActive(geminiApiKey, uploaded.name);
      const result = await callGeminiGenerateContentWithFallback(
        geminiApiKey,
        { file_data: { mime_type: mimeType, file_uri: uploaded.uri } },
        prompt,
        MAX_VIDEO_GEMINI_MODELS,
      );
      geminiJson = result.json;
      geminiModelUsed = result.model;
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(message);
  } finally {
    if (geminiFileName) {
      await deleteGeminiFile(geminiApiKey, geminiFileName).catch(() => {});
    }
  }

  const candidate = geminiJson?.candidates?.[0];
  const finishReason = candidate?.finishReason;
  if (finishReason === "SAFETY" || finishReason === "BLOCKLIST") {
    throw new Error(
      "SwimIQ could not generate coaching feedback for this clip. Try a shorter pool-only video.",
    );
  }

  const textPart = candidate?.content?.parts?.find(
    (part: { text?: string }) => typeof part.text === "string",
  )?.text;

  if (!textPart) {
    throw new Error("Gemini returned an empty analysis.");
  }

  const parsed = JSON.parse(textPart) as Record<string, unknown>;
  return normalizeAnalysis(
    parsed,
    body,
    uploadMethod,
    geminiModelUsed,
  );
}

async function persistAnalysisToDb(
  admin: ReturnType<typeof createClient>,
  analysis: Record<string, unknown>,
): Promise<void> {
  const videoId = analysis.swim_video_id;
  if (!videoId || typeof videoId !== "string") return;

  const swimmer = String(analysis.swimmer ?? "");
  const row = {
    swim_video_id: videoId,
    swimmer,
    swimmer_name: swimmer,
    summary: analysis.summary ?? "",
    strengths: analysis.strengths ?? "",
    improvements: analysis.improvements ?? "",
    technique_score: analysis.technique_score ?? 70,
    pace_score: analysis.pace_score ?? 70,
    overall_score: analysis.overall_score ?? 70,
    analysis_json: analysis.analysis_json ?? {},
  };

  const { error } = await admin.from("swim_video_analyses").insert(row);
  if (error) {
    console.error("Failed to persist swim_video_analysis:", error.message);
    throw new Error(`Could not save analysis: ${error.message}`);
  }
}

async function persistFailedAnalysis(
  admin: ReturnType<typeof createClient>,
  body: AnalyzeRequest,
  message: string,
): Promise<void> {
  const videoId = body.video_id?.trim();
  if (!videoId) return;

  const swimmer = body.swimmer?.trim() ||
    body.coach_context?.display_name?.trim() ||
    "swimmer";

  const { error } = await admin.from("swim_video_analyses").insert({
    swim_video_id: videoId,
    swimmer,
    swimmer_name: swimmer,
    summary: "Analysis unavailable",
    strengths: "",
    improvements: "",
    technique_score: 70,
    pace_score: 70,
    overall_score: 70,
    analysis_json: {
      engine: "swimiq-v1-notes-mediapipe",
      gemini_fallback_reason: message,
      gemini_error_raw: message,
      function_version: CURRENT_FUNCTION_VERSION,
      sections: {},
    },
  });

  if (error) {
    console.error("Failed to persist failed analysis:", error.message);
  }
}

const analysisResponseSchema = {
  type: "OBJECT",
  properties: {
    quick_summary: { type: "STRING" },
    quick_pro: { type: "STRING" },
    quick_con: { type: "STRING" },
    next_race_goal: { type: "STRING" },
    what_the_video_shows: { type: "ARRAY", items: { type: "STRING" } },
    top_3_priorities: { type: "ARRAY", items: { type: "STRING" } },
    dryland_focus: { type: "STRING" },
    estimated_time_savings: { type: "STRING" },
    coach_notes_for_next_race: { type: "STRING" },
    technique_score: { type: "INTEGER" },
    pace_score: { type: "INTEGER" },
    overall_score: { type: "INTEGER" },
    overall_summary: { type: "STRING" },
    technique_summary: { type: "STRING" },
    pace_summary: { type: "STRING" },
  },
  required: [
    "quick_summary",
    "quick_pro",
    "quick_con",
    "next_race_goal",
    "top_3_priorities",
    "dryland_focus",
    "estimated_time_savings",
    "coach_notes_for_next_race",
    "technique_score",
    "pace_score",
    "overall_score",
    "overall_summary",
    "technique_summary",
    "pace_summary",
  ],
};

function buildPrompt(body: AnalyzeRequest): string {
  const ctx = body.coach_context ?? {};
  const contextLines = [
    ctx.display_name ? `Athlete: ${ctx.display_name}` : null,
    ctx.team ? `Team: ${ctx.team}` : null,
    body.event_label ? `Event: ${body.event_label}` : null,
    body.title ? `Video title: ${body.title}` : null,
    body.notes ? `Uploader notes: ${body.notes}` : null,
    ctx.personal_bests?.length
      ? `Personal bests: ${ctx.personal_bests.join("; ")}`
      : null,
    ctx.goals?.length ? `Goals: ${ctx.goals.join("; ")}` : null,
    ctx.recent_sessions?.length
      ? `Recent training: ${ctx.recent_sessions.join("; ")}`
      : null,
  ].filter(Boolean).join("\n");

  const pose = body.pose_metrics;
  const poseLines = pose
    ? [
        pose.engine ? `Pose engine: ${pose.engine}` : null,
        pose.frames_with_pose != null && pose.frames_sampled != null
          ? `Pose detected in ${pose.frames_with_pose}/${pose.frames_sampled} sampled frames`
          : null,
        pose.avg_body_line_angle_deg != null
          ? `Average body line angle: ${pose.avg_body_line_angle_deg.toFixed(1)}°`
          : null,
        pose.hip_drop_degrees != null
          ? `Hip drop estimate: ${pose.hip_drop_degrees.toFixed(1)}`
          : null,
        pose.head_lift_score != null
          ? `Head lift score: ${pose.head_lift_score.toFixed(1)} (lower = head down, hips up)`
          : null,
        pose.avg_elbow_angle_deg != null
          ? `Average elbow angle: ${pose.avg_elbow_angle_deg.toFixed(1)}°`
          : null,
        pose.estimated_stroke_cycles != null
          ? `Estimated arm cycles in clip: ${pose.estimated_stroke_cycles}`
          : null,
        pose.kick_symmetry_score != null
          ? `Kick symmetry score: ${pose.kick_symmetry_score.toFixed(0)}/100`
          : null,
        pose.body_mechanics_pro
          ? `MediaPipe body-mechanics PRO: ${pose.body_mechanics_pro}`
          : null,
        pose.body_mechanics_con
          ? `MediaPipe body-mechanics CON: ${pose.body_mechanics_con}`
          : null,
        pose.body_mechanics_suggestions?.length
          ? `MediaPipe suggestions: ${pose.body_mechanics_suggestions.join("; ")}`
          : null,
        pose.observations?.length
          ? `Pose observations: ${pose.observations.join("; ")}`
          : null,
      ].filter(Boolean).join("\n")
    : "";

  return `You are an elite NCAA Division I swim coach and biomechanics analyst reviewing race footage for SwimIQ.

AUDIENCE: Youth swimmers (ages 8–18), their parents, and club/college coaches who expect D1-level precision.
Write so a parent can read this with their child, but use the same technical depth a Ohio State / Michigan / Texas deck coach would expect:
underwater breakout distance, hip-driven kick, high-elbow catch, breathing pattern cost, turn momentum, finish projection, and race-shape (front-half vs back-half).

STRICT SAFETY RULES:
- Supportive, encouraging coach tone only — never harsh, scary, shaming, or sarcastic.
- Comment ONLY on swimming technique: starts, underwater, stroke, kick, turns, finish, pacing, race strategy.
- NEVER comment on appearance, body shape, weight, clothing, or anything non-swim-related.
- NO medical advice, injury diagnosis, or treatment — say "ask your coach" for health questions.
- NO profanity, adult themes, bullying language, or personal insults.
- If the video is unclear, describe what you CAN see; do not invent details.

BODY MECHANICS PRECISION (REQUIRED):
- Be specific about body angles and positions swimmers and parents can act on:
  hips up / hips near the surface vs hips sinking, head down in streamline vs head lifting,
  flat body line (shoulder–hip–ankle), elbow angle at the catch, kick from the hips, kick symmetry.
PLAIN LANGUAGE (REQUIRED for youth swimmers):
- Use real swim words swimmers hear on deck: streamline, take your marks, breakout, body line, catch, kick.
- NEVER tell swimmers to stare at the starter. Before the call: eyes slightly down or out, ready to go.
- On "take your marks": tighten the body and stay coiled. On the beep: explode into streamline.
- After a swim term, add a short plain-language hint in parentheses when it helps parents, e.g.
  "tight streamline (arms squeezed behind your ears)."
- BAD: "Drive full extension on the last stroke at the wall."
- GOOD: "Finish your final stroke completely before touching the wall. Reach all the way forward, keep driving through the water, and touch with a fully extended arm instead of shortening or gliding into the wall."
- Explain less common terms when needed:
  breakout → coming up for your first stroke after underwater (keep "breakout" if the sentence already explains it)
  over-gliding → pausing too long with arms stretched out
  body line → flat body position on the water (shoulder–hip–ankle in a line)
  high-elbow catch → pull with your elbow high, like scooping water with your forearm
- When MediaPipe pose metrics are provided below, you MUST weave them into quick_pro, quick_con,
  and at least one top_3_priorities item. Do not ignore automated body-line data.
- quick_pro should name a body-mechanics strength when pose data supports it.
- quick_con should name the main body-mechanics limiter (hips, head, body line, elbow, or kick) when visible.
- For start feedback use plain deck language, e.g. "Work on your start — eyes slightly down or out before the call, tighten on take your marks, explode on the beep into your streamline underwater." Never say "start phase needs sharpening" or "block snap" without explaining what to do.

Watch the attached swim video carefully. Combine what you SEE in the footage with the athlete context and on-device pose metrics below.

Athlete context:
${contextLines || "(no extra context)"}

On-device pose metrics from MediaPipe (automated body-line estimates — not official timing):
${poseLines || "(pose metrics not available for this clip)"}

Return JSON only (no markdown). Be specific about visible technique (body line, kick, pull, breathing, turns, underwater, finish).
Reference the pose metrics when they support what you see, but do not invent numbers beyond them.
Use clear sentences a parent can read with their swimmer — include enough detail to impress a college recruiter or D1 assistant coach.
Scores are 0-100 integers where 50 = developing, 70 = strong club, 85+ = elite / D1-ready execution on what you can see.
technique_score = stroke mechanics (body line, catch, kick, breathing, turns).
pace_score = tempo, rhythm, and race management (start speed, middle hold, back-half fade or build).
overall_score = holistic race readiness combining both.
Provide overall_summary, technique_summary, and pace_summary — each ONE or TWO short sentences in plain language for swimmers ages 10–18.
Each summary MUST start with its topic label and include both a strength and a work-on cue:
- overall_summary: race readiness (how complete and competitive the swim looked).
- technique_summary: stroke mechanics (body line, catch, kick, breathing, turns).
- pace_summary: tempo and rhythm (start speed, middle hold, back-half fade or build).
Format example: "Race readiness — Going well: [strength]. Work on: [limiter]."
Provide a quick_pro (one strength) and quick_con (one limiter) as short bullet-ready sentences with body-mechanics detail when relevant.
quick_pro and quick_con are shown to youth swimmers — use clear words, not jargon like "pro" or "con".
Provide next_race_goal as one concrete race target sentence tied to technique.
For top_3_priorities: three race-day execution cues for the NEXT RACE (starts, underwater, tempo, breathing, finish) — NOT practice homework or filming reminders.
For dryland_focus: list 3–4 specific dryland exercises with sets/reps (bands, planks, mobility) — NEVER pool sets or in-water drills.
For estimated_time_savings: REQUIRED. List 2–4 specific limiters you saw in the video and/or MediaPipe pose data.
Format each line as: "• [what you saw]: 0.XX–0.XXs" then end with "Combined if you nail these on [event]: X.XX–X.XXs".
Every number must tie to a visible limiter (start, hips, head, kick, tempo, finish). Never say "add upload notes" or generic placeholders.
For coach_notes_for_next_race: REQUIRED. Write 5–7 short bullets speaking directly to the swimmer (use "you" or their name).
Race-day steps a 10-year-old can follow but still useful for an 18-year-old:
behind the blocks (eyes slightly down or out), take your marks (tighten body), explode on the beep, tight streamline underwater off the start and walls,
mid-race cue from quick_con, last meters, finish.
Use proper swim words: streamline (not "arrow position"), take your marks, breakout. Add brief parent-friendly hints in parentheses only when helpful.
No admin labels like "Event:" or "PB reference" — sound like a supportive pool-deck coach.
Do not invent split times or stroke counts you cannot verify from the video.
Do not include disclaimers about missing AI or frame-by-frame analysis.`;
}

type GeminiVideoPart =
  | { inline_data: { mime_type: string; data: string } }
  | { file_data: { mime_type: string; file_uri: string } };

type GeminiUploadMethod = "inline" | "file_api";

async function getStorageObjectSize(
  admin: ReturnType<typeof createClient>,
  storagePath: string,
): Promise<number> {
  const normalized = storagePath.replace(/^\/+/, "");
  const parts = normalized.split("/");
  const fileName = parts.pop() ?? normalized;
  const folder = parts.join("/");

  const { data, error } = await admin.storage.from(BUCKET).list(folder, {
    limit: 100,
    search: fileName,
  });

  if (error || !data?.length) {
    return 0;
  }

  const match = data.find((entry) => entry.name === fileName);
  if (!match) return 0;

  const metaSize = match.metadata &&
    typeof match.metadata === "object" &&
    "size" in match.metadata
    ? Number((match.metadata as { size?: number }).size)
    : NaN;
  if (Number.isFinite(metaSize) && metaSize > 0) return metaSize;

  const listedSize = Number(match.size);
  return Number.isFinite(listedSize) && listedSize > 0 ? listedSize : 0;
}

async function openStorageVideoStream(
  admin: ReturnType<typeof createClient>,
  storagePath: string,
): Promise<{ body: ReadableStream<Uint8Array>; byteLength: number }> {
  const { data: signed, error } = await admin.storage
    .from(BUCKET)
    .createSignedUrl(storagePath, 3600);

  if (error || !signed?.signedUrl) {
    throw new Error(
      `Could not access video in storage: ${error?.message ?? "missing signed URL"}`,
    );
  }

  const response = await fetch(signed.signedUrl);
  if (!response.ok || !response.body) {
    throw new Error(
      `Could not download video from storage (HTTP ${response.status}).`,
    );
  }

  const lengthHeader = response.headers.get("content-length");
  const byteLength = lengthHeader ? Number(lengthHeader) : 0;
  if (Number.isFinite(byteLength) && byteLength > MAX_FILE_API_BYTES) {
    throw new Error(
      "Video is too large for analysis (max ~50 MB on server). Trim the clip and try again.",
    );
  }

  return { body: response.body, byteLength: byteLength || MAX_FILE_API_BYTES };
}

async function downloadStorageVideoBytes(
  admin: ReturnType<typeof createClient>,
  storagePath: string,
): Promise<Uint8Array> {
  const { data, error } = await admin.storage.from(BUCKET).download(storagePath);
  if (error || !data) {
    throw new Error(
      `Could not download video from storage: ${error?.message ?? "empty file"}`,
    );
  }
  const bytes = new Uint8Array(await data.arrayBuffer());
  if (bytes.length > MAX_FILE_API_BYTES) {
    throw new Error(
      "Video is too large for analysis (max ~25 MB on server). Trim the clip and try again.",
    );
  }
  return bytes;
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const slice = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode.apply(null, Array.from(slice));
  }
  return btoa(binary);
}

async function uploadVideoStreamToGeminiFile(
  apiKey: string,
  videoStream: ReadableStream<Uint8Array>,
  byteLength: number,
  mimeType: string,
  displayName: string,
): Promise<{ name: string; uri: string }> {
  const startResponse = await fetch(
    `https://generativelanguage.googleapis.com/upload/v1beta/files?key=${apiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Upload-Protocol": "resumable",
        "X-Goog-Upload-Command": "start",
        "X-Goog-Upload-Header-Content-Length": String(byteLength),
        "X-Goog-Upload-Header-Content-Type": mimeType,
      },
      body: JSON.stringify({ file: { display_name: displayName } }),
    },
  );

  if (!startResponse.ok) {
    const errText = await startResponse.text();
    throw new Error(`Gemini file upload start failed: ${errText}`);
  }

  const uploadUrl = startResponse.headers.get("x-goog-upload-url");
  if (!uploadUrl) {
    throw new Error("Gemini file upload missing x-goog-upload-url header.");
  }

  const uploadResponse = await fetch(uploadUrl, {
    method: "POST",
    headers: {
      "Content-Length": String(byteLength),
      "X-Goog-Upload-Offset": "0",
      "X-Goog-Upload-Command": "upload, finalize",
    },
    body: videoStream,
  });

  if (!uploadResponse.ok) {
    const errText = await uploadResponse.text();
    throw new Error(`Gemini file upload failed: ${errText}`);
  }

  const uploadJson = await uploadResponse.json();
  const file = uploadJson?.file as { name?: string; uri?: string } | undefined;
  if (!file?.uri || !file?.name) {
    throw new Error("Gemini file upload returned invalid file metadata.");
  }

  return { name: file.name, uri: file.uri };
}

async function uploadVideoToGeminiFile(
  apiKey: string,
  videoBytes: Uint8Array,
  mimeType: string,
  displayName: string,
): Promise<{ name: string; uri: string }> {
  const startResponse = await fetch(
    `https://generativelanguage.googleapis.com/upload/v1beta/files?key=${apiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Upload-Protocol": "resumable",
        "X-Goog-Upload-Command": "start",
        "X-Goog-Upload-Header-Content-Length": String(videoBytes.length),
        "X-Goog-Upload-Header-Content-Type": mimeType,
      },
      body: JSON.stringify({ file: { display_name: displayName } }),
    },
  );

  if (!startResponse.ok) {
    const errText = await startResponse.text();
    throw new Error(`Gemini file upload start failed: ${errText}`);
  }

  const uploadUrl = startResponse.headers.get("x-goog-upload-url");
  if (!uploadUrl) {
    throw new Error("Gemini file upload missing x-goog-upload-url header.");
  }

  const uploadResponse = await fetch(uploadUrl, {
    method: "POST",
    headers: {
      "Content-Length": String(videoBytes.length),
      "X-Goog-Upload-Offset": "0",
      "X-Goog-Upload-Command": "upload, finalize",
    },
    body: videoBytes,
  });

  if (!uploadResponse.ok) {
    const errText = await uploadResponse.text();
    throw new Error(`Gemini file upload failed: ${errText}`);
  }

  const uploadJson = await uploadResponse.json();
  const file = uploadJson?.file as { name?: string; uri?: string } | undefined;
  if (!file?.uri || !file?.name) {
    throw new Error("Gemini file upload returned invalid file metadata.");
  }

  return { name: file.name, uri: file.uri };
}

async function waitForGeminiFileActive(
  apiKey: string,
  fileName: string,
): Promise<void> {
  const started = Date.now();
  while (Date.now() - started < GEMINI_FILE_MAX_WAIT_MS) {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/${fileName}?key=${apiKey}`,
    );
    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Gemini file status check failed: ${errText}`);
    }
    const fileJson = await response.json();
    const state = (fileJson?.state ?? fileJson?.file?.state) as
      | string
      | undefined;
    if (state === "ACTIVE") return;
    if (state === "FAILED") {
      throw new Error("Gemini could not process this video file.");
    }
    await new Promise((resolve) => setTimeout(resolve, GEMINI_FILE_POLL_MS));
  }
  throw new Error(
    "Gemini video processing timed out — try a shorter clip.",
  );
}

async function deleteGeminiFile(apiKey: string, fileName: string): Promise<void> {
  await fetch(
    `https://generativelanguage.googleapis.com/v1beta/${fileName}?key=${apiKey}`,
    { method: "DELETE" },
  );
}

async function callGeminiGenerateContent(
  apiKey: string,
  model: string,
  videoPart: GeminiVideoPart,
  prompt: string,
): Promise<Record<string, unknown>> {
  const geminiPayload = {
    contents: [
      {
        parts: [
          videoPart,
          { text: prompt },
        ],
      },
    ],
    safetySettings: GEMINI_SAFETY_SETTINGS,
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: analysisResponseSchema,
    },
  };

  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiPayload),
    },
  );

  if (!geminiResponse.ok) {
    const errText = await geminiResponse.text();
    const friendly = friendlyGeminiHttpError(errText, model, geminiResponse.status);
    throw new Error(friendly ?? `Gemini API error (${geminiResponse.status}): ${errText}`);
  }

  return await geminiResponse.json() as Record<string, unknown>;
}

function isBlockedGeminiModel(model: string): boolean {
  const lower = model.toLowerCase();
  if (BLOCKED_GEMINI_MODELS.some((blocked) => lower.includes(blocked))) {
    return true;
  }
  return lower.includes("gemini-1.5") || lower.includes("gemini-2.0");
}

function filterAllowedModels(models: string[]): string[] {
  return models.filter((model) => !isBlockedGeminiModel(model));
}

async function listGeminiVideoModels(apiKey: string): Promise<string[]> {
  // Deprecated for video analysis — kept for diagnostics only.
  return [...PREFERRED_GEMINI_MODELS];
}

/** Video analysis always uses gemini-2.5* only — never ListModels (avoids retired 1.5). */
function getModelCandidates(_apiKey: string): string[] {
  return filterAllowedModels([...PREFERRED_GEMINI_MODELS]);
}

async function probeGeminiModel(apiKey: string, model: string): Promise<void> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: "Reply with exactly: OK" }] }],
      }),
    },
  );
  if (!response.ok) {
    const errText = await response.text();
    throw new Error(
      friendlyGeminiHttpError(errText, model, response.status) ??
        `Gemini probe failed for ${model}: ${errText}`,
    );
  }
}


function isRetriableModelError(message: string): boolean {
  const lower = message.toLowerCase();
  if (isQuotaError(lower)) return false;
  return isTransientGeminiError(lower) ||
    lower.includes("not_found") ||
    lower.includes("no longer available") ||
    lower.includes("not found for api version") ||
    lower.includes("rejected model") ||
    lower.includes("flash-lite");
}

function isTransientGeminiError(message: string): boolean {
  const lower = message.toLowerCase();
  return lower.includes("503") ||
    lower.includes("unavailable") ||
    lower.includes("high demand") ||
    lower.includes("overloaded") ||
    lower.includes("try again");
}

function isQuotaError(message: string): boolean {
  const lower = message.toLowerCase();
  return lower.includes("resource_exhausted") ||
    lower.includes("quota") ||
    lower.includes("429");
}

function friendlyGeminiHttpError(
  errText: string,
  model: string,
  status: number,
): string | null {
  const lower = errText.toLowerCase();
  if (status === 404 || lower.includes("no longer available") ||
      lower.includes("not found for api version")) {
    return `Google rejected model "${model}" for your API key — SwimIQ will try another model. `
      + `If all models fail, create a NEW key at aistudio.google.com/apikey and update `
      + `GEMINI_API_KEY in Supabase Edge Function secrets (no GEMINI_MODEL secret).`;
  }
  if (status === 429 || isQuotaError(lower)) {
    if (lower.includes("gemini-1.5") || model.includes("1.5")) {
      return "Google retired gemini-1.5 (quota 0). Redeploy sync-v9 — your server "
        + "must only use gemini-2.5-flash. Create a NEW key at aistudio.google.com/apikey if needed.";
    }
    if (lower.includes("gemini-2.0-flash") || model.includes("2.0-flash")) {
      return "Gemini 2.0 Flash is retired (quota limit 0). "
        + "Run KARA-GEMINI-FIX-NOW.bat to deploy sync-v9.";
    }
    return "Google Gemini rate limit for your API key. Wait 2-3 minutes and tap Analyze again. "
      + "If this keeps happening: create a NEW key at aistudio.google.com/apikey in a fresh "
      + "Google Cloud project and update GEMINI_API_KEY in Supabase Edge Function secrets.";
  }
  if (status === 503 || isTransientGeminiError(lower)) {
    return `Gemini model "${model}" is busy right now (Google high demand). `
      + `SwimIQ will try another model automatically — tap Analyze again in 1-2 minutes.`;
  }
  if (lower.includes("api key not valid") || lower.includes("api_key_invalid")) {
    return "GEMINI_API_KEY is invalid. Create a new key at aistudio.google.com/apikey "
      + "and update Supabase Edge Function secrets.";
  }
  return null;
}

async function callGeminiGenerateContentWithFallback(
  apiKey: string,
  videoPart: GeminiVideoPart,
  prompt: string,
  maxModels = MAX_VIDEO_GEMINI_MODELS,
): Promise<{ json: Record<string, unknown>; model: string }> {
  const models = getModelCandidates(apiKey).slice(
    0,
    Math.max(1, maxModels),
  );
  if (models.length === 0) {
    throw new Error(
      "No supported Gemini Flash models found for your API key. "
      + "Create a new key at aistudio.google.com/apikey and update GEMINI_API_KEY.",
    );
  }
  let lastError = "Gemini request failed.";
  const attempted: string[] = [];

  for (const model of models) {
    attempted.push(model);
    for (let attempt = 0; attempt <= GEMINI_RETRY_DELAYS_MS.length; attempt++) {
      try {
        const json = await callGeminiGenerateContent(apiKey, model, videoPart, prompt);
        return { json, model };
      } catch (error) {
        lastError = error instanceof Error ? error.message : String(error);
        const canRetrySameModel = attempt < GEMINI_RETRY_DELAYS_MS.length &&
          isTransientGeminiError(lastError.toLowerCase());
        if (canRetrySameModel) {
          await new Promise((resolve) =>
            setTimeout(resolve, GEMINI_RETRY_DELAYS_MS[attempt])
          );
          continue;
        }
        break;
      }
    }
    const isLast = model === models[models.length - 1];
    if (!isRetriableModelError(lastError) || isLast) {
      throw new Error(
        `${lastError} (tried: ${attempted.join(", ")}, `
          + `server: ${CURRENT_FUNCTION_VERSION})`,
      );
    }
  }

  throw new Error(
    `${lastError} (tried: ${attempted.join(", ")}, `
      + `server: ${CURRENT_FUNCTION_VERSION})`,
  );
}

function normalizeAnalysis(
  parsed: Record<string, unknown>,
  body: AnalyzeRequest,
  uploadMethod: GeminiUploadMethod = "inline",
  geminiModel: string = DEFAULT_GEMINI_MODEL,
) {
  const bullet = (items: unknown) =>
    Array.isArray(items)
      ? items.map((item) => `• ${String(item)}`).join("\n")
      : "";

  const whatShows = bullet(parsed.what_the_video_shows);
  const priorities = bullet(parsed.top_3_priorities);

  const sections: Record<string, string> = {
    "Quick pro from this video": sanitizeCoachText(String(
      parsed.quick_pro ?? whatShows.split("\n")[0] ?? "",
    )),
    "Quick con from this video": sanitizeCoachText(String(parsed.quick_con ?? "")),
    "Goal for your next race": sanitizeCoachText(String(parsed.next_race_goal ?? "")),
    "Top 3 priorities for your next race": sanitizeCoachText(priorities),
    "Dryland focus (strength · mobility · stability)": sanitizeCoachText(String(
      parsed.dryland_focus ?? "",
    )),
    "Estimated time savings": sanitizeCoachText(String(parsed.estimated_time_savings ?? "")),
    "Coach notes for next race": sanitizeCoachText(String(
      parsed.coach_notes_for_next_race ?? "",
    )),
  };

  const techniqueScore = clampScore(parsed.technique_score);
  const paceScore = clampScore(parsed.pace_score);
  const overallScore = clampScore(parsed.overall_score);

  const disclaimer = body.pose_metrics?.frames_with_pose
    ? "SwimIQ AI coaching with MediaPipe body-mechanics estimates — precise technique feedback (hips, head, body line) for swimmers and parents; confirm with your coach."
    : "SwimIQ AI coaching from uploaded footage — precise swim technique feedback for swimmers and parents; confirm with your coach.";

  const engine = body.pose_metrics?.frames_with_pose
    ? "swimiq-v2-gemini-mediapipe"
    : "swimiq-v2-gemini";

  const summary = [
    body.event_label ?? "Swim video",
    sections["Quick pro from this video"],
    sections["Quick con from this video"],
  ].join("\n");

  const strengths = [
    "Quick pro from this video",
    sections["Quick pro from this video"],
  ].join("\n").trim();

  return {
    swim_video_id: body.video_id ?? null,
    swimmer: body.swimmer ?? "",
    summary,
    strengths,
    improvements: `Top 3 priorities for your next race\n${priorities}`,
    technique_score: techniqueScore,
    pace_score: paceScore,
    overall_score: overallScore,
    analysis_json: {
      engine,
      model: geminiModel,
      upload_method: uploadMethod,
      event: body.event_label,
      disclaimer,
      pose_metrics: body.pose_metrics ?? null,
      function_version: CURRENT_FUNCTION_VERSION,
      sections,
      top_3_priorities: Array.isArray(parsed.top_3_priorities)
        ? parsed.top_3_priorities.map((item) => sanitizeCoachText(String(item)))
        : [],
      estimated_time_savings: sanitizeCoachText(String(parsed.estimated_time_savings)),
      coach_notes_for_next_race: sanitizeCoachText(String(parsed.coach_notes_for_next_race)),
      quick_pro: sanitizeCoachText(String(parsed.quick_pro)),
      quick_con: sanitizeCoachText(String(parsed.quick_con)),
      next_race_goal: sanitizeCoachText(String(parsed.next_race_goal)),
      dryland_focus: sanitizeCoachText(String(parsed.dryland_focus)),
      overall_summary: sanitizeCoachText(String(parsed.overall_summary ?? "")),
      technique_summary: sanitizeCoachText(String(parsed.technique_summary ?? "")),
      pace_summary: sanitizeCoachText(String(parsed.pace_summary ?? "")),
      youth_friendly: true,
    },
  };
}

function clampScore(value: unknown): number {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return 70;
  return Math.max(0, Math.min(100, Math.round(n)));
}

function sanitizeCoachText(value: string): string {
  const plainLanguageRules: Array<[RegExp, string]> = [
    [
      /drive full extension on the last stroke at the wall\.?/gi,
      "Finish your final stroke completely before touching the wall. Reach all the way forward, keep driving through the water, and touch with a fully extended arm instead of shortening or gliding into the wall.",
    ],
    [
      /full extension into the wall on the last stroke/gi,
      "a complete last stroke with a long reach to the wall",
    ],
    [
      /drove full extension into the wall/gi,
      "finished with a complete last stroke — long reach and a strong touch",
    ],
    [/\bfull extension\b/gi, "a complete last stroke with your arm stretched out long"],
    [
      /hold streamline longer before breakout\.?/gi,
      "Stay in your tight streamline a little longer (arms squeezed behind your ears) before you take your first stroke.",
    ],
    [/over-gliding/gi, "pausing too long with your arms stretched out"],
    [/body line/gi, "flat body position on the water"],
    [
      /high-elbow catch/gi,
      "pull with your elbow high, like scooping water with your forearm",
    ],
  ];

  let cleaned = value
    .replace(
      /\b(sexy|hot body|ugly|fat|obese|overweight|skinny|stupid|idiot|damn|hell|shit|fuck|wtf)\b/gi,
      "",
    )
    .trim();

  for (const [pattern, replacement] of plainLanguageRules) {
    cleaned = cleaned.replace(pattern, replacement);
  }

  return cleaned
    .replace(/\s{2,}/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function mimeTypeForPath(path: string): string {
  const lower = path.toLowerCase();
  if (lower.endsWith(".mov")) return "video/quicktime";
  if (lower.endsWith(".webm")) return "video/webm";
  if (lower.endsWith(".mkv")) return "video/x-matroska";
  return "video/mp4";
}

function jsonError(message: string, status: number, functionVersion?: string) {
  return new Response(
    JSON.stringify({
      error: message,
      function_version: functionVersion ?? CURRENT_FUNCTION_VERSION,
    }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}
