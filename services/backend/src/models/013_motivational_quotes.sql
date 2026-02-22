-- Create quotes table with full localization and customization support
CREATE TABLE IF NOT EXISTS quotes (
    id SERIAL PRIMARY KEY,
    text_en TEXT NOT NULL,
    text_hu TEXT DEFAULT '',
    author VARCHAR(255) DEFAULT '',
    title_en VARCHAR(100) DEFAULT 'Study Break',
    title_hu VARCHAR(100) DEFAULT 'Tanulás',
    icon_name VARCHAR(50) DEFAULT 'menu_book_rounded',
    custom_icon_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed with initial medical-themed motivational quotes (EN only for now)
INSERT INTO quotes (text_en, text_hu, author) VALUES 
('The good physician treats the disease; the great physician treats the patient who has the disease.', 'A jó orvos a betegséget gyógyítja; a nagy orvos a beteget, akinek betegsége van.', 'William Osler'),
('Medicine is a science of uncertainty and an art of probability.', 'Az orvostudomány a bizonytalanság tudománya és a valószínűség művészete.', 'William Osler'),
('Wherever the art of Medicine is loved, there is also a love of Humanity.', 'Ahol szeretik az orvoslás művészetét, ott van az emberség szeretete is.', 'Hippocrates'),
('Cure sometimes, treat often, comfort always.', 'Néha gyógyítunk, gyakran kezelünk, mindig vigasztalunk.', 'Hippocrates')
ON CONFLICT DO NOTHING;
