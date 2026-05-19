-- =======================================================
-- 2. EL EŞYA ALT KATEGORİ VE KONUM FİLTRE GÜNCELLEMESİ
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- =======================================================

ALTER TABLE second_hand_items
  ADD COLUMN IF NOT EXISTS subcategory TEXT,
  ADD COLUMN IF NOT EXISTS district TEXT;

UPDATE second_hand_items
SET
  district = NULLIF(TRIM(SPLIT_PART(city, ',', 2)), ''),
  city = NULLIF(TRIM(SPLIT_PART(city, ',', 1)), '')
WHERE city IS NOT NULL
  AND city LIKE '%,%'
  AND district IS NULL;

CREATE INDEX IF NOT EXISTS idx_second_hand_items_subcategory
  ON second_hand_items(subcategory);

CREATE INDEX IF NOT EXISTS idx_second_hand_items_city_district
  ON second_hand_items(city, district);