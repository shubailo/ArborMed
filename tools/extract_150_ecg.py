#!/usr/bin/env python3
"""
ArborMed - 150 ECG Problems Extractor & Ingestion Pipeline
Extracts high-resolution cropped ECGs (excluding X-rays and vignette text),
parses patient histories, 7+2 systematic interpretation findings (with normal defaults),
and generates SQL seed migrations and JSON artifacts.
"""

import os
import re
import sys
import json
import fitz  # PyMuPDF

# Ensure stdout uses UTF-8
sys.stdout.reconfigure(encoding='utf-8')

PDF_PATH = r"C:\Users\shuba\Desktop\Projects\ArborMed\150 ekg.pdf"
OUT_IMG_DIR = r"C:\Users\shuba\Desktop\Projects\ArborMed\ArborMed\services\backend\uploads\ecg"
OUT_JSON_PATH = os.path.join(OUT_IMG_DIR, "cases_data.json")
OUT_SQL_PATH = r"C:\Users\shuba\Desktop\Projects\ArborMed\ArborMed\services\backend\migrations\046_seed_150_ecg_cases.sql"

os.makedirs(OUT_IMG_DIR, exist_ok=True)

# Common diagnosis translation map from summary to canonical code + Hungarian/English
DIAGNOSIS_MAP = [
    (r"ventricular extrasystole|pvc", "PVC", "Ventricular extrasystoles", "Kamrai extrasystolék (VES)", "warning"),
    (r"atrial extrasystole|pac", "PAC", "Atrial extrasystoles", "Pitvari extrasystolék (SVES)", "warning"),
    (r"atrial fibrillation", "AFIB", "Atrial fibrillation", "Pitvarfibrilláció", "warning"),
    (r"atrial flutter", "AFLUT", "Atrial flutter", "Pitvari lebegés (flutter)", "warning"),
    (r"sinus tachycardia", "SINUS_TACH", "Sinus tachycardia", "Sinus tachycardia", "warning"),
    (r"sinus bradycardia", "SINUS_BRADY", "Sinus bradycardia", "Sinus bradycardia", "warning"),
    (r"supraventricular tachycardia|avnrt|svt", "SVT", "Supraventricular tachycardia (AVNRT)", "Supraventricularis tachycardia (AVNRT)", "warning"),
    (r"ventricular tachycardia", "VT", "Ventricular tachycardia", "Kamrai tachycardia (VT)", "critical"),
    (r"first degree (atrio|av )?block", "AVB_1", "First degree AV block", "I. fokú atrioventricularis blokk", "normal"),
    (r"second degree (.*wenckebach|.*mobitz i\b)", "AVB_2_M1", "Second degree AV block (Mobitz I / Wenckebach)", "II. fokú AV-blokk (Mobitz I / Wenckebach)", "warning"),
    (r"second degree .*mobitz ii\b", "AVB_2_M2", "Second degree AV block (Mobitz II)", "II. fokú AV-blokk (Mobitz II)", "critical"),
    (r"third degree|complete heart block", "AVB_3", "Complete (third degree) heart block", "III. fokú (teljes) AV-blokk", "critical"),
    (r"bifascicular block", "BIFASC_BLOCK", "Bifascicular block", "Bifascicularis blokk", "critical"),
    (r"trifascicular block", "TRIFASC_BLOCK", "Trifascicular block", "Trifascicularis blokk", "critical"),
    (r"left bundle branch block|lbbb", "LBBB", "Left bundle branch block (LBBB)", "Bal szárblokk (LBBB)", "warning"),
    (r"right bundle branch block|rbbb", "RBBB", "Right bundle branch block (RBBB)", "Jobb szárblokk (RBBB)", "warning"),
    (r"left anterior (hemi|fascicular )?block|lahb", "LAHB", "Left anterior hemiblock", "Bal elülső hemiblokk (LAHB)", "warning"),
    (r"left posterior (hemi|fascicular )?block", "LPHB", "Left posterior hemiblock", "Bal hátsó hemiblokk (LPHB)", "warning"),
    (r"acute anterior stemi|acute anterior myocardial", "STEMI_ANT", "Acute anterior STEMI", "Akut anterioris myocardialis infarctus (STEMI)", "critical"),
    (r"acute inferior stemi|acute inferior myocardial", "STEMI_INF", "Acute inferior STEMI", "Akut inferioris myocardialis infarctus (STEMI)", "critical"),
    (r"acute anterolateral stemi|acute anterolateral myocardial", "STEMI_ANTLAT", "Acute anterolateral STEMI", "Akut anterolateralis STEMI", "critical"),
    (r"acute lateral stemi|acute lateral myocardial", "STEMI_LAT", "Acute lateral STEMI", "Akut lateralis STEMI", "critical"),
    (r"acute posterior stemi|acute posterior myocardial", "STEMI_POST", "Acute posterior STEMI", "Akut posterioris STEMI", "critical"),
    (r"old inferior myocardial|inferior infarction", "OLD_MI_INF", "Old inferior myocardial infarction", "Lezajlott inferioris myocardialis infarctus", "warning"),
    (r"old anterior myocardial|anterior infarction", "OLD_MI_ANT", "Old anterior myocardial infarction", "Lezajlott anterioris myocardialis infarctus", "warning"),
    (r"ischaemia|ischemia|nstemi|subendocardial", "ISCHEMIA", "Myocardial ischaemia / NSTEMI", "Myocardialis ischaemia / NSTEMI", "warning"),
    (r"pericarditis", "PERICARDITIS", "Acute pericarditis", "Akut pericarditis", "warning"),
    (r"pulmonary embolism|cor pulmonale", "PE", "Pulmonary embolism / Acute cor pulmonale", "Tüdőembólia / Akut cor pulmonale", "critical"),
    (r"left ventricular hypertrophy|lvh", "LVH", "Left ventricular hypertrophy (LVH)", "Bal kamra hypertrophia (LVH)", "warning"),
    (r"right ventricular hypertrophy|rvh", "RVH", "Right ventricular hypertrophy (RVH)", "Jobb kamra hypertrophia (RVH)", "warning"),
    (r"wpw|wolff[–-]parkinson[–-]white", "WPW", "Wolff–Parkinson–White syndrome (WPW)", "Wolff–Parkinson–White-szindróma (WPW)", "warning"),
    (r"digoxin effect|digitalis", "DIGOXIN", "Digoxin effect", "Digoxin-hatás", "warning"),
    (r"hypokalaemia|hypokalemia", "HYPOK", "Hypokalaemia", "Hypokalaemia", "warning"),
    (r"hyperkalaemia|hyperkalemia", "HYPERK", "Hyperkalaemia", "Hyperkalaemia", "critical"),
    (r"long qt|prolonged qt", "LQTS", "Long QT syndrome", "Hosszú QT-szindróma (LQTS)", "critical"),
    (r"dextrocardia", "DEXTROCARDIA", "Dextrocardia", "Dextrocardia", "normal"),
    (r"paced|pacemaker", "PACED", "Ventricular paced rhythm", "Pacemaker-ritmus", "warning"),
    (r"normal ecg|normal record|sinus rhythm$", "NORMAL", "Normal ECG / Normal sinus rhythm", "Normál EKG / Sinus ritmus", "normal")
]

def map_diagnosis(summary_text):
    text_lower = summary_text.lower()
    for pattern, code, name_en, name_hu, severity in DIAGNOSIS_MAP:
        if re.search(pattern, text_lower):
            return code, name_en, name_hu, severity
    # Fallback slug
    clean_code = re.sub(r'[^A-Z0-9]', '_', summary_text[:20].upper()).strip('_')
    return clean_code or "MISC_CARDIO", summary_text.strip('. '), summary_text.strip('. '), "warning"

def parse_7_plus_2_findings(shows_text, summary_text, what_to_do_text, difficulty):
    combined = (shows_text + " " + summary_text).lower()

    # --- 1. Rhythm ---
    if any(k in combined for k in ["atrial fibrillation", "irregular qrs", "ventricular extrasystoles", "fibrillation", "extrasystoles"]):
        regularity = "irregular"
    else:
        regularity = "regular"

    if any(k in combined for k in ["atrial fibrillation", "atrial flutter", "junctional", "ventricular tachycardia", "accelerated idioventricular", "paced"]):
        sinus = False
    else:
        sinus = True

    if "2:1" in combined or "2 : 1" in combined or "2 : 1" in combined:
        conduction_ratio = "2:1"
    elif "3:1" in combined or "3 : 1" in combined:
        conduction_ratio = "3:1"
    elif "complete heart block" in combined or "third degree" in combined:
        conduction_ratio = "complete_block"
    else:
        conduction_ratio = "1:1"

    # --- 2. Rate ---
    rate_match = re.search(r'rate\s*(?:about|of|is)?\s*(\d{2,3})', combined)
    if rate_match:
        target_rate = int(rate_match.group(1))
        min_rate = max(30, target_rate - 5)
        max_rate = min(250, target_rate + 5)
    else:
        # Default normal rate
        target_rate = 75
        min_rate = 60
        max_rate = 100

    # --- 3. Conduction ---
    # PR interval: default 160 ms (Normal: 120-200)
    if "first degree" in combined or "pr interval prolonged" in combined or "long pr" in combined:
        pr_interval = 240
        av_block = "first_degree"
    elif "wenckebach" in combined or "mobitz i" in combined:
        pr_interval = 220
        av_block = "second_degree_mobitz1"
    elif "mobitz ii" in combined:
        pr_interval = 180
        av_block = "second_degree_mobitz2"
    elif "third degree" in combined or "complete heart block" in combined:
        pr_interval = 0
        av_block = "third_degree"
    elif "short pr" in combined or "wpw" in combined or "pre-excitation" in combined:
        pr_interval = 100
        av_block = "none"
    else:
        pr_interval = 160
        av_block = "none"

    # QRS duration: default 90 ms (Normal: < 120)
    if "bundle branch block" in combined or "lbbb" in combined or "rbbb" in combined or "wide qrs" in combined or "wpw" in combined or "ventricular tachycardia" in combined:
        qrs_duration = 140
    else:
        qrs_duration = 90

    # QT interval: default 400 ms (Normal: 350-440)
    if "prolonged qt" in combined or "long qt" in combined:
        qt_interval = 500
    elif "short qt" in combined:
        qt_interval = 320
    else:
        qt_interval = 400

    sa_block = "sa_arrest" if "sinus arrest" in combined else "none"

    # --- 4. Axis ---
    if "left axis deviation" in combined or "left anterior hemiblock" in combined:
        axis = "left"
    elif "right axis deviation" in combined or "right ventricular hypertrophy" in combined:
        axis = "right"
    elif "extreme axis" in combined:
        axis = "extreme"
    else:
        axis = "normal"

    # --- 5. P-Wave ---
    if "peaked p" in combined or "p pulmonale" in combined:
        p_morph = "peaked"
        atrial_enl = "rae"
    elif "bifid p" in combined or "p mitrale" in combined:
        p_morph = "bifid"
        atrial_enl = "lae"
    elif "inverted p" in combined:
        p_morph = "inverted"
        atrial_enl = "none"
    elif not sinus:
        p_morph = "absent"
        atrial_enl = "none"
    else:
        p_morph = "normal"
        atrial_enl = "none"

    # --- 6. QRS Morphology ---
    if "left ventricular hypertrophy" in combined or "lvh" in combined:
        hypertrophy = "lvh"
    elif "right ventricular hypertrophy" in combined or "rvh" in combined:
        hypertrophy = "rvh"
    else:
        hypertrophy = "none"

    if "left bundle branch block" in combined or "lbbb" in combined:
        bbb = "lbbb"
    elif "right bundle branch block" in combined or "rbbb" in combined:
        bbb = "rbbb"
    else:
        bbb = "none"

    if "q waves in leads ii, iii" in combined or "inferior infarction" in combined or "inferior q" in combined:
        q_waves = "inferior"
    elif "q waves in leads v1" in combined or "anterior infarction" in combined or "anterior q" in combined or "v2–v4" in combined or "v2-v4" in combined:
        q_waves = "anterior"
    elif "lateral q" in combined or "q waves in leads i, vl" in combined:
        q_waves = "lateral"
    else:
        q_waves = "none"

    # --- 7. ST-T Morphology ---
    if "raised st" in combined or "st segment elevation" in combined or "stemi" in combined:
        ischemia = "stemi_elevation"
    elif "depressed st" in combined or "st segment depression" in combined or "ischaemia" in combined or "ischemia" in combined:
        ischemia = "nstemi_depression"
    elif "digoxin" in combined or "reverse tick" in combined or "downward-sloping st" in combined:
        ischemia = "digoxin_scoop"
    elif "pericarditis" in combined or "saddle-shaped" in combined:
        ischemia = "pericarditis_diffuse"
    else:
        ischemia = "none"

    if "peaked t" in combined or "tall t" in combined or "hyperkalaemia" in combined:
        t_wave = "peaked"
    elif "inverted t" in combined or "t wave inversion" in combined:
        t_wave = "inverted"
    elif "flattened t" in combined or "flat t" in combined:
        t_wave = "flat"
    elif "biphasic t" in combined:
        t_wave = "biphasic"
    else:
        t_wave = "normal"

    # --- +2 Management / Urgency ---
    what_lower = what_to_do_text.lower()
    if any(k in what_lower for k in ["pci", "thromboly", "immediate", "emergency", "temporary pacemaker", "defibrillat", "dc cardioversion", "cardiac arrest"]):
        urgency = "Emergent"
    elif any(k in what_lower for k in ["admit", "hospital", "urgent", "digoxin toxicity", "potassium", "heparin", "troponin", "pacemaker"]):
        urgency = "Urgent"
    else:
        urgency = "Routine"

    return {
        "rhythm": {
            "regularity": regularity,
            "sinus": sinus,
            "conduction_ratio": conduction_ratio
        },
        "rate": {
            "min": min_rate,
            "max": max_rate,
            "target": target_rate
        },
        "conduction": {
            "pr_interval": pr_interval,
            "qrs_duration": qrs_duration,
            "qt_interval": qt_interval,
            "av_block": av_block,
            "sa_block": sa_block
        },
        "axis": axis,
        "p_wave": {
            "morphology": p_morph,
            "enlargement": atrial_enl
        },
        "qrs": {
            "hypertrophy": hypertrophy,
            "bbb": bbb,
            "q_waves": q_waves
        },
        "st_t": {
            "ischemia": ischemia,
            "t_wave": t_wave
        },
        "management": {
            "urgency": urgency
        }
    }

def main():
    print(f"Opening PDF: {PDF_PATH}")
    doc = fitz.open(PDF_PATH)
    total_cases = 150
    cases_records = []
    diagnoses_dict = {}

    print("Beginning extraction of all 150 ECGs (isolated grid images + structured findings)...")

    for i in range(1, total_cases + 1):
        prob_page_idx = 11 + (i - 1) * 2
        ans_page_idx = 12 + (i - 1) * 2

        prob_page = doc[prob_page_idx]
        ans_page = doc[ans_page_idx]

        # 1. Detect red millimeter ECG grid
        red_rects = []
        for d in prob_page.get_drawings():
            c = d.get('color') or d.get('fill')
            if c and len(c) >= 3 and c[0] > 0.85 and c[1] < 0.2 and c[2] < 0.35:
                r = d.get('rect')
                if r and r.width > 200:
                    red_rects.append(r)

        if not red_rects:
            # Fallback to standard top crop
            crop_rect = fitz.Rect(35, 50, 465, 275)
            grid_bottom_y = 275
        else:
            union_r = fitz.Rect(red_rects[0])
            for r in red_rects[1:]:
                union_r |= r
            # Pad slightly by 1pt to keep border line crisp
            crop_rect = fitz.Rect(union_r.x0 - 1, union_r.y0 - 1, union_r.x1 + 1, union_r.y1 + 1)
            grid_bottom_y = union_r.y1

        # 2. Render & Save high-res isolated ECG image (200 DPI)
        pix = prob_page.get_pixmap(dpi=200, clip=crop_rect)
        img_filename = f"case_{i:03d}.png"
        img_disk_path = os.path.join(OUT_IMG_DIR, img_filename)
        pix.save(img_disk_path)
        img_url = f"/uploads/ecg/{img_filename}"

        # 3. Extract Patient History / Symptoms strictly below the ECG grid
        vignette_rect = fitz.Rect(30, grid_bottom_y - 2, 465, 490)
        vignette_raw = prob_page.get_text('text', clip=vignette_rect).strip()
        vignette_lines = [
            line.strip() for line in vignette_raw.splitlines()
            if line.strip() and not line.strip().startswith('ECG ') and line.strip() != str(i)
        ]
        history_text = ' '.join(vignette_lines)
        # Fallback if somehow empty
        if not history_text:
            history_text = f"Clinical case presentation for ECG Problem {i}."

        # 4. Extract Answer Page sections
        ans_text = ans_page.get_text()

        # Summary
        summary_match = re.search(r'Summary\s*\n+(.*?)(?:See p\.||\n\n\n|$)', ans_text, re.DOTALL)
        summary = summary_match.group(1).strip().replace('\n', ' ') if summary_match else f"ECG Problem {i}"

        # Difficulty stars ( symbol in book)
        star_count = ans_text.count('')
        if star_count <= 1:
            difficulty = "beginner"
        elif star_count == 2:
            difficulty = "intermediate"
        else:
            difficulty = "advanced"

        # What to do (Management)
        what_to_do_match = re.search(r'What to do\s*\n+(.*?)(?:Summary|See p\.|$)', ans_text, re.DOTALL)
        what_to_do = what_to_do_match.group(1).strip().replace('\n', ' ') if what_to_do_match else ""

        # Clinical interpretation
        interp_match = re.search(r'Clinical interpretation\s*\n+(.*?)(?:What to do|Summary|$)', ans_text, re.DOTALL)
        clinical_interp = interp_match.group(1).strip().replace('\n', ' ') if interp_match else ""

        # Bulleted ECG shows
        shows_match = re.search(r'The ECG.*?shows:\s*\n*(.*?)(?:The chest X-ray|Clinical interpretation|What to do|Summary|See p\.|$)', ans_text, re.DOTALL)
        ecg_shows = shows_match.group(1).strip().replace('\n', ' ') if shows_match else ""

        # 5. Map to Canonical Diagnosis
        diag_code, diag_name_en, diag_name_hu, severity = map_diagnosis(summary)
        if diag_code not in diagnoses_dict:
            diagnoses_dict[diag_code] = {
                "code": diag_code,
                "name_en": diag_name_en,
                "name_hu": diag_name_hu,
                "severity_level": severity,
                "description_en": clinical_interp or summary,
                "description_hu": diag_name_hu
            }

        # 6. Parse structured 7+2 systematic interpretation findings with defaults
        findings_7_2 = parse_7_plus_2_findings(ecg_shows, summary, what_to_do, difficulty)

        # Build full findings JSON payload expected by mobile client
        full_findings = {
            "history": history_text,
            "ecg_shows": ecg_shows,
            "clinical_interpretation": clinical_interp,
            "what_to_do": what_to_do,
            "summary": summary,
            "stars": star_count,
            **findings_7_2
        }

        case_record = {
            "case_number": i,
            "diagnosis_code": diag_code,
            "image_url": img_url,
            "difficulty": difficulty,
            "findings_json": full_findings
        }
        cases_records.append(case_record)

        if i % 25 == 0 or i == 150:
            print(f"  Processed {i}/150 cases... (Latest: {diag_code} - {summary[:40]}...)")

    print(f"Saving JSON dataset to: {OUT_JSON_PATH}")
    with open(OUT_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump({
            "diagnoses": list(diagnoses_dict.values()),
            "cases": cases_records
        }, f, indent=2, ensure_ascii=False)

    print(f"Generating SQL seed migration: {OUT_SQL_PATH}")
    generate_sql_migration(list(diagnoses_dict.values()), cases_records, OUT_SQL_PATH)

    print("150 ECG Extraction and Ingestion Pipeline completed successfully!")

def generate_sql_migration(diagnoses, cases, sql_path):
    def esc(text):
        if text is None:
            return "NULL"
        return "'" + str(text).replace("'", "''") + "'"

    lines = []
    lines.append("-- 046_seed_150_ecg_cases.sql")
    lines.append("-- Automatically generated gold-standard ECG cases from Hampton's 150 ECG Problems")
    lines.append("")
    lines.append("-- Ensure secondary_diagnoses_ids exists on ecg_cases")
    lines.append("DO $$")
    lines.append("BEGIN")
    lines.append("    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ecg_cases' AND column_name = 'secondary_diagnoses_ids') THEN")
    lines.append("        ALTER TABLE ecg_cases ADD COLUMN secondary_diagnoses_ids INTEGER[] DEFAULT '{}';")
    lines.append("    END IF;")
    lines.append("    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ecg_diagnoses' AND column_name = 'standard_findings_json') THEN")
    lines.append("        ALTER TABLE ecg_diagnoses ADD COLUMN standard_findings_json JSONB;")
    lines.append("    END IF;")
    lines.append("END $$;")
    lines.append("")
    lines.append("-- 1. Seed Master Diagnoses")
    for d in diagnoses:
        code_esc = esc(d['code'])
        name_en_esc = esc(d['name_en'])
        name_hu_esc = esc(d['name_hu'])
        desc_en_esc = esc(d['description_en'])
        desc_hu_esc = esc(d['description_hu'])
        sev_esc = esc(d['severity_level'])
        lines.append(f"""INSERT INTO ecg_diagnoses (code, name_en, name_hu, description_en, description_hu, severity_level)
VALUES ({code_esc}, {name_en_esc}, {name_hu_esc}, {desc_en_esc}, {desc_hu_esc}, {sev_esc})
ON CONFLICT (code) DO UPDATE SET
    name_en = EXCLUDED.name_en,
    name_hu = EXCLUDED.name_hu,
    description_en = EXCLUDED.description_en,
    description_hu = EXCLUDED.description_hu,
    severity_level = EXCLUDED.severity_level;""")

    lines.append("")
    lines.append("-- 2. Seed All 150 ECG Cases")
    for c in cases:
        diag_code_esc = esc(c['diagnosis_code'])
        img_esc = esc(c['image_url'])
        diff_esc = esc(c['difficulty'])
        findings_json_esc = esc(json.dumps(c['findings_json'], ensure_ascii=False))

        lines.append(f"""INSERT INTO ecg_cases (diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids)
SELECT id, {img_esc}, {diff_esc}, {findings_json_esc}::jsonb, '{{}}'::integer[]
FROM ecg_diagnoses WHERE code = {diag_code_esc}
ON CONFLICT DO NOTHING;""")

    with open(sql_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')

if __name__ == "__main__":
    main()
