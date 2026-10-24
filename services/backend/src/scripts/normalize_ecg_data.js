const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

function normalizeFindings(raw) {
  if (!raw || typeof raw !== 'object') return {};

  const f = { ...raw };

  // 1. Rhythm
  const rawRhythm = f.rhythm || {};
  let regularity = 'Regular';
  const regStr = (rawRhythm.regularity || '').toLowerCase();
  if (regStr.includes('irregularly')) regularity = 'Irregularly Irregular';
  else if (regStr.includes('irreg')) regularity = 'Irregular';

  let isSinus = rawRhythm.sinus !== undefined ? Boolean(rawRhythm.sinus) : true;
  let conductionRatio = '1:1';
  const condStr = (rawRhythm.conduction_ratio || rawRhythm.p_qrs_relation || '').toLowerCase();
  if (condStr.includes('2:1') || condStr.includes('2 : 1')) conductionRatio = '2:1';
  else if (condStr.includes('3:1') || condStr.includes('3 : 1')) conductionRatio = '3:1';
  else if (condStr.includes('dissociat') || condStr.includes('complete')) conductionRatio = 'Dissociated';
  else if (condStr.includes('variab')) conductionRatio = 'Variable';

  let saBlock = 'None';
  const saStr = (raw.conduction?.sa_block || rawRhythm.sa_block || '').toLowerCase();
  if (saStr.includes('arrest')) saBlock = 'Sinus Arrest';
  else if (saStr.includes('exit')) saBlock = 'SA Exit Block';

  f.rhythm = {
    regularity,
    sinus: isSinus,
    conduction_ratio: conductionRatio,
    p_qrs_relation: conductionRatio,
    sa_block: saBlock
  };

  // 2. Rate
  let targetRate = 75;
  let minRate = 60;
  let maxRate = 100;
  if (f.rate) {
    if (typeof f.rate === 'number') {
      targetRate = f.rate;
      minRate = Math.max(30, targetRate - 5);
      maxRate = Math.min(250, targetRate + 5);
    } else if (typeof f.rate === 'object') {
      targetRate = f.rate.target || f.rate.max || f.rate.min || 75;
      minRate = f.rate.min || Math.max(30, targetRate - 5);
      maxRate = f.rate.max || Math.min(250, targetRate + 5);
    }
  }
  f.rate = {
    target: targetRate,
    min: minRate,
    max: maxRate
  };

  // 3. Conduction
  const rawCond = f.conduction || {};
  let prMs = rawCond.pr_interval !== undefined ? Number(rawCond.pr_interval) : 160;
  let qrsMs = rawCond.qrs_duration !== undefined ? Number(rawCond.qrs_duration) : 90;
  let qtMs = rawCond.qt_interval !== undefined ? Number(rawCond.qt_interval) : 400;

  let prCat = 'Normal';
  if (prMs > 200) prCat = 'Prolonged';
  else if (prMs > 0 && prMs < 120) prCat = 'Short';

  let qrsCat = qrsMs >= 120 ? 'Prolonged' : 'Normal';
  let qtCat = qtMs > 440 ? 'Prolonged' : (qtMs < 350 ? 'Short' : 'Normal');

  let avBlock = 'None';
  const avStr = (rawCond.av_block || '').toLowerCase();
  if (avStr.includes('first') || avStr.includes('1st')) avBlock = '1st Degree';
  else if (avStr.includes('mobitz1') || avStr.includes('mobitz i') || avStr.includes('wenckebach')) avBlock = '2nd Degree Type I';
  else if (avStr.includes('mobitz2') || avStr.includes('mobitz ii')) avBlock = '2nd Degree Type II';
  else if (avStr.includes('third') || avStr.includes('3rd') || avStr.includes('complete')) avBlock = '3rd Degree';

  f.conduction = {
    pr_interval: prMs,
    pr_category: prCat,
    qrs_duration: qrsMs,
    qrs_category: qrsCat,
    qt_interval: qtMs,
    qt_category: qtCat,
    av_block: avBlock,
    sa_block: saBlock
  };

  // 4. Axis
  let axisQuad = 'Normal';
  const axisRaw = (typeof f.axis === 'object' ? f.axis.quadrant : f.axis) || '';
  const axisStr = axisRaw.toLowerCase();
  if (axisStr.includes('extreme')) axisQuad = 'Extreme Left Deviation';
  else if (axisStr.includes('left')) axisQuad = 'Left Deviation';
  else if (axisStr.includes('right')) axisQuad = 'Right Deviation';
  else axisQuad = 'Normal';

  f.axis = {
    quadrant: axisQuad,
    deviation: axisQuad
  };

  // 5. P-Wave & Atrial Enlargement
  const rawP = f.p_wave || {};
  let pMorph = 'Normal';
  const pMorphStr = (rawP.morphology || '').toLowerCase();
  if (pMorphStr.includes('peaked') || pMorphStr.includes('pulmonale')) pMorph = 'Peaked (Pulmonale)';
  else if (pMorphStr.includes('bifid') || pMorphStr.includes('mitrale')) pMorph = 'Bifid (Mitrale)';
  else if (pMorphStr.includes('inverted')) pMorph = 'Inverted';
  else if (pMorphStr.includes('absent') || !isSinus) pMorph = 'Absent';

  let atrialEnl = 'None';
  const enlStr = (rawP.atrial_enlargement || rawP.enlargement || '').toLowerCase();
  if (enlStr.includes('bi')) atrialEnl = 'Bi-atrial Enlargement';
  else if (enlStr.includes('left') || enlStr === 'lae') atrialEnl = 'Left Atrial Enlargement';
  else if (enlStr.includes('right') || enlStr === 'rae') atrialEnl = 'Right Atrial Enlargement';

  f.p_wave = {
    morphology: pMorph,
    enlargement: atrialEnl,
    atrial_enlargement: atrialEnl
  };

  // 6. QRS Morphology (Hypertrophy, BBB, Q-waves)
  const rawQrs = f.qrs_morph || f.qrs || {};
  let hypertrophy = 'None';
  const hypStr = (rawQrs.hypertrophy || '').toLowerCase();
  if (hypStr.includes('lvh') || hypStr.includes('left')) hypertrophy = 'LVH';
  else if (hypStr.includes('rvh') || hypStr.includes('right')) hypertrophy = 'RVH';
  else if (hypStr.includes('bi')) hypertrophy = 'Bi-ventricular';

  let bbb = 'None';
  const bbbStr = (rawQrs.bbb || '').toLowerCase();
  if (bbbStr.includes('rbbb')) bbb = 'RBBB';
  else if (bbbStr.includes('lbbb')) bbb = 'LBBB';
  else if (bbbStr.includes('ivcd')) bbb = 'IVCD';

  let qWaves = 'None';
  const qStr = (rawQrs.q_waves || '').toLowerCase();
  if (qStr.includes('inferior')) qWaves = 'Inferior';
  else if (qStr.includes('anterior')) qWaves = 'Anterior';
  else if (qStr.includes('lateral')) qWaves = 'Lateral';
  else if (qStr.includes('septal')) qWaves = 'Septal';

  const qrsData = {
    hypertrophy,
    bbb,
    q_waves: qWaves
  };
  f.qrs = qrsData;
  f.qrs_morph = qrsData;

  // 7. ST-T Segment
  const rawStT = f.st_t || {};
  let ischemia = 'None';
  const ischStr = (rawStT.ischemia || '').toLowerCase();
  if (ischStr.includes('elevation') || ischStr.includes('stemi')) ischemia = 'ST Elevation';
  else if (ischStr.includes('depression') || ischStr.includes('nstemi')) ischemia = 'ST Depression';
  else if (ischStr.includes('hyperacute')) ischemia = 'Hyperacute T Waves';
  else if (ischStr.includes('inversion')) ischemia = 'T Wave Inversion';

  let tWave = 'Normal';
  const tStr = (rawStT.t_wave || '').toLowerCase();
  if (tStr.includes('peaked')) tWave = 'Peaked';
  else if (tStr.includes('inverted')) tWave = 'Inverted';
  else if (tStr.includes('flat')) tWave = 'Flattened';
  else if (tStr.includes('biphasic')) tWave = 'Biphasic';

  f.st_t = {
    ischemia,
    t_wave: tWave
  };

  // 8. Management Urgency
  const rawMgmt = f.management || {};
  let urgency = 'Routine';
  const urgStr = (rawMgmt.urgency || '').toLowerCase();
  if (urgStr.includes('emerg')) urgency = 'Emergency';
  else if (urgStr.includes('urgent')) urgency = 'Urgent';

  f.management = {
    urgency,
    notes: rawMgmt.notes || raw.what_to_do || ''
  };

  return f;
}

async function run() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  const client = await pool.connect();
  console.log('Connected to Supabase...');

  try {
    const casesRes = await client.query('SELECT id, findings_json FROM ecg_cases ORDER BY id ASC');
    console.log(`Found ${casesRes.rows.length} cases to normalize...`);

    let updatedCount = 0;
    for (const row of casesRes.rows) {
      const normalized = normalizeFindings(row.findings_json);
      await client.query(
        'UPDATE ecg_cases SET findings_json = $1 WHERE id = $2',
        [JSON.stringify(normalized), row.id]
      );
      updatedCount++;
    }
    console.log(`✅ Successfully normalized ${updatedCount} cases in Supabase!`);

    // Also update local cases_data.json
    const casesDataPath = path.join(__dirname, '../../uploads/ecg/cases_data.json');
    if (fs.existsSync(casesDataPath)) {
      const localData = JSON.parse(fs.readFileSync(casesDataPath, 'utf8'));
      if (Array.isArray(localData.cases)) {
        localData.cases = localData.cases.map(c => ({
          ...c,
          findings_json: normalizeFindings(c.findings_json)
        }));
        fs.writeFileSync(casesDataPath, JSON.stringify(localData, null, 2), 'utf8');
        console.log(`✅ Updated local cases_data.json with normalized findings!`);
      }
    }

    // Verify a sample case
    const sample = await client.query('SELECT id, findings_json FROM ecg_cases WHERE image_url LIKE \'%case_026.png%\' LIMIT 1');
    console.log('Verified Case 26 Normalized:');
    console.log(JSON.stringify(sample.rows[0].findings_json, null, 2));

  } catch (err) {
    console.error('Error normalizing cases:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
