import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { DOMParser } from "https://deno.land/x/deno_dom@v0.1.47/deno-dom-wasm.ts";

type ScrapeSource = {
  id: string;
  university: string;
  url: string;
  base_url: string | null;
  selectors: Record<string, string> | null;
  item_selector: string | null;
  title_selector: string | null;
  content_selector: string | null;
  date_selector: string | null;
  link_selector: string | null;
  is_active: boolean;
};

type AnnouncementRow = {
  university: string;
  title: string;
  content: string | null;
  summary: string | null;
  category: string;
  published_at: string;
  scraped_at: string;
  source_url: string;
  external_link: string;
  is_active: boolean;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const requestHeaders = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.5",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY eksik.");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: sources, error: sourceError } = await supabase
      .from("scraped_sources")
      .select("id, university, url, base_url, selectors, item_selector, title_selector, content_selector, date_selector, link_selector, is_active")
      .eq("is_active", true)
      .order("university", { ascending: true });

    if (sourceError) {
      throw sourceError;
    }

    const items = (sources ?? []) as ScrapeSource[];
    const result = {
      sourceCount: items.length,
      scrapedCount: 0,
      upsertedCount: 0,
      errors: [] as Array<{ university: string; error: string }>,
    };

    for (const source of items) {
      try {
        const rows = await scrapeSource(source);
        result.scrapedCount += rows.length;

        if (rows.length > 0) {
          const { error: upsertError } = await supabase
            .from("scraped_announcements")
            .upsert(rows, { onConflict: "university,external_link", ignoreDuplicates: false });

          if (upsertError) {
            throw upsertError;
          }

          result.upsertedCount += rows.length;
        }

        await supabase
          .from("scraped_sources")
          .update({ last_scraped_at: new Date().toISOString(), last_error: null })
          .eq("id", source.id);
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        result.errors.push({ university: source.university, error: message });

        await supabase
          .from("scraped_sources")
          .update({ last_error: message })
          .eq("id", source.id);
      }
    }

    await supabase
      .from("scraped_announcements")
      .delete()
      .lt("scraped_at", new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString());

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function scrapeSource(source: ScrapeSource): Promise<AnnouncementRow[]> {
  const nowIso = new Date().toISOString();
  const res = await fetch(source.url, { headers: requestHeaders });
  if (!res.ok) {
    throw new Error(`Sayfa alınamadı (${res.status})`);
  }

  const html = await res.text();
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) {
    throw new Error("HTML parse edilemedi.");
  }

  const itemSelector = source.item_selector || source.selectors?.["container"] || "article";
  const titleSelector = source.title_selector || source.selectors?.["title"] || "h3, h2, a";
  const contentSelector = source.content_selector || source.selectors?.["content"] || "p";
  const dateSelector = source.date_selector || source.selectors?.["date"] || "time, .date";
  const linkSelector = source.link_selector || source.selectors?.["link"] || "a";

  const nodes = Array.from(doc.querySelectorAll(itemSelector)).slice(0, 40);
  const rows: AnnouncementRow[] = [];

  if (nodes.length === 0) {
    const fallback = Array.from(doc.querySelectorAll("a[href]"))
      .map((a) => ({
        title: cleanText(a.textContent || ""),
        href: (a as Element).getAttribute("href") || "",
      }))
      .filter((x) => x.title.length >= 8)
      .slice(0, 20);

    for (const item of fallback) {
      const ext = toAbsoluteUrl(item.href, source.base_url || source.url);
      rows.push({
        university: source.university,
        title: item.title.slice(0, 500),
        content: null,
        summary: null,
        category: "genel",
        published_at: nowIso,
        scraped_at: nowIso,
        source_url: source.url,
        external_link: ext,
        is_active: true,
      });
    }

    return dedupeRows(rows);
  }

  for (const node of nodes) {
    const title = queryText(node as Element, titleSelector);
    if (!title || title.length < 3) continue;

    const content = queryText(node as Element, contentSelector) || null;
    const dateText = queryText(node as Element, dateSelector);
    const href = queryHref(node as Element, linkSelector);
    const externalLink = href
      ? toAbsoluteUrl(href, source.base_url || source.url)
      : `${source.url}#${slugify(title)}`;

    rows.push({
      university: source.university,
      title: title.slice(0, 500),
      content: content ? content.slice(0, 2000) : null,
      summary: content ? content.slice(0, 300) : null,
      category: "genel",
      published_at: parseTurkishDate(dateText) || nowIso,
      scraped_at: nowIso,
      source_url: source.url,
      external_link: externalLink,
      is_active: true,
    });
  }

  return dedupeRows(rows);
}

function queryText(node: Element, selector: string): string {
  const child = node.querySelector(selector);
  return cleanText(child?.textContent || "");
}

function queryHref(node: Element, selector: string): string | null {
  const first = node.querySelector(selector);
  if (!first) return null;
  const href = first.getAttribute("href");
  return href || null;
}

function cleanText(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

function toAbsoluteUrl(href: string, base: string): string {
  try {
    return new URL(href, base).toString();
  } catch {
    return base;
  }
}

function dedupeRows(rows: AnnouncementRow[]): AnnouncementRow[] {
  const seen = new Set<string>();
  const out: AnnouncementRow[] = [];
  for (const row of rows) {
    const key = `${row.university}::${row.external_link}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(row);
  }
  return out;
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .slice(0, 80);
}

function parseTurkishDate(text: string): string | null {
  const input = text.toLowerCase().trim();
  if (!input) return null;

  const months: Record<string, string> = {
    ocak: "01",
    "subat": "02",
    "şubat": "02",
    mart: "03",
    nisan: "04",
    mayis: "05",
    "mayıs": "05",
    haziran: "06",
    temmuz: "07",
    agustos: "08",
    "ağustos": "08",
    eylul: "09",
    "eylül": "09",
    ekim: "10",
    kasim: "11",
    "kasım": "11",
    aralik: "12",
    "aralık": "12",
  };

  for (const [name, mm] of Object.entries(months)) {
    const m = input.match(new RegExp(`(\\d{1,2})\\s*${name}\\s*(\\d{4})`));
    if (m) {
      const dd = m[1].padStart(2, "0");
      return `${m[2]}-${mm}-${dd}T00:00:00+03:00`;
    }
  }

  const dmy = input.match(/(\d{1,2})[./](\d{1,2})[./](\d{4})/);
  if (dmy) {
    const dd = dmy[1].padStart(2, "0");
    const mm = dmy[2].padStart(2, "0");
    return `${dmy[3]}-${mm}-${dd}T00:00:00+03:00`;
  }

  return null;
}
