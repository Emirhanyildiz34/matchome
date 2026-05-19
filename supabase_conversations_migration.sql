-- =======================================================
-- CONVERSATIONS TABLOSU GÜNCELLEMESİ
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- =======================================================

-- 1. Yeni sütunlar ekle
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS listing_id TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS listing_type TEXT DEFAULT 'listing';
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS listing_image_url TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS listing_title TEXT;

-- 2. Mevcut null satırları güncelle
UPDATE conversations SET listing_type = 'listing' WHERE listing_type IS NULL;

-- 3. Eski unique constraint'i kaldır (participant1_id, participant2_id çifti)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'conversations_participants_unique'
  ) THEN
    ALTER TABLE conversations DROP CONSTRAINT conversations_participants_unique;
  END IF;
END $$;

-- 4. Yeni unique constraint ekle: (participant1_id, participant2_id, listing_type)
--    Böylece aynı iki kullanıcı hem ev ilanı hem elden ele konuşması yapabilir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'conversations_participants_listing_type_unique'
  ) THEN
    ALTER TABLE conversations
      ADD CONSTRAINT conversations_participants_listing_type_unique
      UNIQUE (participant1_id, participant2_id, listing_type);
  END IF;
END $$;

-- 5. Sohbet silme politikası (kullanıcı kendi sohbetini silebilsin)
DROP POLICY IF EXISTS "Sohbet sil" ON conversations;
CREATE POLICY "Sohbet sil"
  ON conversations FOR DELETE TO authenticated
  USING (participant1_id = auth.uid() OR participant2_id = auth.uid());
