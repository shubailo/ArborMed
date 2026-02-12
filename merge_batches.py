import json
import glob
import os

def merge_batches():
    all_questions = []
    # Pattern to match: tk10_batch_1_bilingual.json, tk10_batch_2_bilingual.json, etc.
    # We want to iterate 1 to 32 specifically to maintain order if possible, though ID sorting is safer.
    
    missing_batches = []
    
    for i in range(1, 33):
        filename = f"tk10_batch_{i}_bilingual.json"
        if os.path.exists(filename):
            try:
                with open(filename, 'r', encoding='utf-8') as f:
                    batch_data = json.load(f)
                    if isinstance(batch_data, list):
                        all_questions.extend(batch_data)
                    else:
                        print(f"Warning: {filename} does not contain a list.")
            except Exception as e:
                print(f"Error reading {filename}: {e}")
        else:
            missing_batches.append(filename)

    if missing_batches:
        print(f"Missing batches: {missing_batches}")
        
    # Sort by ID just in case
    # The IDs are strings like "tk10_1", "tk10_2", ... "tk10_960"
    # We need to extract the number to sort correctly.
    def get_id_num(q):
        try:
            return int(q['id'].split('_')[1])
        except:
            return 999999

    all_questions.sort(key=get_id_num)
    
    output_file = "endocrinology_questions.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_questions, f, indent=4, ensure_ascii=False)
        
    print(f"Successfully merged {len(all_questions)} questions into {output_file}")

if __name__ == "__main__":
    merge_batches()
