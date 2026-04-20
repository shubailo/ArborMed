const fs = require('fs');
const path = 'c:/Users/shuba/Desktop/ArborMed/services/backend/src/data/questions/pathophysiology/renal-homeostasis.json';
let data = JSON.parse(fs.readFileSync(path));
const newItems = [
  {
    "id": "GP-TK1-S09",
    "subject": "pathophysiology",
    "topic": "renal-homeostasis",
    "sub_topic": "tubular-function",
    "bloom_level": 3,
    "text": "Egy beteg vizeletében glükóz mutatható ki, miközben az éhomi vércukorszintje és a glükóz-tolerancia tesztje is teljesen normális. Mi a legvalószínűbb háttérfolyamat?",
    "options": [
      { "id": "a", "text": "SGLT-2 receptorok genetikai vagy szerzett defektusa" },
      { "id": "b", "text": "fokozott renális glükoneogenezis" },
      { "id": "c", "text": "inzulinrezisztencia kezdeti stádiuma" },
      { "id": "d", "text": "mellékvesekéreg-elégtelenség (Addison-kór)" },
      { "id": "e", "text": "fokozott növekedési hormon elválasztás" }
    ],
    "correct_answer": "a",
    "explanation": "1. Trigger: A glükozuria normál vércukorszint mellett a tubuláris visszaszívó kapacitás hibáját jelzi. 2. Response: Az SGLT-2 transzporterek felelősek a filtrált glükóz 90%-ának visszaszívásáért a proximális tubulusban. 3. Endpoint: Ezen transzporterek hibája (renális diabetes) szelektív glükozuriát okoz metabolikus zavar nélkül.",
    "text_en": "Glucose is detected in a patient's urine, while fasting blood glucose and GGT are entirely normal. What is the most likely underlying process?",
    "explanation_en": "1. Trigger: Glucosuria with normal blood sugar indicates a defect in tubular reabsorptive capacity. 2. Response: SGLT-2 transporters are responsible for 90% of glucose reabsorption in the proximal tubule. 3. Endpoint: A defect in these transporters (renal diabetes) causes selective glucosuria without metabolic dysfunction.",
    "nexus_links": ["metabolism", "renal"]
  },
  {
    "id": "GP-TK1-S10",
    "subject": "pathophysiology",
    "topic": "renal-homeostasis",
    "sub_topic": "nephrotic-syndrome",
    "bloom_level": 4,
    "text": "Krónikus gyulladásos folyamatok (pl. rheumatoid arthritis) szövődményeként jelentkező masszív proteinuria és ödéma esetén melyik kórkép a legvalószínűbb?",
    "options": [
      { "id": "a", "text": "szekunder AA-amyloidosis" },
      { "id": "b", "text": "akut poststreptococcus glomerulonephritis" },
      { "id": "c", "text": "benignus nephrosclerosis" },
      { "id": "d", "text": "vesevéna thrombosis" },
      { "id": "e", "text": "akut tubuláris nekrózis" }
    ],
    "correct_answer": "a",
    "explanation": "1. Trigger: Krónikus gyulladásban fokozott az SAA (szérum amyloid A) termelés. 2. Response: Az amyloid-lerakódás károsítja a glomeruláris filtrációs gátat. 3. Endpoint: Masszív proteinuria és másodlagos nephrosis szindróma alakul ki.",
    "text_en": "In the case of massive proteinuria and edema occurring as a complication of chronic inflammatory processes (e.g., rheumatoid arthritis), which condition is most likely?",
    "explanation_en": "1. Trigger: Chronic inflammation increases SAA (serum amyloid A) production. 2. Response: Amyloid deposition damages the glomerular filtration barrier. 3. Endpoint: Massive proteinuria and secondary nephrotic syndrome develop.",
    "nexus_links": ["immunology", "renal"]
  },
  {
    "id": "GP-TK1-S11",
    "subject": "pathophysiology",
    "topic": "renal-homeostasis",
    "sub_topic": "renal-failure",
    "bloom_level": 4,
    "text": "Mi a renális osteodystrophia kialakulásának primer indítéka krónikus veseelégtelenségben?",
    "options": [
      { "id": "a", "text": "foszfát-retenció és az 1,25-(OH)2-D3-vitamin hiánya" },
      { "id": "b", "text": "közvetlen csontvelő-toxicitás az urea miatt" },
      { "id": "c", "text": "fokozott kalcium-vesztés a vizelettel" },
      { "id": "d", "text": "az aldoszteron-szint drasztikus csökkenése" },
      { "id": "e", "text": "krónikus metabolikus alkalózis" }
    ],
    "correct_answer": "a",
    "explanation": "1. Trigger: A csökkent GFR miatt a foszfát nem választódik ki, a veseszövet pusztulása miatt pedig csökken az aktív D-vitamin szintézis. 2. Response: A hyperphosphataemia és hypocalcaemia stimuálja a parathormon (PTH) elválasztást. 3. Endpoint: A secundaer hyperparathyreosis demineralizációt és csontdeformitásokat (osteodystrophia) szül.",
    "text_en": "What is the primary trigger for the development of renal osteodystrophy in chronic renal failure?",
    "explanation_en": "1. Trigger: Reduced GFR leads to phosphate retention, while loss of renal tissue decreases active Vitamin D synthesis. 2. Response: Hyperphosphatemia and hypocalcemia stimulate PTH secretion. 3. Endpoint: Secondary hyperparathyroidism leads to bone demineralization and deformities (osteodystrophy).",
    "nexus_links": ["endocrinology", "skeletal-system", "renal"]
  },
  {
    "id": "GP-TK1-S12",
    "subject": "pathophysiology",
    "topic": "renal-homeostasis",
    "sub_topic": "renal-failure",
    "bloom_level": 4,
    "text": "Uraemiás betegeknél gyakran jelentkező kínzó bőrviszketés (pruritus) hátterében melyik kórélettani tényező áll?",
    "options": [
      { "id": "a", "text": "kalcium-foszfát kristályok lerakódása és uraemiás toxinok irritációja" },
      { "id": "b", "text": "a bőr fokozott melanocita-aktivitása" },
      { "id": "c", "text": "szisztémás hisztamin-hiány" },
      { "id": "d", "text": "fokozott faggyútermelés és zsírosodás" },
      { "id": "e", "text": "krónikus vashiányos anaemia miatti hám-atrófia" }
    ],
    "correct_answer": "a",
    "explanation": "1. Trigger: A veseelégtelenségben visszamaradó foszfát és kalcium kicsapódik a szövetekben. 2. Response: A szekunder hyperparathyreosis és a toxinok irritálják a bőr idegvégződéseit. 3. Endpoint: Intenzív pruritus alakul ki, ami gyakran rezisztens a lokális kezelésre.",
    "text_en": "What pathophysiological factor underlies the frequent distressing skin itching (pruritus) in uraemic patients?",
    "explanation_en": "1. Trigger: Retained phosphate and calcium in renal failure precipitate in tissues. 2. Response: Secondary hyperparathyroidism and toxins irritate nerve endings in the skin. 3. Endpoint: Intensive pruritus develops, often resistant to topical treatments.",
    "nexus_links": ["dermatology", "renal", "endocrinology"]
  }
];
data.push(...newItems);
fs.writeFileSync(path, JSON.stringify(data, null, 2));
console.log('Final count:', data.length);
