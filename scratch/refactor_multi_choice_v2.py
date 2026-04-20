import json
import os

data_dir = r'c:\Users\shuba\Desktop\ArborMed\services\backend\src\data\questions'

def refactor_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
        except Exception as e:
            print(f"Error loading {file_path}: {e}")
            return
    
    modified = False
    for q in data:
        # Check for multiple_choice type (or single_choice that should be multi)
        q_type = q.get('type') or q.get('question_type')
        if q_type == 'multiple_choice':
            ans = q.get('correct_answer')
            
            # Handle list of one string that contains multiple answers (like I just saw in cardio)
            if isinstance(ans, list) and len(ans) == 1 and isinstance(ans[0], str):
                ans = ans[0]
            
            if isinstance(ans, str):
                # We need to find the correct separator. 
                # Check for semicolon first (our new standard)
                if ';' in ans:
                    q['correct_answer'] = [s.strip() for s in ans.split(';')]
                    modified = True
                elif ',' in ans:
                    # Check if it's a comma-separated list of options
                    # We compare parts with existing options to be sure
                    opts_en = q.get('options_en', [])
                    opts_hu = q.get('options_hu', [])
                    # Also check options Map
                    if isinstance(q.get('options'), dict):
                        opts_en = opts_en or q['options'].get('en', [])
                        opts_hu = opts_hu or q['options'].get('hu', [])
                    
                    # Normalize for comparison
                    all_opts = [str(o).strip().lower() for o in opts_en + opts_hu]
                    
                    # Special case for "1, 2, 3" etc (ids)
                    if not all_opts and isinstance(q.get('options'), list):
                         for o in q['options']:
                             if isinstance(o, dict):
                                 all_opts.append(str(o.get('text', '')).strip().lower())
                                 all_opts.append(str(o.get('id', '')).strip().lower())
                    
                    parts = [s.strip() for s in ans.split(',')]
                    # If all parts (or most) match an option, split it
                    matches = sum(1 for p in parts if p.lower() in all_opts)
                    if matches >= 2 or (len(parts) > 1 and matches == len(parts)):
                        q['correct_answer'] = parts
                        modified = True
                        print(f"Split by comma in {q.get('id')}")
                    else:
                        # Fallback: just wrap in list if not already
                        q['correct_answer'] = [ans]
                        modified = True
                else:
                    # Single string, wrap in list
                    q['correct_answer'] = [ans]
                    modified = True
            
            # Ensure correct_answer is never just a string for multi-choice
            if not isinstance(q.get('correct_answer'), list):
                 q['correct_answer'] = [str(q.get('correct_answer'))]
                 modified = True

    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Refactored: {file_path}")

def walk_and_refactor(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.json'):
                refactor_file(os.path.join(root, file))

if __name__ == "__main__":
    walk_and_refactor(data_dir)
