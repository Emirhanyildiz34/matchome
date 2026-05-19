-- ==============================================
-- 2. EL EŞYALAR TABLOSU KURULUMU
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- ==============================================

-- Tabloyu oluştur
CREATE TABLE IF NOT EXISTS second_hand_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price INTEGER NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'TL',
    category TEXT NOT NULL DEFAULT 'diger',
  subcategory TEXT,
  -- Kategoriler: kiyafet, aksesuar, teknoloji, mutfak, ders_kitabi, mobilya, spor, diger
    condition TEXT NOT NULL DEFAULT 'iyi',
    -- Durumlar: sifir_gibi, az_kullanilmis, iyi, makul
    image_urls TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    city TEXT,
  district TEXT,
    show_phone BOOLEAN DEFAULT FALSE,
    contact_phone TEXT,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- İndexler
CREATE INDEX IF NOT EXISTS idx_second_hand_items_seller ON second_hand_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_second_hand_items_category ON second_hand_items(category);
CREATE INDEX IF NOT EXISTS idx_second_hand_items_subcategory ON second_hand_items(subcategory);
CREATE INDEX IF NOT EXISTS idx_second_hand_items_active ON second_hand_items(is_active);
CREATE INDEX IF NOT EXISTS idx_second_hand_items_city_district ON second_hand_items(city, district);

-- updated_at otomatik güncelleme trigger'ı
CREATE OR REPLACE FUNCTION update_second_hand_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_second_hand_updated_at ON second_hand_items;
CREATE TRIGGER trg_second_hand_updated_at
  BEFORE UPDATE ON second_hand_items
  FOR EACH ROW EXECUTE FUNCTION update_second_hand_updated_at();

-- RLS etkinleştir
ALTER TABLE second_hand_items ENABLE ROW LEVEL SECURITY;

-- Herkes aktif ilanları görebilir
DROP POLICY IF EXISTS "Aktif esyalari goruntule" ON second_hand_items;
CREATE POLICY "Aktif esyalari goruntule"
  ON second_hand_items FOR SELECT TO authenticated
  USING (is_active = TRUE OR seller_id = auth.uid());

-- Sadece kendi ilanını ekleyebilir
DROP POLICY IF EXISTS "Esya ekle" ON second_hand_items;
CREATE POLICY "Esya ekle"
  ON second_hand_items FOR INSERT TO authenticated
  WITH CHECK (seller_id = auth.uid());

-- Sadece kendi ilanını güncelleyebilir
DROP POLICY IF EXISTS "Esya guncelle" ON second_hand_items;
CREATE POLICY "Esya guncelle"
  ON second_hand_items FOR UPDATE TO authenticated
  USING (seller_id = auth.uid());

-- Sadece kendi ilanını silebilir
DROP POLICY IF EXISTS "Esya sil" ON second_hand_items;
CREATE POLICY "Esya sil"
  ON second_hand_items FOR DELETE TO authenticated
  USING (seller_id = auth.uid());

-- Realtime etkinleştir
ALTER PUBLICATION supabase_realtime ADD TABLE second_hand_items;
