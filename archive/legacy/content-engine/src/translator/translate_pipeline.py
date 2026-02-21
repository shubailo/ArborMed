import json
import os
import glob
import time
from deep_translator import GoogleTranslator
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configuration
SOURCE_DIR = r"backend/src/data/questions"
TARGET_DIR = r"backend/src/data/questions/hungarian"
FINAL_FILE = r"backend/src/data/questions/all_questions_hungarian.json"

# Ensure target directory exists
os.makedirs(TARGET_DIR, exist_ok=True)

def translate_text(text, target_lang='hu'):
    """Translates text to Hungarian using Google Translate."""
    if not text or not isinstance(text, str):
        return text
    try:
        # Use deep_translator
        translator = GoogleTranslator(source='auto', target=target_lang)
        return translator.translate(text)
    except Exception as e:
        print(f"Error translating text: {text[:30]}... Error: {e}")
        return text

def process_question(q):
    """Deep copies and translates a single question object."""
    q_new = q.copy()
    
    # Translate core fields
    q_new['question_text'] = translate_text(q.get('question_text', ''))
    q_new['explanation'] = translate_text(q.get('explanation', ''))
    
    # Translate options (list of strings)
    if 'options' in q and isinstance(q['options'], list):
        # Handle matching type options "A -> B"
        new_options = []
        for opt in q['options']:
            if "->" in opt:
                # Split, translate parts, rejoin
                parts = opt.split("->")
                translated_parts = [translate_text(p.strip()) for p in parts]
                new_options.append(" -> ".join(translated_parts))
            else:
                new_options.append(translate_text(opt))
        q_new['options'] = new_options
    
    # Translate correct answer
    correct = q.get('correct_answer', '')
    if "->" in correct and ";" in correct:
        # Complex matching answer "A->B; C->D"
        pairs = correct.split(";")
        new_pairs = []
        for pair in pairs:
            if "->" in pair:
                parts = pair.split("->")
                translated_parts = [translate_text(p.strip()) for p in parts]
                new_pairs.append(" -> ".join(translated_parts))
            else:
                new_pairs.append(translate_text(pair.strip()))
        q_new['correct_answer'] = "; ".join(new_pairs)
    else:
        q_new['correct_answer'] = translate_text(correct)

    # Note: Keeping ID, type, bloom_level, topic, subtopic as is.
    # If topic/subtopic need translation, add here.
    # q_new['topic'] = translate_text(q.get('topic', '')) 
    
    return q_new

def process_file(file_path):
    """Reads, translates, and saves a single file."""
    filename = os.path.basename(file_path)
    target_path = os.path.join(TARGET_DIR, f"hu_{filename}")
    
    if os.path.exists(target_path):
        print(f"Skipping existing: {filename}")
        with open(target_path, 'r', encoding='utf-8') as f:
            return json.load(f)

    print(f"Processing: {filename}...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    translated_questions = []
    
    # Use threading for faster translation (I/O bound)
    # Be careful with rate limits! Google Translate has limits.
    # Using 5 workers to be safe-ish.
    with ThreadPoolExecutor(max_workers=5) as executor:
        future_to_q = {executor.submit(process_question, q): q for q in questions}
        for future in as_completed(future_to_q):
            try:
                translated_q = future.result()
                translated_questions.append(translated_q)
            except Exception as e:
                print(f"Error processing question in {filename}: {e}")
                translated_questions.append(future_to_q[future]) # Fallback to original
    
    # Sort by ID to maintain order
    translated_questions.sort(key=lambda x: x.get('id', ''))
    
    with open(target_path, 'w', encoding='utf-8') as f:
        json.dump(translated_questions, f, indent=4, ensure_ascii=False)
        
    print(f"Saved: {target_path}")
    return translated_questions

def main():
    # Find all batch files
    batch_files = glob.glob(os.path.join(SOURCE_DIR, "high_density_batch_*.json"))
    batch_files.sort() # Process in order
    
    all_questions = []
    
    print(f"Found {len(batch_files)} batch files to translate.")
    
    for file_path in batch_files:
        batch_questions = process_file(file_path)
        all_questions.extend(batch_questions)
        # Sleep briefly to be nice to the API
        time.sleep(1)

    # Save merged file
    print(f"Merging {len(all_questions)} questions into {FINAL_FILE}...")
    with open(FINAL_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_questions, f, indent=4, ensure_ascii=False)
    
    print("Done! Translation complete.")

if __name__ == "__main__":
    main()
