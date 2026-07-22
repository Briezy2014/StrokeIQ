import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const GEMINI_MODEL = "gemini-3.5-flash";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type SchoolMatch = {
  school?: string;
  division?: string;
  conference?: string;
  tier?: string;
  event?: string;
  swimmer_time?: string;
  recruit_range?: string;
  gap_to_target?: string;
};

type MatchRequest = {
  display_name?: string;
  graduation_year?: number;
  gpa?: string;
  college_interests?: string;
  personal_bests?: string[];
  benchmark_disclaimer?: string;
  matches?: SchoolMatch[];
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
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return jsonError("Missing Authorization header.", 401);

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth
      .getUser();
    if (userError || !userData.user) return jsonError("Unauthorized.", 401);

    const body = (await req.json()) as MatchRequest;
    const matches = body.matches ?? [];
    if (matches.length === 0) {
      return jsonError("matches array is required.", 400);
    }

    const prompt = buildPrompt(body, matches);
    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: {
              type: "OBJECT",
              properties: {
                coach_summary: { type: "STRING" },
              },
              required: ["coach_summary"],
            },
          },
        }),
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

    if (!textPart) return jsonError("Gemini returned an empty summary.", 502);

    const parsed = JSON.parse(textPart) as { coach_summary?: string };
    return new Response(
      JSON.stringify({
        coach_summary: parsed.coach_summary ?? "",
        engine: "swimiq-gemini-college-match-v1",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonError(message, 500);
  }
});

function buildPrompt(body: MatchRequest, matches: SchoolMatch[]): string {
  const athleteLines = [
    body.display_name ? `Athlete: ${body.display_name}` : null,
    body.graduation_year ? `Class of ${body.graduation_year}` : null,
    body.gpa ? `GPA: ${body.gpa}` : null,
    body.college_interests ? `College interests: ${body.college_interests}` : null,
    body.personal_bests?.length
      ? `Personal bests: ${body.personal_bests.join("; ")}`
      : null,
  ].filter(Boolean).join("\n");

  const matchLines = matches.map((match, index) =>
    `${index + 1}. [${match.tier}] ${match.school} (${match.division}, ${match.conference}) — ${match.event}: swimmer ${match.swimmer_time}, recruit range ${match.recruit_range}, gap to target ${match.gap_to_target}`
  ).join("\n");

  return `You are a trusted swim recruiting advisor speaking to a youth swimmer, their club coach, and their family together.

VOICE:
- Warm, clear, and coach/family-friendly — no hype, no guarantees.
- Name specific schools from MATCHES. Group Reach / Target / Likely plainly.
- Explain what the time gap means in plain English (e.g. "about 0.8s from Target for Miami of Ohio").
- Mention academics briefly when GPA is provided.
- Suggest practical next steps: email the college coach with a résumé, verify times on SwimCloud, ask the club coach which programs fit the family's region and budget.

STRICT RULES:
- ONLY discuss schools listed in MATCHES below. Do NOT invent or add new schools.
- Do NOT promise scholarships, roster spots, or admission.
- Prefer Central U.S. / listed region language when interests mention it.
- 5–8 sentences in coach_summary.
- End with a reminder to verify times with coaches and ${body.benchmark_disclaimer ?? "official recruiting databases"}.

Athlete:
${athleteLines || "(limited profile)"}

Benchmark-matched schools (pre-computed — do not change tiers or school names):
${matchLines}

Return JSON with coach_summary: a family-friendly recruiting briefing that names the schools, clarifies reach vs likely, and gives one clear next action.`;
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
