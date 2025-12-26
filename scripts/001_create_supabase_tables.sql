-- Supabase tables for Python بالعربي
-- NOTE: These tables use firebase_uid as a plain string identifier (NOT Supabase auth)
-- RLS is based on matching firebase_uid, not JWT claims

-- User Progress Table
CREATE TABLE IF NOT EXISTS user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT NOT NULL UNIQUE,
  completed_lesson_ids TEXT[] DEFAULT '{}',
  completed_path_ids TEXT[] DEFAULT '{}',
  current_path_id TEXT,
  current_lesson_id TEXT,
  current_card_index INTEGER DEFAULT 0,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Profiles Table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT NOT NULL UNIQUE,
  name TEXT,
  avatar_id INTEGER DEFAULT 0,
  is_linked BOOLEAN DEFAULT FALSE,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_progress_firebase_uid ON user_progress(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_user_profiles_firebase_uid ON user_profiles(firebase_uid);

-- Note: RLS policies should be added based on your security requirements
-- Since we use firebase_uid as plain string (not JWT), standard RLS won't apply
-- Consider application-level security or custom RLS if needed
