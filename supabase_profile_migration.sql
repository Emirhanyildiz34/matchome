-- ==============================================
-- PROFİL TABLOSU GÜNCELLEME MIGRATION
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- ==============================================

-- Eksik olabilecek sütunları ekle (IF NOT EXISTS ile güvenli)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS district TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS campus TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- PostgREST schema cache'i yenile (PGRST204 hatasını giderir)
NOTIFY pgrst, 'reload schema';
