-- Rol ve Eşleşme Durumları için ENUM Tipleri
CREATE TYPE role_type AS ENUM ('student', 'professional', 'both');
CREATE TYPE match_status AS ENUM ('pending', 'accepted', 'rejected');

-- 1. PROFILES Tablosu
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    gender TEXT,
    role role_type DEFAULT 'student', -- Öğrenci veya Profesyonel
    user_type TEXT DEFAULT 'seeker', -- 'host' (Evi olan) veya 'seeker' (Ev arayan)
    city TEXT,
    district TEXT,
    university TEXT,
    campus TEXT,
    is_verified BOOLEAN DEFAULT FALSE, -- Hibrit Doğrulama Rozeti
    verification_document_url TEXT, -- Doğrulama için yüklenen belgenin yolu
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. PERSONALITY_RESULTS Tablosu
-- traits JSONB Örneği:
-- {
--   "smoking": false,
--   "pets": true,
--   "cleaning_habit": 4, // 1-5 arası (1: Dağınık, 5: Çok Titiz)
--   "sleep_schedule": 2, // 1-5 arası (1: Gece Kuşu, 5: Erkenci)
--   "social_battery": 3, // 1-5 arası (1: İçe dönük, 5: Dışa dönük)
--   "guest_frequency": 2 // 1-5 arası
-- }
CREATE TABLE personality_results (
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
    traits JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. LISTINGS (İlanlar) Tablosu
-- preference_filters JSONB Örneği:
-- { "must_not_smoke": true, "no_pets": false, "min_cleaning_habit": 3 }
CREATE TABLE listings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    host_id UUID REFERENCES profiles(id) NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price INTEGER NOT NULL,
    utilities_included BOOLEAN DEFAULT FALSE, -- Faturalar dahil mi?
    room_count TEXT, -- Örn: "3+1"
    house_features JSONB DEFAULT '[]'::jsonb, -- ['Eşyalı', 'Asansör', 'WiFi']
    image_urls TEXT[] DEFAULT '{}', -- Fotoğraflar
    address_text TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    preference_filters JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    listing_type TEXT DEFAULT 'room_offer', -- 'room_offer' veya 'room_search'
    home_type TEXT, -- 'Müstakil', 'Apartman', 'Site' (ev sahibi için)
    empty_rooms INTEGER, -- Boş oda sayısı (ev sahibi için)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. MATCHES Tablosu
CREATE TABLE matches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID REFERENCES profiles(id) NOT NULL,
    target_profile_id UUID REFERENCES profiles(id),
    target_listing_id UUID REFERENCES listings(id),
    compatibility_score INTEGER NOT NULL, -- 0 ile 100 arasında
    status match_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT check_match_target CHECK (
        (target_profile_id IS NOT NULL AND target_listing_id IS NULL) OR 
        (target_profile_id IS NULL AND target_listing_id IS NOT NULL)
    ),
    UNIQUE(requester_id, target_profile_id),
    UNIQUE(requester_id, target_listing_id)
);

-- 5. CHAT / CONVERSATIONS Tablosu (Realtime için eklendi)
CREATE TABLE conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    participant1_id UUID REFERENCES profiles(id) NOT NULL,
    participant2_id UUID REFERENCES profiles(id) NOT NULL,
    match_id UUID REFERENCES matches(id), -- Hangi eşleşmeden dolayı oluştu
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(participant1_id, participant2_id)
);

-- 6. MESSAGES Tablosu (Realtime chat)
CREATE TABLE messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES profiles(id) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Handle Yeni Kayıt Olan Kullanıcılar (Trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, city, district, university, campus)
  VALUES (
      new.id, 
      COALESCE(new.raw_user_meta_data->>'full_name', 'Yeni Kullanıcı'), 
      COALESCE((new.raw_user_meta_data->>'role')::role_type, 'student'),
      new.raw_user_meta_data->>'city',
      new.raw_user_meta_data->>'district',
      new.raw_user_meta_data->>'university',
      new.raw_user_meta_data->>'campus'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- =============================================
-- ROW LEVEL SECURITY (RLS) POLİTİKALARI
-- =============================================

-- PROFILES tablosu RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes profilleri okuyabilir"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Kullanici kendi profilini guncelleyebilir"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Kullanici kendi profilini ekleyebilir"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- PERSONALITY_RESULTS tablosu RLS
ALTER TABLE personality_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes kisilik sonuclarini okuyabilir"
  ON personality_results FOR SELECT
  USING (true);

CREATE POLICY "Kullanici kendi kisilik sonucunu ekleyebilir"
  ON personality_results FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Kullanici kendi kisilik sonucunu guncelleyebilir"
  ON personality_results FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- LISTINGS tablosu RLS
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes aktif ilanlari okuyabilir"
  ON listings FOR SELECT
  USING (true);

CREATE POLICY "Kullanici kendi ilanini olusturabilir"
  ON listings FOR INSERT
  WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Kullanici kendi ilanini guncelleyebilir"
  ON listings FOR UPDATE
  USING (auth.uid() = host_id)
  WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Kullanici kendi ilanini silebilir"
  ON listings FOR DELETE
  USING (auth.uid() = host_id);

-- MATCHES tablosu RLS
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanici kendi eslesmelerini gorebilir"
  ON matches FOR SELECT
  USING (auth.uid() = requester_id OR auth.uid() = target_profile_id);

CREATE POLICY "Kullanici eslesme istegi gonderebilir"
  ON matches FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Kullanici kendi eslesmesini guncelleyebilir"
  ON matches FOR UPDATE
  USING (auth.uid() = requester_id OR auth.uid() = target_profile_id);

-- CONVERSATIONS tablosu RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanici kendi konusmalarini gorebilir"
  ON conversations FOR SELECT
  USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

CREATE POLICY "Kullanici konusma olusturabilir"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() = participant1_id OR auth.uid() = participant2_id);

-- MESSAGES tablosu RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanici konusma mesajlarini okuyabilir"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
      AND (auth.uid() = c.participant1_id OR auth.uid() = c.participant2_id)
    )
  );

CREATE POLICY "Kullanici mesaj gonderebilir"
  ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Kullanici kendi mesajini guncelleyebilir"
  ON messages FOR UPDATE
  USING (auth.uid() = sender_id);
