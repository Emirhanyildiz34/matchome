-- =======================================================
-- SCRAPED DUYURULARI DÜZELTME (GÜNCELLENMİŞ SIRALAMA)
-- =======================================================

-- 1) Tabloyu oluştur (Yoksa)
CREATE TABLE IF NOT EXISTS scraped_announcements (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  university  TEXT NOT NULL,
  title       TEXT NOT NULL,
  content     TEXT,
  summary     TEXT,
  category    TEXT DEFAULT 'genel',
  published_at TIMESTAMP WITH TIME ZONE,
  scraped_at   TIMESTAMP WITH TIME ZONE DEFAULT now(),
  source_url   TEXT,
  external_link TEXT,
  image_url    TEXT,
  is_active    BOOLEAN DEFAULT true
);

-- 2) UNIQUE CONSTRAINT'I GEÇİCİ OLARAK KALDIR
-- Bu adım çok önemli, aksi halde UPDATE sırasında "duplicate" hatası alırsınız.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'scraped_announcements_university_external_link_key'
  ) THEN
    ALTER TABLE scraped_announcements DROP CONSTRAINT scraped_announcements_university_external_link_key;
  END IF;
END$$;

-- 3) İSİMLERİ NORMALIZE ET (Silmeden Önce Yapılmalı!)
UPDATE scraped_announcements SET university = 'İstanbul Teknik Üniversitesi'
  WHERE university IN ('Istanbul Teknik Universitesi', 'Istanbul Teknik Üniversitesi', 'İstanbul Teknik Universitesi', 'ITU', 'itu');

UPDATE scraped_announcements SET university = 'Orta Doğu Teknik Üniversitesi'
  WHERE university IN ('Orta Dogu Teknik Universitesi', 'Orta Doğu Teknik Universitesi', 'ODTU', 'METU', 'Middle East Technical University');

UPDATE scraped_announcements SET university = 'Boğaziçi Üniversitesi'
  WHERE university IN ('Bogazici Universitesi', 'Bogazici Üniversitesi', 'Boğaziçi Universitesi', 'Bosphorus University');

UPDATE scraped_announcements SET university = 'Ankara Üniversitesi'
  WHERE university IN ('Ankara Universitesi', 'Ankara University');

UPDATE scraped_announcements SET university = 'Ege Üniversitesi'
  WHERE university IN ('Ege Universitesi', 'Ege University');

UPDATE scraped_announcements SET university = 'Hacettepe Üniversitesi'
  WHERE university IN ('Hacettepe Universitesi', 'Hacettepe University');

UPDATE scraped_announcements SET university = 'Gazi Üniversitesi'
  WHERE university IN ('Gazi Universitesi', 'Gazi University');

UPDATE scraped_announcements SET university = 'Marmara Üniversitesi'
  WHERE university IN ('Marmara Universitesi', 'Marmara University');

UPDATE scraped_announcements SET university = 'Dokuz Eylül Üniversitesi'
  WHERE university IN ('Dokuz Eylul Universitesi', 'Dokuz Eylul University');

UPDATE scraped_announcements SET university = 'Yıldız Teknik Üniversitesi'
  WHERE university IN ('Yildiz Teknik Universitesi', 'Yıldız Teknik Universitesi', 'Yildiz Technical University');

-- 4) MÜKERRER KAYITLARI TEMİZLE
-- İsimler düzeldiği için aynı linke sahip "ITU" ve "İstanbul Teknik" artık burada yakalanacak.
DELETE FROM scraped_announcements a
USING (
  SELECT university, external_link, MIN(id::text)::uuid as keep_id
  FROM scraped_announcements
  WHERE university IS NOT NULL AND external_link IS NOT NULL
  GROUP BY university, external_link
  HAVING COUNT(*) > 1
) dups
WHERE a.university = dups.university
  AND a.external_link = dups.external_link
  AND a.id <> dups.keep_id;

-- 5) UNIQUE CONSTRAINT'I TEKRAR EKLE (Artık temiz veri olduğu için hata vermez)
ALTER TABLE scraped_announcements 
ADD CONSTRAINT scraped_announcements_university_external_link_key 
UNIQUE (university, external_link);

-- 6) RLS POLİTİKALARI
ALTER TABLE scraped_announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Scraped duyuruları oku" ON scraped_announcements;
CREATE POLICY "Scraped duyuruları oku"
  ON scraped_announcements FOR SELECT TO authenticated
  USING (true);

-- 7) SCRAPED_SOURCES TABLOSU DÜZENLEME
ALTER TABLE scraped_sources
  ADD COLUMN IF NOT EXISTS item_selector TEXT,
  ADD COLUMN IF NOT EXISTS title_selector TEXT,
  ADD COLUMN IF NOT EXISTS content_selector TEXT,
  ADD COLUMN IF NOT EXISTS date_selector TEXT,
  ADD COLUMN IF NOT EXISTS link_selector TEXT;

-- JSONB'den sütunlara veri aktarımı
UPDATE scraped_sources
SET
  item_selector    = COALESCE(item_selector,    selectors->>'container'),
  title_selector   = COALESCE(title_selector,   selectors->>'title'),
  content_selector = COALESCE(content_selector, selectors->>'content'),
  date_selector    = COALESCE(date_selector,    selectors->>'date'),
  link_selector    = COALESCE(link_selector,    selectors->>'link')
WHERE is_active = TRUE
  AND selectors IS NOT NULL;

-- 8) SONUÇLARI KONTROL ET
SELECT university, COUNT(*) AS duyuru_sayisi
FROM scraped_announcements
GROUP BY university
ORDER BY duyuru_sayisi DESC;