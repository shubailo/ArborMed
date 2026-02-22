-- Users
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'student', -- student, admin
  coins INTEGER DEFAULT 0,
  xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Topics (Cardiovascular, etc)
CREATE TABLE IF NOT EXISTS topics (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  parent_id INTEGER REFERENCES topics(id)
);

-- Questions
CREATE TABLE IF NOT EXISTS questions (
  id SERIAL PRIMARY KEY,
  topic_id INTEGER REFERENCES topics(id),
  text TEXT NOT NULL,
  type VARCHAR(50) NOT NULL, -- single_choice, etc
  options JSONB NOT NULL, -- Array of strings
  correct_answer TEXT NOT NULL,
  explanation TEXT,
  bloom_level INTEGER NOT NULL CHECK (bloom_level BETWEEN 1 AND 6),
  difficulty INTEGER NOT NULL CHECK (difficulty BETWEEN 1 AND 5),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Quiz Sessions
CREATE TABLE IF NOT EXISTS quiz_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP WITH TIME ZONE,
  score INTEGER DEFAULT 0,
  coins_earned INTEGER DEFAULT 0
);

-- Responses
CREATE TABLE IF NOT EXISTS responses (
  id SERIAL PRIMARY KEY,
  session_id INTEGER REFERENCES quiz_sessions(id),
  question_id INTEGER REFERENCES questions(id),
  user_answer TEXT,
  is_correct BOOLEAN,
  response_time_ms INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
