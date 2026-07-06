import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { encodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";

const BUCKET = "swim-videos";
const MAX_VIDEO_BYTES = 18 * 1024 * 1024;
const GEMINI_MODEL = "gemini-2.0-flash";

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
  observations?: string[];
};

type AnalyzeRequest = {
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
    const storagePath = body.storage_path?.trim();
    if (!storagePath) {
      return jsonError("storage_path is required.", 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { data: fileBlob, error: downloadError } = await admin.storage
      .from(BUCKET)
      .download(storagePath);

    if (downloadError || !fileBlob) {
      return jsonError(
        `Could not download video: ${downloadError?.message ?? "not found"}`,
        404,
      );
    }

    const videoBytes = new Uint8Array(await fileBlob.arrayBuffer());
    if (videoBytes.length > MAX_VIDEO_BYTES) {
      return jsonError(
        "Video is too large for Gemini inline analysis (max ~18 MB). Trim the clip and try again.",
        413,
      );
    }

    const mimeType = mimeTypeForPath(storagePath);
    const base64Video = encodeBase64(videoBytes);
    const prompt = buildPrompt(body);

    const geminiPayload = {
      contents: [
        {
          parts: [
            { inline_data: { mime_type: mimeType, data: base64Video } },
            { text: prompt },
          ],
        },
      ],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: analysisResponseSchema,
      },
    };

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(geminiPayload),
      },
    );

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      return jsonError(`Gemini API error: ${errText}`, 502);
    }

    const geminiJson = await geminiResponse.json();
    const textPart = geminiJson?.candidates?.[0]?.content?.parts?.find(
      (part: { text?: string }) => typeof part.text === "string",
    )?.text;

    if (!textPart) {
      return jsonError("Gemini returned an empty analysis.", 502);
    }

    const parsed = JSON.parse(textPart) as Record<string, unknown>;
    const analysis = normalizeAnalysis(parsed, body);

    return new Response(JSON.stringify(analysis), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonError(message, 500);
  }
});

const analysisResponseSchema = {
  type: "OBJECT",
  properties: {
    quick_summary: { type: "STRING" },
    what_the_video_shows: { type: "ARRAY", items: { type: "STRING" } },
    cannot_confirm_yet: { type: "ARRAY", items: { type: "STRING" } },
    top_3_priorities: { type: "ARRAY", items: { type: "STRING" } },
    recommended_drills: { type: "ARRAY", items: { type: "STRING" } },
    estimated_time_savings: { type: "STRING" },
    coach_notes_for_next_race: { type: "STRING" },
    technique_score: { type: "INTEGER" },
    pace_score: { type: "INTEGER" },
    overall_score: { type: "INTEGER" },
  },
  required: [
    "quick_summary",
    "what_the_video_shows",
    "top_3_priorities",
    "technique_score",
    "pace_score",
    "overall_score",
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
        pose.avg_elbow_angle_deg != null
          ? `Average elbow angle: ${pose.avg_elbow_angle_deg.toFixed(1)}°`
          : null,
        pose.estimated_stroke_cycles != null
          ? `Estimated arm cycles in clip: ${pose.estimated_stroke_cycles}`
          : null,
        pose.kick_symmetry_score != null
          ? `Kick symmetry score: ${pose.kick_symmetry_score.toFixed(0)}/100`
          : null,
        pose.observations?.length
          ? `Pose observations: ${pose.observations.join("; ")}`
          : null,
      ].filter(Boolean).join("\n")
    : "";

  return `You are an experienced youth swim coach reviewing a race or practice video for SwimIQ.

Watch the attached swim video carefully. Combine what you SEE in the footage with the athlete context and on-device pose metrics below.

Athlete context:
${contextLines || "(no extra context)"}

On-device pose metrics (MediaPipe-compatible BlazePose, estimates only):
${poseLines || "(pose metrics not available for this clip)"}

Return JSON only (no markdown). Be specific about visible technique (body line, kick, pull, breathing, turns, underwater, finish).
Reference the pose metrics when they support what you see, but do not invent numbers beyond them.
Use parent-friendly language. Scores are 0-100 integers.
If the camera angle limits certainty, say so in cannot_confirm_yet.
Do not invent split times or stroke counts you cannot verify from the video.`;
}

function normalizeAnalysis(
  parsed: Record<string, unknown>,
  body: AnalyzeRequest,
) {
  const bullet = (items: unknown) =>
    Array.isArray(items)
      ? items.map((item) => `• ${String(item)}`).join("\n")
      : "";

  const whatShows = bullet(parsed.what_the_video_shows);
  const cannotConfirm = bullet(parsed.cannot_confirm_yet);
  const priorities = bullet(parsed.top_3_priorities);
  const drills = bullet(parsed.recommended_drills);

  const sections: Record<string, string> = {
    "Quick Summary": String(parsed.quick_summary ?? ""),
    "What the video shows": whatShows,
    "What cannot be confirmed from this angle": cannotConfirm,
    "Top 3 priorities for the next practice": priorities,
    "Specific drills": drills,
    "Estimated time savings": String(parsed.estimated_time_savings ?? ""),
    "Coach notes for next race": String(
      parsed.coach_notes_for_next_race ?? "",
    ),
  };

  const techniqueScore = clampScore(parsed.technique_score);
  const paceScore = clampScore(parsed.pace_score);
  const overallScore = clampScore(parsed.overall_score);

  const disclaimer = body.pose_metrics?.frames_with_pose
    ? "Gemini video analysis combined with on-device MediaPipe pose metrics — estimates only; confirm with your coach."
    : "Gemini video analysis from uploaded footage — estimates only; confirm with your coach.";

  const engine = body.pose_metrics?.frames_with_pose
    ? "swimiq-v2-gemini-mediapipe"
    : "swimiq-v2-gemini";

  const summary = [
    body.event_label ?? "Swim video",
    disclaimer,
    "",
    sections["Quick Summary"],
  ].join("\n");

  const strengths = [
    "What the video shows",
    whatShows,
    "",
    "Specific drills",
    drills,
  ].join("\n").trim();

  return {
    swim_video_id: body.video_id ?? null,
    swimmer: body.swimmer ?? "",
    summary,
    strengths,
    improvements: `Top 3 priorities for the next practice\n${priorities}`,
    technique_score: techniqueScore,
    pace_score: paceScore,
    overall_score: overallScore,
    analysis_json: {
      engine,
      model: GEMINI_MODEL,
      event: body.event_label,
      disclaimer,
      pose_metrics: body.pose_metrics ?? null,
      sections,
      top_3_priorities: parsed.top_3_priorities ?? [],
      recommended_drills: parsed.recommended_drills ?? [],
      estimated_time_savings: parsed.estimated_time_savings,
      coach_notes_for_next_race: parsed.coach_notes_for_next_race,
    },
  };
}

function clampScore(value: unknown): number {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return 70;
  return Math.max(0, Math.min(100, Math.round(n)));
}

function mimeTypeForPath(path: string): string {
  const lower = path.toLowerCase();
  if (lower.endsWith(".mov")) return "video/quicktime";
  if (lower.endsWith(".webm")) return "video/webm";
  if (lower.endsWith(".mkv")) return "video/x-matroska";
  return "video/mp4";
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
