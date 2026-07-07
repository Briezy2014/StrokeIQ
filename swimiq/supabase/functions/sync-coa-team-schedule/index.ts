const COA_TEAM_ALIAS = "ohcoa";
const COA_TEAM_NAME = "Central Ohio Aquatics";
const GOMOTION_BASE = "https://www.gomotionapp.com";
const SC_SCHEDULE_PAGE =
  "/team/ohcoa/page/meet-info/single-page-sc-meet-schedule";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type PdfLink = {
  label: string;
  url: string;
  updated?: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const [events, pdfLinks] = await Promise.all([
      fetchCoaTeamEvents(),
      fetchSchedulePdfLinks(),
    ]);

    return jsonResponse({
      source: "coa-gomotion",
      team: COA_TEAM_NAME,
      team_alias: COA_TEAM_ALIAS,
      events,
      pdf_links: pdfLinks,
      synced_at: new Date().toISOString(),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonError(message, 502);
  }
});

async function fetchCoaTeamEvents(): Promise<unknown[]> {
  const response = await fetch(`${GOMOTION_BASE}/rest/teamevent/rawData`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-TU-Team": COA_TEAM_ALIAS,
      "User-Agent": "SwimIQ/1.0 (+https://github.com/Briezy2014/StrokeIQ)",
    },
    body: JSON.stringify({
      isPastMeet: false,
      timezone: "America/New_York",
    }),
  });

  if (!response.ok) {
    throw new Error(
      `COA calendar API returned HTTP ${response.status}.`,
    );
  }

  const data = await response.json();
  if (!Array.isArray(data)) {
    throw new Error("COA calendar API returned unexpected data.");
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  return data
    .filter((event) => {
      const categories = readFieldList(event?.categories);
      const isSwimMeet = categories.some((c) =>
        c.toLowerCase().includes("swim meet")
      );
      const isTeamMeeting = categories.some((c) =>
        c.toLowerCase().includes("team meeting")
      );
      if (!isSwimMeet && !isTeamMeeting) return false;

      const start = readFieldValue(event?.startDate);
      if (!start) return true;
      const startDate = new Date(start);
      return !Number.isNaN(startDate.getTime()) && startDate >= today;
    })
    .sort((a, b) => {
      const aDate = new Date(readFieldValue(a?.startDate) ?? 0).getTime();
      const bDate = new Date(readFieldValue(b?.startDate) ?? 0).getTime();
      return aDate - bDate;
    });
}

async function fetchSchedulePdfLinks(): Promise<PdfLink[]> {
  const response = await fetch(`${GOMOTION_BASE}${SC_SCHEDULE_PAGE}`, {
    headers: {
      "User-Agent": "SwimIQ/1.0 (+https://github.com/Briezy2014/StrokeIQ)",
    },
  });

  if (!response.ok) {
    return [];
  }

  const html = await response.text();
  const links: PdfLink[] = [];
  const pattern =
    /<a href="([^"]+\.pdf)"[^>]*>([^<]+)<\/a>\s*(?:&#xa0;|-)?\s*updated\s+([^<]+)/gi;

  for (const match of html.matchAll(pattern)) {
    const href = match[1];
    const label = decodeHtml(match[2]).trim();
    const updated = decodeHtml(match[3]).trim();
    const url = href.startsWith("http")
      ? href
      : `${GOMOTION_BASE}${href.startsWith("/") ? "" : "/"}${href}`;
    links.push({ label, url, updated });
  }

  return links;
}

function readFieldValue(field: unknown): string | null {
  if (!field || typeof field !== "object") return null;
  const value = (field as { value?: unknown }).value;
  if (value == null) return null;
  const text = String(value).trim();
  return text.length > 0 ? text : null;
}

function readFieldList(field: unknown): string[] {
  if (!field || typeof field !== "object") return [];
  const value = (field as { value?: unknown }).value;
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item));
}

function decodeHtml(text: string): string {
  return text
    .replace(/&#xa0;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&nbsp;/g, " ")
    .trim();
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function jsonError(message: string, status: number) {
  return jsonResponse({ error: message }, status);
}
