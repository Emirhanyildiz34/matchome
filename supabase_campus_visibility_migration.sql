-- =======================================================
-- KAMPÜS DUYURULARI: GÖRÜNÜRLÜk KAPSAMI SÜTUNU
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- =======================================================

-- 1. visibility_scope sütununu ekle
--    'campus'     → yalnızca duyurunun oluşturulduğu kampüsteki kullanıcılar görür
--    'university' → aynı üniversitedeki TÜM kullanıcılar görür
ALTER TABLE campus_announcements
  ADD COLUMN IF NOT EXISTS visibility_scope TEXT NOT NULL DEFAULT 'campus'
  CHECK (visibility_scope IN ('campus', 'university'));

-- 2. Mevcut kayıtlar için akıllı varsayılan değer ata
--    campus değeri NULL olan eski kayıtlar muhtemelen üniversite geneline yazılmış
UPDATE campus_announcements
  SET visibility_scope = 'university'
  WHERE campus IS NULL
    AND visibility_scope = 'campus';

-- 3. Performans için indeks ekle
CREATE INDEX IF NOT EXISTS idx_campus_ann_visibility_scope
  ON campus_announcements(visibility_scope);

CREATE INDEX IF NOT EXISTS idx_campus_ann_university_scope
  ON campus_announcements(university, visibility_scope, is_active, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_campus_ann_campus_scope
  ON campus_announcements(university, campus, visibility_scope, is_active, created_at DESC);
