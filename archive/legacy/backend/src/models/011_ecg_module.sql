-- ECG Diagnoses (The "Library")
CREATE TABLE IF NOT EXISTS ecg_diagnoses (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL, -- 'AFIB', 'STEMI_INF'
  name_en VARCHAR(255) NOT NULL,
  name_hu VARCHAR(255) NOT NULL,
  description_en TEXT,
  description_hu TEXT,
  severity_level VARCHAR(50) DEFAULT 'warning', -- normal, warning, critical
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ECG Cases (The actual images)
CREATE TABLE IF NOT EXISTS ecg_cases (
  id SERIAL PRIMARY KEY,
  diagnosis_id INTEGER REFERENCES ecg_diagnoses(id),
  image_url TEXT NOT NULL,
  difficulty VARCHAR(50) DEFAULT 'beginner', -- beginner, intermediate, advanced
  findings_json JSONB NOT NULL, -- { rate: 75, rhythm: 'irregular', axis: 'normal' ... }
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
