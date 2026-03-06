-- Topics
INSERT INTO topics (name, slug) VALUES 
('CardiovascularSystem', 'cardiovascular'),
('Respiratory System', 'respiratory'),
('Gastrointestinal System', 'gastrointestinal'),
('Renal System', 'renal'),
('Endocrine System', 'endocrine'),
('Neurology', 'neurology')
ON CONFLICT (slug) DO NOTHING;

-- Dummy Questions (Cardiovascular)
INSERT INTO questions (topic_id, text, type, options, correct_answer, bloom_level, difficulty, explanation) 
VALUES 
(1, 'Which of the following is a primary symptom of myocardial infarction?', 'single_choice', '["Headache", "Chest Pain", "Rash", "Knee Pain"]', 'Chest Pain', 1, 1, 'Chest pain is the classic symptom of MI due to ischemia.'),
(1, 'A patient presents with elevated troponin levels. What does this suggest?', 'single_choice', '["Liver failure", "Kidney stones", "Cardiac muscle damage", "Lung infection"]', 'Cardiac muscle damage', 2, 2, 'Troponins are specific markers for cardiac injury.'),
(1, 'Calculate the Mean Arterial Pressure (MAP) if BP is 120/80.', 'single_choice', '["93.3", "100", "110", "85"]', '93.3', 3, 3, 'MAP = DP + 1/3(SP - DP) = 80 + 1/3(40) = 93.3');
