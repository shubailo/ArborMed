-- Add customization fields to quotes table
ALTER TABLE quotes 
  ADD COLUMN IF NOT EXISTS title_en VARCHAR(100) DEFAULT 'Study Break',
  ADD COLUMN IF NOT EXISTS title_hu VARCHAR(100) DEFAULT 'Tanulás',
  ADD COLUMN IF NOT EXISTS icon_name VARCHAR(50) DEFAULT 'menu_book_rounded',
  ADD COLUMN IF NOT EXISTS custom_icon_url TEXT;

-- Update existing quotes to have default values
UPDATE quotes 
SET 
  title_en = COALESCE(title_en, 'Study Break'),
  title_hu = COALESCE(title_hu, 'Tanulás'),
  icon_name = COALESCE(icon_name, 'menu_book_rounded')
WHERE title_en IS NULL OR title_hu IS NULL OR icon_name IS NULL;
