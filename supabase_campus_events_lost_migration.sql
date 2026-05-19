-- =======================================================
-- KAMPÜS DUYURULARI İÇİN ETKİNLİK VE KAYIP EŞYA EKLENTİLERİ
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- =======================================================

-- 1. campus_announcements tablosuna yeni sütunlar ekle
ALTER TABLE campus_announcements
ADD COLUMN IF NOT EXISTS max_participants INTEGER DEFAULT NULL,
ADD COLUMN IF NOT EXISTS participation_fee TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS last_seen_location TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS last_seen_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS is_resolved BOOLEAN DEFAULT false; -- Etkinlik doldu/kapandı veya eşya bulundu

-- 2. campus_announcement_applications tablosunu oluştur
CREATE TABLE IF NOT EXISTS campus_announcement_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID NOT NULL REFERENCES campus_announcements(id) ON DELETE CASCADE,
  applicant_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  contact_info TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(announcement_id, applicant_id) -- Bir kullanıcı bir etkinliğe sadece 1 kez başvurabilsin
);

-- 3. RLS (Row Level Security) ayarları
ALTER TABLE campus_announcement_applications ENABLE ROW LEVEL SECURITY;

-- Herkes başvuruları ekleyebilsin (kendi adına)
DROP POLICY IF EXISTS "Kullanıcılar kendi başvurularını oluşturabilir" ON campus_announcement_applications;
CREATE POLICY "Kullanıcılar kendi başvurularını oluşturabilir"
  ON campus_announcement_applications FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = applicant_id);

-- Başvuru sahibi kendi başvurusunu görebilsin
DROP POLICY IF EXISTS "Kullanıcılar kendi başvurularını görebilir" ON campus_announcement_applications;
CREATE POLICY "Kullanıcılar kendi başvurularını görebilir"
  ON campus_announcement_applications FOR SELECT TO authenticated
  USING (auth.uid() = applicant_id);

-- İlan sahibi, ilanına gelen başvuruları görebilir
DROP POLICY IF EXISTS "İlan sahipleri başvuruları görebilir" ON campus_announcement_applications;
CREATE POLICY "İlan sahipleri başvuruları görebilir"
  ON campus_announcement_applications FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM campus_announcements
      WHERE campus_announcements.id = campus_announcement_applications.announcement_id
      AND campus_announcements.author_id = auth.uid()
    )
  );

-- İlan sahibi başvuruları güncelleyebilir (durum değiştirme vb.)
DROP POLICY IF EXISTS "İlan sahipleri başvuruları güncelleyebilir" ON campus_announcement_applications;
CREATE POLICY "İlan sahipleri başvuruları güncelleyebilir"
  ON campus_announcement_applications FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM campus_announcements
      WHERE campus_announcements.id = campus_announcement_applications.announcement_id
      AND campus_announcements.author_id = auth.uid()
    )
  );

-- 4. Supabase Realtime'a tabloyu dahil et
ALTER PUBLICATION supabase_realtime ADD TABLE campus_announcement_applications;
