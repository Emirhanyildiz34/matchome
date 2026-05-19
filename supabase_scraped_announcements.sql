-- =======================================================
-- SCRAPED (RESMİ) ÜNİVERSİTE DUYURULARI TABLOSU
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- =======================================================

-- 1. scraped_announcements tablosu
CREATE TABLE IF NOT EXISTS scraped_announcements (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  university     TEXT NOT NULL,
  title          TEXT NOT NULL,
  content        TEXT,
  summary        TEXT,
  category       TEXT DEFAULT 'genel',
  published_at   TIMESTAMP WITH TIME ZONE,
  scraped_at     TIMESTAMP WITH TIME ZONE DEFAULT now(),
  source_url     TEXT,
  external_link  TEXT,
  image_url      TEXT,
  is_active      BOOLEAN DEFAULT true,
  UNIQUE(university, external_link)
);

-- 2. RLS
ALTER TABLE scraped_announcements ENABLE ROW LEVEL SECURITY;

-- Tüm authenticated kullanıcılar okuyabilir
DROP POLICY IF EXISTS "Scraped duyuruları oku" ON scraped_announcements;
CREATE POLICY "Scraped duyuruları oku"
  ON scraped_announcements FOR SELECT TO authenticated
  USING (true);

-- INSERT/UPDATE/DELETE yalnızca service_role (Python scraper) yapabilir
-- (RLS service_role'ü bypass eder, ekstra policy gerekmez)

-- 3. İndeksler
CREATE INDEX IF NOT EXISTS idx_scraped_ann_university
  ON scraped_announcements(university);
CREATE INDEX IF NOT EXISTS idx_scraped_ann_published
  ON scraped_announcements(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_scraped_ann_active_uni_date
  ON scraped_announcements(is_active, university, published_at DESC);

-- 4. 90 günden eski duyuruları temizle
DELETE FROM scraped_announcements
WHERE scraped_at < NOW() - INTERVAL '90 days';
