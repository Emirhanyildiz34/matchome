-- =======================================================
-- KAMPÜS DUYURULARI TABLOSU VE PROFİL GÜNCELLEMELERİ
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- =======================================================

-- 1. Profiles tablosuna university ve campus sütunlarını ekle (henüz yoksa)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS campus TEXT;

-- 2. campus_announcements tablosunu oluştur
--    NOT: author_id YALNIZCA profiles(id)'ye FK bağlı olmalı.
--    Böylece select('*, profiles(...)') PostgREST join'u çalışır.
CREATE TABLE IF NOT EXISTS campus_announcements (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  university   TEXT NOT NULL,
  campus       TEXT,
  title        TEXT NOT NULL,
  content      TEXT,
  category     TEXT DEFAULT 'genel',
  image_urls   TEXT[] DEFAULT '{}',
  latitude     DOUBLE PRECISION,
  longitude    DOUBLE PRECISION,
  address_text TEXT,
  is_active    BOOLEAN DEFAULT true,
  created_at   TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2b. Eğer tablo zaten varsa ve eski FK (auth.users) bağlıysa düzelt
DO $$
BEGIN
  -- auth.users'a giden eski FK varsa kaldır
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'campus_announcements_author_id_fkey'
      AND table_name = 'campus_announcements'
  ) THEN
    ALTER TABLE campus_announcements
      DROP CONSTRAINT campus_announcements_author_id_fkey;
  END IF;

  -- profiles'a giden FK yoksa ekle
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_campus_ann_profiles'
      AND table_name = 'campus_announcements'
  ) THEN
    ALTER TABLE campus_announcements
      ADD CONSTRAINT fk_campus_ann_profiles
      FOREIGN KEY (author_id) REFERENCES profiles(id) ON DELETE CASCADE;
  END IF;
END
$$;

-- 3. RLS etkinleştir
ALTER TABLE campus_announcements ENABLE ROW LEVEL SECURITY;

-- 4. Herkes kendi üniversitesinin duyurularını görebilsin
DROP POLICY IF EXISTS "Kampüs duyurularını oku" ON campus_announcements;
CREATE POLICY "Kampüs duyurularını oku"
  ON campus_announcements FOR SELECT TO authenticated
  USING (true);

-- 5. Üyeler duyuru ekleyebilsin (yalnızca kendi author_id'leri ile)
DROP POLICY IF EXISTS "Kampüs duyurusu ekle" ON campus_announcements;
CREATE POLICY "Kampüs duyurusu ekle"
  ON campus_announcements FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = author_id);

-- 6. Duyuru sahibi pasife alabilsin (soft-delete)
DROP POLICY IF EXISTS "Kampüs duyurusu güncelle" ON campus_announcements;
CREATE POLICY "Kampüs duyurusu güncelle"
  ON campus_announcements FOR UPDATE TO authenticated
  USING (auth.uid() = author_id);

-- 7. İndeksler (hız için)
CREATE INDEX IF NOT EXISTS idx_campus_ann_university
  ON campus_announcements(university);
CREATE INDEX IF NOT EXISTS idx_campus_ann_university_campus
  ON campus_announcements(university, campus);
CREATE INDEX IF NOT EXISTS idx_campus_ann_created_at
  ON campus_announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_campus_ann_active_university_date
  ON campus_announcements(is_active, university, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_campus_ann_author_id
  ON campus_announcements(author_id);

-- 8. Eski duyuruları otomatik temizleme (30 gün veya daha eski inactive duyurular)
DELETE FROM campus_announcements
WHERE is_active = false
  AND created_at < NOW() - INTERVAL '30 days';
