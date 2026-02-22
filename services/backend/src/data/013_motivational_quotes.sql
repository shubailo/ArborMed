-- Create quotes table
CREATE TABLE IF NOT EXISTS quotes (
    id SERIAL PRIMARY KEY,
    text TEXT NOT NULL,
    author VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed with initial medical-themed motivational quotes
INSERT INTO quotes (text, author) VALUES 
('The good physician treats the disease; the great physician treats the patient who has the disease.', 'William Osler'),
('Medicine is a science of uncertainty and an art of probability.', 'William Osler'),
('Wherever the art of Medicine is loved, there is also a love of Humanity.', 'Hippocrates'),
('The art of healing comes from nature, not from the physician. Therefore the physician must start from nature, with an open mind.', 'Paracelsus'),
('Observation, Reason, Human Understanding, Courage; these make the physician.', 'Martin H. Fischer'),
('Let food be thy medicine and medicine be thy food.', 'Hippocrates'),
('The secret of the care of the patient is in caring for the patient.', 'Francis W. Peabody'),
('To study the phenomena of disease without books is to sail an uncharted sea, while to study books without patients is not to go to sea at all.', 'William Osler'),
('A physician is obligated to consider more than a diseased organ, more even than the whole man — he must view the man in his world.', 'Harvey Cushing'),
('Cure sometimes, treat often, comfort always.', 'Hippocrates');
