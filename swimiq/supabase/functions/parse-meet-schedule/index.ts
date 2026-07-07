const GEMINI_MODEL = "gemini-2.0-flash";
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ParseRequest = {
  image_base64?: string;
  mime_type?: string;
  file_name?: string;
  team_name?: string;
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

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonError("Missing Authorization header.", 401);
    }

    const body = (await req.json()) as ParseRequest;
    const imageBase64 = body.image_base64?.trim();
    if (!imageBase64) {
      return jsonError("image_base64 is required.", 400);
    }

    const mimeType = body.mime_type?.trim() || "image/jpeg";
    const bytes = Uint8Array.from(atob(imageBase64), (c) => c.charCodeAt(0));
    if (bytes.length > MAX_IMAGE_BYTES) {
      return jsonError("Image is too large (max 8 MB).", 413);
    }

    const teamName = body.team_name?.trim() || "the swimmer's team";
    const prompt = buildPrompt(teamName);

    const geminiPayload = {
      contents: [
        {
          parts: [
            { inline_data: { mime_type: mimeType, data: imageBase64 } },
            { text: prompt },
          ],
        },
      ],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: meetListSchema,
      },
    };

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(geminiPayload),
      },
    );

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      return jsonError(`Gemini error: ${errText.slice(0, 400)}`, 502);
    }

    const geminiJson = await geminiRes.json();
    const text =
      geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
    if (!text) {
      return jsonError("Gemini returned an empty response.", 502);
    }

    const parsed = JSON.parse(text);
    const meets = Array.isArray(parsed?.meets) ? parsed.meets : [];

    return jsonResponse({
      meets,
      source: "photo-scan",
      file_name: body.file_name ?? "schedule.jpg",
      parsed_at: new Date().toISOString(),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonError(message, 502);
  }
});

function buildPrompt(teamName: string): string {
  const today = new Date().toISOString().slice(0, 10);
  return `You are reading a youth swim team meet schedule from a photo or screenshot.
Team context: ${teamName}
Today's date: ${today}

Extract every upcoming swim meet listed in the image. Include invitationals, duals, championships, and team travel meets.
Skip practices, banquets, and non-competitive events unless clearly labeled as meets.

For each meet return:
- name: meet name
- start_date: ISO date YYYY-MM-DD (use the first day if a range)
- end_date: ISO date YYYY-MM-DD or omit if single day
- location: pool or city if visible
- course: SCY, SCM, or LCM if stated, else omit
- categories: array including "Swim Meet"

Only include meets on or after ${today}. If unsure of a date, make your best estimate from context.
Return JSON matching the schema.`;
}

const meetListSchema = {
  type: "OBJECT",
  properties: {
    meets: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          name: { type: "STRING" },
          start_date: { type: "STRING" },
          end_date: { type: "STRING" },
          location: { type: "STRING" },
          course: { type: "STRING" },
          categories: { type: "ARRAY", items: { type: "STRING" } },
        },
        required: ["name", "start_date"],
      },
    },
  },
  required: ["meets"],
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function jsonError(message: string, status: number) {
  return jsonResponse({ error: message }, status);
}
