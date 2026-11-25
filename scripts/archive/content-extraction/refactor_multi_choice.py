import os
import json

base_path = r'c:\Users\shuba\Desktop\ArborMed\services\backend\src\data\questions'

def refactor_multiple_choice(data):
    modified = False
    for q in data:
        # Check if it's multiple_choice
        q_type = q.get('question_type') or q.get('type')
        if q_type == 'multiple_choice':
            ans = q.get('correct_answer')
            if isinstance(ans, str):
                # If it's a semicolon separated string, split it
                if ';' in ans:
                    q['correct_answer'] = [s.strip() for s in ans.split(';')]
                    modified = True
                else:
                    # If it's just a single string but for multiple_choice, wrap it in a list
                    # Unless it already looks like a JSON string list (unlikely given current state)
                    if not ans.startswith('['):
                         q['correct_answer'] = [ans]
                         modified = True
            
            # Handle localized ones if they exist (added for robustness)
            for lang in ['en', 'hu']:
                ans_key = f'correct_answer_{lang}'
                if ans_key in q and isinstance(q[ans_key], str):
                    if ';' in q[ans_key]:
                        q[ans_key] = [s.strip() for s in q[ans_key].split(';')]
                        modified = True
                    elif not q[ans_key].startswith('['):
                        q[ans_key] = [q[ans_key]]
                        modified = True
    return modified

def main():
    for root, dirs, files in os.walk(base_path):
        for file in files:
            if file.endswith('.json'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    
                    if isinstance(data, list):
                        if refactor_multiple_choice(data):
                            with open(file_path, 'w', encoding='utf-8') as f:
                                json.dump(data, f, ensure_ascii=False, indent=2)
                            print(f"Refactored: {file_path}")
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

if __name__ == '__main__':
    main()
