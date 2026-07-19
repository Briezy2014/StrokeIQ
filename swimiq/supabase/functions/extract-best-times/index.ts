import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const GEMINI_MODEL = "gemini-2.5-flash";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ExtractRequest = {
  image_base64?: string;
  mime_type?: string;
  course_hint?: string;
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
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) return jsonError("Unauthorized.", 401);

    const body = (await req.json()) as ExtractRequest;
    const imageBase64 = (body.image_base64 ?? "").trim();
    if (!imageBase64) return jsonError("image_base64 is required.", 400);

    let mime = (body.mime_type ?? "image/jpeg").split(";")[0].trim().toLowerCase();
    let rawBase64 = imageBase64;
    if (imageBase64.startsWith("data:")) {
      const comma = imageBase64.indexOf(",");
      const header = imageBase64.slice(0, comma);
      rawBase64 = imageBase64.slice(comma + 1);
      const match = header.match(/data:([^;]+);base64/i);
      if (match?.[1]) mime = match[1].toLowerCase();
    }
    if (!["image/jpeg", "image/jpg", "image/png", "image/webp"].includes(mime)) {
      return jsonError(`Unsupported image type: ${mime}`, 400);
    }
    if (mime === "image/jpg") mime = "image/jpeg";

    const courseHint = (body.course_hint ?? "").trim().toUpperCase();
    const prompt =
      "Extract all personal best rows from this Best Times History screenshot. " +
      "Return JSON with times[].event, times[].time, times[].course (SCY/LCM/SCM), " +
      "times[].date, times[].meet_name, plus detected_course." +
      (["SCY", "LCM", "SCM"].includes(courseHint)
        ? ` Default course hint if unclear: ${courseHint}.`
        : "");

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: prompt },
                {
                  inline_data: {
                    mime_type: mime,
                    data: rawBase64,
                  },
                },
              ],
            },
          ],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: {
              type: "OBJECT",
              properties: {
                times: {
                  type: "ARRAY",
                  items: {
                    type: "OBJECT",
                    properties: {
                      event: { type: "STRING" },
                      time: { type: "STRING" },
                      course: { type: "STRING" },
                      date: { type: "STRING" },
                      meet_name: { type: "STRING" },
                    },
                    required: ["event", "time"],
                  },
                },
                detected_course: { type: "STRING" },
                notes: { type: "STRING" },
              },
              required: ["times"],
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
    if (!textPart) return jsonError("Gemini returned an empty extract.", 502);

    const parsed = JSON.parse(textPart) as {
      times?: Array<Record<string, unknown>>;
      detected_course?: string;
      notes?: string;
    };
    const times = Array.isArray(parsed.times) ? parsed.times : [];
    if (times.length === 0) {
      return jsonError(
        "No swim times were found in that photo. Use a clear Best Times History screenshot.",
        422,
      );
    }

    return new Response(
      JSON.stringify({
        ok: true,
        engine: "swimiq-best-times-extract-edge-v1",
        times,
        detected_course: parsed.detected_course ?? null,
        notes: parsed.notes ?? null,
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

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message, message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
