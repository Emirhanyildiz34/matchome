-- =======================================================
-- SUPABASE EDGE SCRAPING SETUP (GUNLUK CRON)
-- Bu dosyayi Supabase Dashboard > SQL Editor'da calistirin.
-- =======================================================

-- 1) Gerekli extension'lar
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2) Kaynak tablo (hangi universiteden nasil scrape edilecek)
CREATE TABLE IF NOT EXISTS scraped_sources (
  id BIGSERIAL PRIMARY KEY,
  university TEXT NOT NULL UNIQUE,
  url TEXT NOT NULL,
  base_url TEXT,
  selectors JSONB NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  last_scraped_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Eski tabloyu yeni semaya uyumlu hale getir (backward-compatible)
ALTER TABLE scraped_sources
  ADD COLUMN IF NOT EXISTS base_url TEXT,
  ADD COLUMN IF NOT EXISTS selectors JSONB,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS last_scraped_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_error TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Edge Function'un select ettigi bireysel selector sutunlari (eger yoksa ekle)
ALTER TABLE scraped_sources
  ADD COLUMN IF NOT EXISTS item_selector TEXT,
  ADD COLUMN IF NOT EXISTS title_selector TEXT,
  ADD COLUMN IF NOT EXISTS content_selector TEXT,
  ADD COLUMN IF NOT EXISTS date_selector TEXT,
  ADD COLUMN IF NOT EXISTS link_selector TEXT;

UPDATE scraped_sources
SET selectors = COALESCE(selectors, '{}'::jsonb)
WHERE selectors IS NULL;

ALTER TABLE scraped_sources
  ALTER COLUMN selectors SET NOT NULL;

-- 3) updated_at trigger
CREATE OR REPLACE FUNCTION set_updated_at_scraped_sources()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_updated_at_scraped_sources ON scraped_sources;
CREATE TRIGGER trg_set_updated_at_scraped_sources
BEFORE UPDATE ON scraped_sources
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_scraped_sources();

-- 4) Tum universiteleri pasif (is_active=false) kayit olarak olustur.
-- URL ve selector bilinmeyenler daha sonra guncellenerek aktiflestirilebilir.
INSERT INTO scraped_sources (university, url, base_url, selectors, is_active)
SELECT u.university, 'https://example.com', NULL, '{}'::jsonb, FALSE
FROM (
VALUES
    ('19 Mayıs Üniversitesi'),
    ('29 Mayıs Üniversitesi'),
    ('7 Aralık Üniversitesi'),
    ('Abant İzzet Baysal Üniversitesi'),
    ('Abdullah Gül Üniversitesi'),
    ('Acıbadem Üniversitesi'),
    ('Adana Alparslan Türkeş Bilim ve Teknoloji Üniversitesi'),
    ('Adana Bilim ve Teknoloji Üniversitesi'),
    ('Adıyaman Üniversitesi'),
    ('Adnan Menderes Üniversitesi'),
    ('Afyon Kocatepe Üniversitesi'),
    ('Afyonkarahisar Sağlık Bilimleri Üniversitesi'),
    ('Ağrı İbrahim Çeçen Üniversitesi'),
    ('Akdeniz Üniversitesi'),
    ('Aksaray Üniversitesi'),
    ('Alanya Alaaddin Keykubat Üniversitesi'),
    ('Alanya Üniversitesi'),
    ('Altınbaş Üniversitesi'),
    ('Amasya Üniversitesi'),
    ('Anadolu Üniversitesi'),
    ('Ankara Güzel Sanatlar ve Müzik Üniversitesi'),
    ('Ankara Hacı Bayram Veli Üniversitesi'),
    ('Ankara Sosyal Bilimler Üniversitesi'),
    ('Ankara Üniversitesi'),
    ('Ankara Yıldırım Beyazıt Üniversitesi'),
    ('Antalya Belek Üniversitesi'),
    ('Antalya Bilim Üniversitesi'),
    ('Ardahan Üniversitesi'),
    ('Artvin Çoruh Üniversitesi'),
    ('Atatürk Üniversitesi'),
    ('Atılım Üniversitesi'),
    ('AUZEF İstanbul üniversitesi'),
    ('Avrasya Üniversitesi'),
    ('AYDIN ADNAN MENDERES ÜNİVERSİTESİ'),
    ('Bahcesehir University'),
    ('Bahçeşehir Üniversitesi'),
    ('Balıkesir Üniversitesi'),
    ('Bandırma 17 Eylül Üniversitesi'),
    ('Bandırma Onyedi Eylül Üniversitesi'),
    ('Bartın Üniversitesi'),
    ('Başkent Üniversitesi'),
    ('Batman Üniversitesi'),
    ('Beykent Üniversitesi'),
    ('Bezmiâlem Vakıf Üniversitesi'),
    ('Bilecik Şeyh Edebali Üniversitesi'),
    ('Bilgi Üniversitesi'),
    ('Bilkent Üniversitesi'),
    ('Bingöl Üniversitesi'),
    ('Biruni Üniversitesi'),
    ('Boğaziçi Üniversitesi'),
    ('Burdur Mehmet Akif Ersoy Üniversitesi'),
    ('Bursa Teknik Üniversitesi'),
    ('Bursa Uludağ Üniversitesi'),
    ('Bülent Ecevit Üniversitesi'),
    ('Celal Bayar Üniversitesi'),
    ('Cukurova University'),
    ('Çanakkale 18 Mart Üniversitesi'),
    ('Çanakkale Onsekiz Mart Üniversitesi'),
    ('Çanakkale Onsekiz Mart Üniversitesi Astrofizik Araştırma Merkezi'),
    ('Çankaya Üniversitesi'),
    ('Çankırı Karatekin Üniversitesi'),
    ('Çorum Hitit Üniversitesi'),
    ('Çukurova Üniversitesi'),
    ('Dicle Üniversitesi'),
    ('Doğuş Üniversitesi'),
    ('Dokuz Eylül Üniversitesi'),
    ('Dumlupınar Üniversitesi'),
    ('Düzce Üniversitesi'),
    ('Ege Üniversitesi'),
    ('Erciyes Üniversitesi'),
    ('Eren Üniversitesi'),
    ('Erzincan Binali Yıldırım Üniversitesi'),
    ('Erzincan Üniversitesi'),
    ('Erzurum Atatürk Üniversitesi'),
    ('Erzurum Teknik Üniversitesi'),
    ('Eskişehir Osmangazi Üniversitesi'),
    ('Eskişehir Teknik Üniversitesi'),
    ('Fatih Belediyesi - Yıldız Teknik Üniversitesi'),
    ('Fatih Sultan Mehmet Vakıf Üniversitesi'),
    ('Fenerbahçe Üniversitesi'),
    ('Fırat Üniversitesi'),
    ('FMV Işık Üniversitesi'),
    ('Galatasaray Üniversitesi'),
    ('Gazi Üniversitesi'),
    ('Gazi ve Ankara Hacı Bayram Veli Üniversitesi'),
    ('Gaziantep Üniversitesi'),
    ('Gaziosmanpaşa Üniversitesi'),
    ('Gebze Teknik Üniversitesi'),
    ('Gedik Üniversitesi'),
    ('Gelişim Üniversitesi'),
    ('Giresun Üniversitesi'),
    ('Gümüşhane Üniversitesi'),
    ('Hacettepe University'),
    ('Hacettepe Üniversitesi'),
    ('Hacı Bayram Veli Üniversitesi'),
    ('Hakkari Üniversitesi'),
    ('Haliç Üniversitesi'),
    ('Harran Üniversitesi'),
    ('Hasan Kalyoncu Üniversitesi'),
    ('Hatay Mustafa Kemal Üniversitesi'),
    ('Hiti Üniversitesi'),
    ('Hitit Üniversitesi'),
    ('Iğdır Üniversitesi'),
    ('Isparta Uygulamalı Bilimler Üniversitesi'),
    ('Istanbul Kültür Üniversitesi'),
    ('Istanbul University'),
    ('Istanbul Üniversitesi'),
    ('Işık Üniversitesi'),
    ('İbn Haldun Üniversitesi'),
    ('İnönü Üniversitesi'),
    ('İskenderun Teknik Üniversitesi'),
    ('İslam Bilim ve Teknoloji Üniversitesi'),
    ('İstanbul Arel Üniversitesi'),
    ('İstanbul Atlas Üniversitesi'),
    ('İstanbul Aydın Üniversitesi'),
    ('İstanbul Ayvansaray Üniversitesi'),
    ('İstanbul Bilgi Üniversitesi'),
    ('İstanbul Esenyurt Üniversitesi'),
    ('İstanbul Gedik Üniversitesi'),
    ('İstanbul Kent Üniversitesi'),
    ('İstanbul Kültür Üniversitesi'),
    ('İstanbul Medeniyet Üniversitesi'),
    ('İstanbul Rumeli Üniversitesi'),
    ('İstanbul Sabahattin Zaim Üniversitesi'),
    ('İstanbul Teknik Üniversitesi'),
    ('İstanbul Ticaret Üniversitesi'),
    ('İstanbul üniversitesi'),
    ('İstanbul Yeni Yüzyıl Üniversitesi'),
    ('İstiklal Üniversitesi'),
    ('İstinye Üniversitesi'),
    ('İzmir Bakırçay Üniversitesi'),
    ('İzmir Demokrasi Üniversitesi'),
    ('İzmir Ekonomi Üniversitesi'),
    ('İzmir Kâtip Çelebi Üniversitesi'),
    ('İzmir Yüksek Teknoloji Enstitüsü'),
    ('Kadir Has Üniversitesi'),
    ('Kafkas Üniversitesi'),
    ('Kahramanmaraş Sütçü İmam Üniversitesi'),
    ('Kapadokya Üniversitesi'),
    ('Karabük Üniversitesi'),
    ('Karadeniz Teknik Üniversitesi'),
    ('Karamanoğlu Mehmetbey Üniversitesi'),
    ('Karatekin Üniversitesi'),
    ('Kastamonu Üniversitesi'),
    ('Kayseri Üniversitesi'),
    ('Kırklareli üniversitesi'),
    ('Kırşehir Ahi Evran Üniversitesi'),
    ('Kilis 7 Aralık Üniversitesi'),
    ('Kocaeli Sağlık ve Teknoloji Üniversitesi'),
    ('KOCAELİ ÜNİVERSİTESİ'),
    ('Koç Üniversitesi'),
    ('Konya Gıda ve Tarım Üniversitesi'),
    ('Konya Teknik Üniversitesi'),
    ('Korkut Ata Üniversitesi'),
    ('KTO Karatay Üniversitesi'),
    ('Malatya Turgut Özal Üniversitesi'),
    ('Manisa Celal Bayar Üniversitesi'),
    ('Manisa Celâl Bayar Üniversitesi'),
    ('Mardin Artuklu Üniversitesi'),
    ('Marmara Üniversitesi'),
    ('Medeniyet Üniversitesi'),
    ('Medipol University'),
    ('Medipol Üniversitesi'),
    ('MEF Üniversitesi'),
    ('Mehmet Akif Ersoy Üniversitesi'),
    ('Mersin Üniversitesi'),
    ('Milas Meslek Yüksekokulu | Muğla Sıtkı Koçman Üniversitesi'),
    ('Milli Savunma Üniversitesi'),
    ('Mimar Sinan Güzel Sanatlar Üniversitesi'),
    ('Mudanya Üniversitesi'),
    ('Muğla Sıtkı Koçman Üniversitesi'),
    ('Muğla Üniversitesi'),
    ('Mustafa Kemal Üniversitesi'),
    ('Muş Alparslan Üniversitesi'),
    ('Namık Kemal Üniversites'),
    ('Namık Kemal Üniversitesi'),
    ('Necmettin Erbakan Üniversitesi'),
    ('Nevşehir Hacıbektaş Veli Üniversitesi'),
    ('Nevşehir Üniversitesi'),
    ('Nişantaşı Üniversitesi'),
    ('Nuh Naci Yazgan Üniversitesi'),
    ('ODTÜ Deniz Bilimleri Enstitüsü'),
    ('Okan Üniversitesi'),
    ('Ondokuz Mayıs Üniversitesi'),
    ('Onyedi Eylül Üniversitesi'),
    ('Ordu Üniversitesi'),
    ('Orta Doğu Teknik Üniversitesi'),
    ('Osmangazi Üniversitesi'),
    ('Osmaniye Korkut Ata Üniversitesi'),
    ('Ostim Teknik Üniversitesi'),
    ('Ömer Halisdemir Üniversitesi'),
    ('Pamukkale Üniversitesi'),
    ('Piri Reis Üniversitesi'),
    ('Recep Tayyip Erdoğan Üniversitesi'),
    ('Sabahattin Zaim Üniversitesi'),
    ('Sabancı Üniversitesi'),
    ('Sağlık Bilimleri Üniversitesi'),
    ('Sakarya Uygulamalı Bilimler Üniversitesi'),
    ('Sakarya Üniversitesi'),
    ('Samsun Üniversitesi'),
    ('Sanko Üniversitesi'),
    ('Selçuk Üniversitesi'),
    ('Siirt Üniversitesi'),
    ('Sinop Üniversitesi'),
    ('Sivas Bilim ve Teknoloji Üniversitesi'),
    ('Sivas Cumhuriyet University'),
    ('Sivas Cumhuriyet Üniversitesi'),
    ('Su Altı Arkeoleji Enstitüsü'),
    ('Süleyman Demirel Üniversitesi'),
    ('Şebinkarahisar Üniversite Yerleşkesi'),
    ('Şırnak Üniversitesi'),
    ('T. C. İstanbul Arel Üniversitesi'),
    ('T.C. Balıkesir Üniversitesi'),
    ('T.C. Bayburt Üniversitesi'),
    ('T.C. Kırklareli Üniversitesi'),
    ('T.C. Maltepe Üniversitesi'),
    ('T.C. Mehmet Akif Ersoy Üniversitesi'),
    ('T.C. Sakarya Üniversitesi'),
    ('Tarsus Üniversitesi'),
    ('TED Üniversitesi'),
    ('Tekirdağ Namık Kemal Üniversitesi'),
    ('Tınaztepe Üniversitesi'),
    ('TOBB Ekonomi ve Teknoloji Üniversitesi'),
    ('Toros Üniversitesi'),
    ('Trabzon Üniversitesi'),
    ('Trakya Üniversitesi'),
    ('Tunceli - Munzur Üniversitesi'),
    ('Türk Hava Kurumu Üniversitesi'),
    ('Türk-Alman Üniversitesi'),
    ('Türk-Japon Üniversitesi'),
    ('Ufuk Üniversitesi'),
    ('Uludağ Üniversitesi'),
    ('Uşak Üniversitesi'),
    ('Uygulamalı Matematik Enstitüsü'),
    ('Üsküdar University'),
    ('Üsküdar Üniversitesi'),
    ('Yalova Üniversitesi'),
    ('Yaşar Üniversitesi'),
    ('Yeditepe Üniversitesi'),
    ('Yıldırım Beyazıt Üniversitesi'),
    ('Yıldız Teknik Üniversitesi'),
    ('Yozgat Bozok Üniversitesi'),
    ('Yüzüncü Yıl Üniversitesi'),
    ('Zonguldak Bülent Ecevit Üniversitesi')
) AS u(university)
ON CONFLICT (university) DO NOTHING;

-- 5) Bilinen kaynaklari aktif ve selector'lu olarak guncelle (upsert)
UPDATE scraped_sources
SET is_active = FALSE;

INSERT INTO scraped_sources (university, url, base_url, selectors, item_selector, title_selector, content_selector, date_selector, link_selector, is_active)
VALUES
  (
    'İstanbul Teknik Üniversitesi',
    'https://www.itu.edu.tr/duyurular',
    'https://www.itu.edu.tr',
    '{"container":"div.news-item, article.post, div.announcement-item","title":"h3, h2, .title, a","content":"p, .summary, .description","date":".date, time, .news-date","link":"a"}'::jsonb,
    'div.news-item, article.post, div.announcement-item',
    'h3, h2, .title, a',
    'p, .summary, .description',
    '.date, time, .news-date',
    'a',
    TRUE
  ),
  (
    'Orta Doğu Teknik Üniversitesi',
    'https://www.metu.edu.tr',
    'https://www.metu.edu.tr',
    '{"container":".view-content .views-row, article, .node","title":"h3 a, h2 a, .field-title a","content":".field-body, .summary, p","date":".date-display-single, .field-date, time","link":"h3 a, h2 a, a"}'::jsonb,
    '.view-content .views-row, article, .node',
    'h3 a, h2 a, .field-title a',
    '.field-body, .summary, p',
    '.date-display-single, .field-date, time',
    'h3 a, h2 a, a',
    TRUE
  ),
  (
    'Boğaziçi Üniversitesi',
    'https://bogazici.edu.tr',
    'https://bogazici.edu.tr',
    '{"container":".announcement-item, .news-item, article, .list-group-item","title":"h3, h4, a.title, .announcement-title","content":"p, .excerpt, .announcement-body","date":".date, time, span.date","link":"a"}'::jsonb,
    '.announcement-item, .news-item, article, .list-group-item',
    'h3, h4, a.title, .announcement-title',
    'p, .excerpt, .announcement-body',
    '.date, time, span.date',
    'a',
    TRUE
  ),
  (
    'Ankara Üniversitesi',
    'https://www.ankara.edu.tr',
    'https://www.ankara.edu.tr',
    '{"container":"article, .post, .duyuru-item, .news-item","title":"h2 a, h3 a, .entry-title a","content":".entry-content p, .excerpt, p","date":".date, time, .entry-date","link":"h2 a, h3 a, a"}'::jsonb,
    'article, .post, .duyuru-item, .news-item',
    'h2 a, h3 a, .entry-title a',
    '.entry-content p, .excerpt, p',
    '.date, time, .entry-date',
    'h2 a, h3 a, a',
    TRUE
  ),
  (
    'Ege Üniversitesi',
    'https://www.ege.edu.tr',
    'https://www.ege.edu.tr',
    '{"container":".news-item, article, .duyuru, .list-group-item","title":"h3, h4, a","content":"p, .summary","date":".date, time","link":"a"}'::jsonb,
    '.news-item, article, .duyuru, .list-group-item',
    'h3, h4, a',
    'p, .summary',
    '.date, time',
    'a',
    TRUE
  )
ON CONFLICT (university)
DO UPDATE SET
  url = EXCLUDED.url,
  base_url = EXCLUDED.base_url,
  selectors = EXCLUDED.selectors,
  item_selector = EXCLUDED.item_selector,
  title_selector = EXCLUDED.title_selector,
  content_selector = EXCLUDED.content_selector,
  date_selector = EXCLUDED.date_selector,
  link_selector = EXCLUDED.link_selector,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- 6) RLS (opsiyonel ama guvenli)
ALTER TABLE scraped_sources ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'scraped_sources'
      AND policyname = 'Allow read for authenticated users'
  ) THEN
    CREATE POLICY "Allow read for authenticated users"
    ON scraped_sources
    FOR SELECT
    TO authenticated
    USING (true);
  END IF;
END $$;

-- 7) Eski cron joblari kaldir (saatlik + gunluk isimleri)
DO $$
BEGIN
  PERFORM cron.unschedule(jobid)
  FROM cron.job
  WHERE jobname IN (
    'scrape-university-announcements-hourly',
    'scrape-university-announcements-daily'
  );
END $$;

-- 8) Gunluk cron: her gun 06:00 (UTC)
-- Not: Authorization header'da anon public key kullanildi.
SELECT cron.schedule(
  'scrape-university-announcements-daily',
  '0 6 * * *',
  $$
    SELECT net.http_post(
      url := 'https://owalhgozebvapuubsgtv.supabase.co/functions/v1/scrape-university-announcements',
      headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93YWxoZ296ZWJ2YXB1dWJzZ3R2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0Mzk4MDYsImV4cCI6MjA4ODAxNTgwNn0.mF7hUM-rxNaaBlh0wzrIqTZoNF_gew7rTTzsv2AY0fQ", "Content-Type": "application/json"}'::jsonb,
      body := '{}'::jsonb
    );
  $$
);

-- 9) Kontrol query'leri (opsiyonel)
-- SELECT COUNT(*) AS total_sources, COUNT(*) FILTER (WHERE is_active) AS active_sources FROM scraped_sources;
-- SELECT jobid, jobname, schedule, command FROM cron.job WHERE jobname LIKE 'scrape-university-announcements-%';
