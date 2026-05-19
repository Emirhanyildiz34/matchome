-- ==============================================
-- CHAT SİSTEMİ KURULUMU (Tam Kurulum)
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- ==============================================

-- 1. CONVERSATIONS tablosunu oluştur (yoksa)
CREATE TABLE IF NOT EXISTS conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    participant1_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    participant2_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    last_message TEXT,
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Benzersiz kısıt (tablo yeni oluşturulduysa zaten yok, varsa ekle)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'conversations_participants_unique'
  ) THEN
    ALTER TABLE conversations
      ADD CONSTRAINT conversations_participants_unique
      UNIQUE (participant1_id, participant2_id);
  END IF;
END $$;

-- last_message sütunlarını ekle (zaten varsa bir şey yapmaz)
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS last_message TEXT;
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ DEFAULT NOW();

-- 2. MESSAGES tablosunu oluştur (yoksa)
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. RLS — conversations
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Kendi sohbetlerini goruntule" ON conversations;
CREATE POLICY "Kendi sohbetlerini goruntule"
  ON conversations FOR SELECT TO authenticated
  USING (participant1_id = auth.uid() OR participant2_id = auth.uid());

DROP POLICY IF EXISTS "Sohbet baslat" ON conversations;
CREATE POLICY "Sohbet baslat"
  ON conversations FOR INSERT TO authenticated
  WITH CHECK (participant1_id = auth.uid() OR participant2_id = auth.uid());

DROP POLICY IF EXISTS "Sohbet guncelle" ON conversations;
CREATE POLICY "Sohbet guncelle"
  ON conversations FOR UPDATE TO authenticated
  USING (participant1_id = auth.uid() OR participant2_id = auth.uid());

-- 4. RLS — messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Kendi mesajlarini goruntule" ON messages;
CREATE POLICY "Kendi mesajlarini goruntule"
  ON messages FOR SELECT TO authenticated
  USING (
    conversation_id IN (
      SELECT id FROM conversations
      WHERE participant1_id = auth.uid() OR participant2_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Mesaj gonder" ON messages;
CREATE POLICY "Mesaj gonder"
  ON messages FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid());

DROP POLICY IF EXISTS "Mesaj okundu guncelle" ON messages;
CREATE POLICY "Mesaj okundu guncelle"
  ON messages FOR UPDATE TO authenticated
  USING (
    conversation_id IN (
      SELECT id FROM conversations
      WHERE participant1_id = auth.uid() OR participant2_id = auth.uid()
    )
  );

-- 5. Realtime etkinleştir
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
