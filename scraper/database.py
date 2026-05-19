"""
Supabase veritabanı istemcisi.
scraped_announcements tablosuna CRUD işlemleri yapar.
Service role key kullanır (RLS bypass).
"""

import os
import logging
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)


def get_client() -> Client:
    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_KEY"]
    return create_client(url, key)


def upsert_announcements(client: Client, announcements: list[dict]) -> int:
    """
    Duyuruları scraped_announcements tablosuna ekler.
    (university, external_link) UNIQUE constraint sayesinde
    aynı duyuru tekrar eklenmez (upsert on conflict ignore).
    Döndürür: eklenen yeni kayıt sayısı.
    """
    if not announcements:
        return 0

    inserted = 0
    for ann in announcements:
        try:
            # Önce aynı duyuru var mı kontrol et
            existing = (
                client.table("scraped_announcements")
                .select("id")
                .eq("university", ann["university"])
                .eq("external_link", ann.get("external_link", ""))
                .execute()
            )
            if existing.data:
                continue

            client.table("scraped_announcements").insert(ann).execute()
            inserted += 1
        except Exception as e:
            # Duplicate key gibi hatalar sessizce geç
            if "duplicate" in str(e).lower() or "unique" in str(e).lower():
                continue
            logger.warning("Duyuru eklenemedi: %s — %s", ann.get("title", "?"), e)

    return inserted


def cleanup_old(client: Client, days: int = 90) -> int:
    """90 günden eski duyuruları sil."""
    from datetime import datetime, timedelta, timezone

    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    result = (
        client.table("scraped_announcements")
        .delete()
        .lt("scraped_at", cutoff)
        .execute()
    )
    count = len(result.data) if result.data else 0
    if count:
        logger.info("%d eski duyuru silindi.", count)
    return count
