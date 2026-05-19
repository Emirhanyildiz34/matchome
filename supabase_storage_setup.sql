-- ==============================================
-- STORAGE: listing-images bucket oluşturma
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- ==============================================

-- 1. Public storage bucket oluştur
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'listing-images',
  'listing-images',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Herkesin resimleri görüntüleyebilmesi için policy
DROP POLICY IF EXISTS "Public read access for listing images" ON storage.objects;
CREATE POLICY "Public read access for listing images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'listing-images');

-- 3. Giriş yapmış kullanıcıların resim yükleyebilmesi için policy
DROP POLICY IF EXISTS "Authenticated users can upload listing images" ON storage.objects;
CREATE POLICY "Authenticated users can upload listing images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'listing-images');

-- 4. Kullanıcıların kendi yüklediği resimleri silebilmesi için policy
DROP POLICY IF EXISTS "Users can delete own listing images" ON storage.objects;
CREATE POLICY "Users can delete own listing images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'listing-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 5. Kullanıcıların kendi resimlerini güncelleyebilmesi için policy
DROP POLICY IF EXISTS "Users can update own listing images" ON storage.objects;
CREATE POLICY "Users can update own listing images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'listing-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ==============================================
-- LISTINGS TABLOSU: İletişim alanları
-- ==============================================
ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS show_phone BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS host_phone TEXT,
  ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;

-- ==============================================
-- LISTINGS TABLOSU: Depozito alanları
-- ==============================================
ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS has_deposit BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deposit_amount INTEGER;
