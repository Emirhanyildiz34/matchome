# 🤖 Üniversite Duyuru Scraper

Üniversite web sitelerinden duyuruları otomatik kazıyıp (scrape) Supabase veritabanına kaydeden Python botu.

## Kurulum

```bash
cd scraper
pip install -r requirements.txt
```

## Yapılandırma

1. `.env.example` dosyasını `.env` olarak kopyalayın:
   ```bash
   cp .env.example .env
   ```

2. `.env` içine Supabase bilgilerinizi yazın:
   - `SUPABASE_URL` → Supabase Dashboard > Settings > API > URL
   - `SUPABASE_SERVICE_KEY` → Supabase Dashboard > Settings > API > service_role key

3. `config.py` dosyasında üniversite URL'lerini ve CSS selector'larını yapılandırın.

## Çalıştırma

### Tek seferlik
```bash
python main.py
```

### Sürekli (her saat)
```bash
python main.py --loop
```

### Cron Job (Linux/macOS)
```cron
0 * * * * cd /path/to/scraper && python main.py
```

### Windows Task Scheduler
1. Task Scheduler aç
2. "Create Basic Task" → Trigger: Daily, Repeat every 1 hour
3. Action: Start a program → `python` → Arguments: `main.py` → Start in: scraper klasörü

## Yeni Üniversite Ekleme

`config.py` dosyasına yeni bir dict ekleyin:

```python
{
    "name": "Üniversite Adı",          # Supabase'deki profiles.university ile aynı olmalı
    "url": "https://uni.edu.tr/duyurular",
    "base_url": "https://uni.edu.tr",
    "type": "html",
    "selectors": {
        "item": "article",              # Duyuru kartının CSS selector'ı
        "title": "h3",                  # Başlık selector'ı
        "content": "p",                 # İçerik selector'ı
        "date": ".date",               # Tarih selector'ı
        "link": "a",                   # Detay linki selector'ı
    },
}
```

### Selector Bulma
1. Üniversite duyuru sayfasını Chrome'da açın
2. F12 → Elements sekmesi → duyuru kartına sağ tıklayın → "Copy selector"
3. Bu selector'ı `config.py`'ye ekleyin

## Mimari

```
[Üniversite Web Siteleri]
         │
         │ HTTP GET (saatte bir)
         ▼
   ┌──────────┐
   │  Scraper  │  ← Python (BeautifulSoup)
   └────┬─────┘
        │ INSERT (service_role key)
        ▼
   ┌──────────┐
   │ Supabase │  ← scraped_announcements tablosu
   └────┬─────┘
        │ SELECT (anon key)
        ▼
   ┌──────────┐
   │ Flutter  │  ← Mobil uygulama
   │   App    │
   └──────────┘
```

## Dinamik Siteler (JavaScript ile yüklenen)

Bazı üniversiteler duyuruları JavaScript ile yükler. Bu durumda:

1. `playwright` kurun:
   ```bash
   pip install playwright
   playwright install chromium
   ```

2. `config.py`'de `"type": "dynamic"` olarak ayarlayın

3. `scraper.py`'deki `scrape_university()` fonksiyonuna Playwright desteği ekleyin
