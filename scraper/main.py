"""
Üniversite Duyuru Scraper — Ana giriş noktası.

Kullanım:
  python main.py              # Tek seferlik çalıştır
  python main.py --loop       # Belirli aralıklarla sürekli çalıştır (cron alternatifi)

Ortam değişkenleri (.env dosyasından okunur):
  SUPABASE_URL, SUPABASE_SERVICE_KEY, SCRAPE_INTERVAL_MINUTES
"""

import os
import sys
import time
import logging
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("main")


def run_once():
    """Tüm üniversiteleri kazı ve veritabanına kaydet."""
    from scraper import scrape_all
    from database import get_client, upsert_announcements, cleanup_old

    logger.info("=== Scrape başlıyor ===")

    announcements = scrape_all()
    logger.info("Toplam %d duyuru kazındı.", len(announcements))

    if not announcements:
        logger.info("Eklenecek duyuru yok.")
        return

    client = get_client()
    inserted = upsert_announcements(client, announcements)
    logger.info("%d yeni duyuru eklendi.", inserted)

    # Eski duyuruları temizle
    cleanup_old(client, days=90)
    logger.info("=== Scrape tamamlandı ===")


def main():
    if "--loop" in sys.argv:
        interval = int(os.getenv("SCRAPE_INTERVAL_MINUTES", "60"))
        logger.info("Loop modu: her %d dakikada bir çalışacak.", interval)
        while True:
            try:
                run_once()
            except Exception as e:
                logger.error("Scrape döngüsünde hata: %s", e)
            logger.info("Sonraki çalışma %d dakika sonra...", interval)
            time.sleep(interval * 60)
    else:
        run_once()


if __name__ == "__main__":
    main()
