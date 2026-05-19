-- ==============================================
-- YENİ ÖZELLİKLER MİGRATION
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- ==============================================

-- 1. Mesaj silme desteği
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- 2. İlanlara cinsiyet tercihi
-- 'male' = Erkek, 'female' = Kadın, NULL = Fark Etmez
ALTER TABLE listings ADD COLUMN IF NOT EXISTS preferred_gender TEXT
  CHECK (preferred_gender IN ('male', 'female'));

-- 3. İlanlara yakın üniversite alanı
ALTER TABLE listings ADD COLUMN IF NOT EXISTS nearby_university TEXT;

-- 4. Mesaj silme için RLS politikası (sadece gönderen silebilir)
DROP POLICY IF EXISTS "Kullanici kendi mesajini silebilir" ON messages;
CREATE POLICY "Kullanici kendi mesajini silebilir"
  ON messages FOR UPDATE
  USING (auth.uid() = sender_id);

-- 5. Supabase realtime için messages tablosunu güncelle
-- (Zaten aktifse tekrar etkinleştirmeye gerek yok)

-- PostgREST schema cache'i yenile
NOTIFY pgrst, 'reload schema';
