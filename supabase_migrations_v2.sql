-- ==============================================
-- MIGRATION: Favori Sistemi ve İlan Yönetimi v2
-- ==============================================

-- Eski ENUM'ı kaldır (varsa)
ALTER TABLE favorites DROP CONSTRAINT IF EXISTS favorites_category_check;
DROP TYPE IF EXISTS favorite_category CASCADE;

-- LISTINGS tablosuna yeni alanlar ekle
ALTER TABLE listings 
  ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS unpublished_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS extra_features JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'TL' CHECK (currency IN ('TL', 'EUR', 'USD', 'GBP'));

-- CUSTOM_CATEGORIES Tablosu (Kullanıcı tanımlı kategoriler)
CREATE TABLE IF NOT EXISTS custom_favorite_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    color TEXT DEFAULT '#FF6B9D', -- Varsayılan renk
    icon_emoji TEXT DEFAULT '❤️',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- FAVORITES Tablosu (Güncellendi - TEXT kategorisi)
CREATE TABLE IF NOT EXISTS favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE NOT NULL,
    category TEXT DEFAULT 'Diğer', -- Artık TEXT, CUSTOM kategorilerine referans
    price_at_favorite INTEGER NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, listing_id)
);

-- PRICE_HISTORY Tablosu (Fiyat Takibi)
CREATE TABLE IF NOT EXISTS price_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE NOT NULL,
    price INTEGER NOT NULL,
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- DEFAULT kategorileri her kullanıcı için oluştur trigger'ı (Opsiyonel)
-- Bunun yerine app tarafında yapabiliriz

-- CUSTOM_CATEGORIES RLS
ALTER TABLE custom_favorite_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanici kendi kategorilerini gorebilir"
  ON custom_favorite_categories FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Kullanici kategori ekleyebilir"
  ON custom_favorite_categories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanici kategorisini guncelleyebilir"
  ON custom_favorite_categories FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Kullanici kategorisini silebilir"
  ON custom_favorite_categories FOR DELETE
  USING (auth.uid() = user_id);

-- FAVORITES tablosu RLS
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanici kendi favorilerini gorebilir"
  ON favorites FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Kullanici favorisi ekleyebilir"
  ON favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanici favorisini silebilir"
  ON favorites FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Kullanici favorisini guncelleyebilir"
  ON favorites FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- PRICE_HISTORY tablosu RLS
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes fiyat gecmisini gorebilir"
  ON price_history FOR SELECT
  USING (true);

CREATE POLICY "Sistem fiyat degisimi kaydedebilir"
  ON price_history FOR INSERT
  WITH CHECK (true);

-- Index'ler (Performance)
CREATE INDEX IF NOT EXISTS idx_custom_categories_user_id ON custom_favorite_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_listing_id ON favorites(listing_id);
CREATE INDEX IF NOT EXISTS idx_price_history_listing_id ON price_history(listing_id);
CREATE INDEX IF NOT EXISTS idx_listings_published_at ON listings(published_at);
CREATE INDEX IF NOT EXISTS idx_listings_unpublished_at ON listings(unpublished_at);
