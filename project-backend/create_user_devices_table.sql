-- ============================================================
-- user_devices table (Stores IST timestamps directly)
-- Run this in Supabase SQL Editor → New Query
-- ============================================================

DROP TABLE IF EXISTS public.user_devices CASCADE;

CREATE TABLE public.user_devices (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Device hardware
  device_brand   TEXT,                      -- e.g. "Realme", "Samsung"
  device_model   TEXT,                      -- e.g. "RMX3710"

  -- OS info
  android_version TEXT,                     -- e.g. "15"
  android_sdk     INTEGER,                  -- e.g. 35

  -- App version
  app_version    TEXT,                      -- e.g. "1.0.0+1"

  -- Screen
  screen_width   INTEGER,                   -- physical pixels e.g. 1080
  screen_height  INTEGER,                   -- physical pixels e.g. 2400
  screen_density NUMERIC(5, 2),             -- e.g. 2.75

  -- Form factor
  is_tablet      BOOLEAN DEFAULT FALSE,

  -- Locale & timezone
  locale         TEXT,                      -- e.g. "en_IN"
  timezone       TEXT,                      -- e.g. "IST (UTC+05:30)"

  -- Timestamps in IST
  last_seen_at   TEXT,                      -- e.g. "2026-07-28 00:07:36 IST"
  created_at     TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata'),

  -- One row per user (upsert on user_id)
  CONSTRAINT user_devices_user_id_unique UNIQUE (user_id)
);

-- Index for fast admin lookups
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- Users can only read/write their OWN device info
CREATE POLICY "Users can upsert own device info"
  ON public.user_devices
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admins can read ALL device info
CREATE POLICY "Admins can read all device info"
  ON public.user_devices
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- Done! Query user devices directly:
--
-- SELECT u.email, d.device_brand, d.device_model, d.timezone, d.last_seen_at
-- FROM user_devices d
-- JOIN users u ON u.id = d.user_id;
-- ============================================================
