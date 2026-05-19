"""
Genel amaçlı üniversite duyuru kazıyıcı (scraper).
config.py'deki selector tanımlarına göre BeautifulSoup ile HTML parse eder.
"""

import logging
from datetime import datetime, timezone
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

from config import UNIVERSITIES

logger = logging.getLogger(__name__)

_SESSION = requests.Session()
_SESSION.headers.update(
    {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/124.0.0.0 Safari/537.36"
        ),
        "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.5",
    }
)

REQUEST_TIMEOUT = 30  # saniye


def _make_external_link(href: str | None, base_url: str) -> str:
    """Relative URL'yi absolute URL'ye çevirir."""
    if not href:
        return base_url
    if href.startswith(("http://", "https://")):
        return href
    return urljoin(base_url, href)


def _extract_text(element, selector: str) -> str:
    """Selector ile eşleşen ilk öğenin textini döndürür."""
    if not element or not selector:
        return ""
    child = element.select_one(selector)
    return child.get_text(strip=True) if child else ""


def _extract_link(element, selector: str) -> str | None:
    """Selector ile eşleşen ilk <a> etiketinin href'ini döndürür."""
    if not element or not selector:
        return None
    child = element.select_one(selector)
    if child and child.name == "a":
        return child.get("href")
    # Selector kendisi <a> değilse, içindeki ilk <a>'yı bul
    a_tag = child.find("a") if child else None
    return a_tag.get("href") if a_tag else None


def _candidate_urls(url: str, base_url: str) -> list[str]:
    """Ana URL başarısızsa denenecek alternatif sayfaları üretir."""
    candidates = [
        url,
        urljoin(base_url, "/duyurular"),
        urljoin(base_url, "/tr/duyurular"),
        urljoin(base_url, "/haberler"),
        urljoin(base_url, "/tr/haberler"),
        base_url,
    ]
    deduped = []
    seen = set()
    for item in candidates:
        if item not in seen:
            seen.add(item)
            deduped.append(item)
    return deduped


def _fetch_first_available(url: str, base_url: str) -> tuple[str, requests.Response] | tuple[None, None]:
    """200 dönen ilk URL'i bulup response ile döndürür."""
    for candidate in _candidate_urls(url, base_url):
        try:
            resp = _SESSION.get(candidate, timeout=REQUEST_TIMEOUT)
            if resp.status_code == 200:
                return candidate, resp
        except requests.RequestException:
            continue
    return None, None


def _fallback_collect_items(soup: BeautifulSoup, base_url: str) -> list[dict]:
    """Selector başarısızsa duyuru/haber benzeri linkleri toplar."""
    items = []
    seen_links = set()

    keywords = ("duyuru", "haber", "announcement", "news", "etkinlik")
    for a in soup.select("a[href]"):
        text = " ".join(a.get_text(" ", strip=True).split())
        href = a.get("href")
        if not text or len(text) < 8 or len(text) > 220:
            continue

        link = _make_external_link(href, base_url)
        haystack = f"{text} {link}".lower()
        if not any(k in haystack for k in keywords):
            continue
        if link in seen_links:
            continue

        seen_links.add(link)
        items.append({"title": text, "content": None, "date_str": "", "external_link": link})
        if len(items) >= 30:
            break

    return items


def scrape_university(uni_config: dict) -> list[dict]:
    """
    Tek bir üniversitenin duyuru sayfasını kazır.
    Döndürür: scraped_announcements tablosuna eklenecek dict listesi.
    """
    name = uni_config["name"]
    url = uni_config["url"]
    base_url = uni_config.get("base_url", url)
    selectors = uni_config.get("selectors", {})

    logger.info("Kazınıyor: %s → %s", name, url)

    used_url, resp = _fetch_first_available(url, base_url)
    if resp is None:
        logger.error("Sayfa alınamadı (%s): URL veya alternatifler erişilemedi.", name)
        return []

    resp.encoding = resp.apparent_encoding or "utf-8"
    soup = BeautifulSoup(resp.text, "lxml")

    item_selector = selectors.get("item", "article")
    items = soup.select(item_selector)

    fallback_items = []
    if not items:
        logger.warning(
            "Selector ile öğe bulunamadı (%s). Fallback link taraması çalışıyor. Selector: '%s'",
            name,
            item_selector,
        )
        fallback_items = _fallback_collect_items(soup, base_url)
        if not fallback_items:
            logger.warning("Fallback de öğe bulamadı (%s).", name)
            return []

    announcements = []
    now_iso = datetime.now(timezone.utc).isoformat()

    if fallback_items:
        for item in fallback_items:
            title = item["title"]
            content = item["content"]
            date_str = item["date_str"]
            external_link = item["external_link"]
            published_at = _parse_turkish_date(date_str) if date_str else None
            announcements.append(
                {
                    "university": name,
                    "title": title[:500],
                    "content": content[:2000] if content else None,
                    "summary": content[:300] if content else None,
                    "category": "genel",
                    "published_at": published_at or now_iso,
                    "scraped_at": now_iso,
                    "source_url": used_url,
                    "external_link": external_link,
                    "is_active": True,
                }
            )
    else:
        for item in items[:30]:  # Sayfa başına en fazla 30 duyuru
            title = _extract_text(item, selectors.get("title", "h3"))
            if not title or len(title) < 3:
                continue

            content = _extract_text(item, selectors.get("content", "p"))
            date_str = _extract_text(item, selectors.get("date", "time"))
            raw_link = _extract_link(item, selectors.get("link", "a"))
            external_link = _make_external_link(raw_link, base_url)

            # Tarih parse (basit deneme)
            published_at = _parse_turkish_date(date_str) if date_str else None

            announcements.append(
                {
                    "university": name,
                    "title": title[:500],
                    "content": content[:2000] if content else None,
                    "summary": content[:300] if content else None,
                    "category": "genel",
                    "published_at": published_at or now_iso,
                    "scraped_at": now_iso,
                    "source_url": used_url,
                    "external_link": external_link,
                    "is_active": True,
                }
            )

    logger.info("%s → %d duyuru bulundu.", name, len(announcements))
    return announcements


def scrape_all() -> list[dict]:
    """Tüm yapılandırılmış üniversiteleri kazır."""
    all_announcements = []
    for uni in UNIVERSITIES:
        try:
            results = scrape_university(uni)
            all_announcements.extend(results)
        except Exception as e:
            logger.error("Beklenmeyen hata (%s): %s", uni.get("name", "?"), e)
    return all_announcements


def _parse_turkish_date(text: str) -> str | None:
    """Türkçe tarih metinlerini ISO 8601'e çevirmeye çalışır."""
    import re

    text = text.strip().lower()
    if not text:
        return None

    # "17 Mart 2026" gibi formatlar
    months_tr = {
        "ocak": "01", "şubat": "02", "mart": "03", "nisan": "04",
        "mayıs": "05", "haziran": "06", "temmuz": "07", "ağustos": "08",
        "eylül": "09", "ekim": "10", "kasım": "11", "aralık": "12",
    }

    for month_name, month_num in months_tr.items():
        pattern = rf"(\d{{1,2}})\s*{month_name}\s*(\d{{4}})"
        m = re.search(pattern, text)
        if m:
            day = m.group(1).zfill(2)
            year = m.group(2)
            return f"{year}-{month_num}-{day}T00:00:00+03:00"

    # "17.03.2026" veya "17/03/2026" formatları
    m = re.search(r"(\d{1,2})[./](\d{1,2})[./](\d{4})", text)
    if m:
        day, month, year = m.group(1).zfill(2), m.group(2).zfill(2), m.group(3)
        return f"{year}-{month}-{day}T00:00:00+03:00"

    # "2026-03-17" ISO format
    m = re.search(r"(\d{4})-(\d{2})-(\d{2})", text)
    if m:
        return f"{m.group(0)}T00:00:00+03:00"

    return None
