-- =======================================================
-- CAMPUS TOPLULUK DUYURULARI: TARİH ALANLARI
-- Supabase Dashboard > SQL Editor'da çalıştırın
-- =======================================================

-- 1. Duyuru görünürlük tarihleri ve etkinlik tarihi
ALTER TABLE campus_announcements
  ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS event_date TIMESTAMP WITH TIME ZONE;

-- 2. Var olan kayıtlara varsayılan yayın aralığı ata
UPDATE campus_announcements
SET start_date = COALESCE(start_date, created_at),
    end_date = COALESCE(end_date, created_at + INTERVAL '7 days')
WHERE start_date IS NULL OR end_date IS NULL;

-- 3. Tarih tutarlılığı
ALTER TABLE campus_announcements
  DROP CONSTRAINT IF EXISTS campus_announcements_date_range_check;

ALTER TABLE campus_announcements
  ADD CONSTRAINT campus_announcements_date_range_check
  CHECK (
    end_date IS NULL
    OR start_date IS NULL
    OR end_date >= start_date
  );

-- 4. Performans indeksleri
CREATE INDEX IF NOT EXISTS idx_campus_ann_start_end
  ON campus_announcements(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_campus_ann_event_date
  ON campus_announcements(event_date);
