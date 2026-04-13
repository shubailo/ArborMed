const db = require('../src/config/db');

async function checkActivity() {
  const userId = 999; // Test user
  const timeframe = 'week';
  
  // Use the updated logic from statsController.js
  let seriesStart = "COALESCE($2::date, CURRENT_DATE) - INTERVAL '6 days'";
  let seriesEnd = "COALESCE($2::date, CURRENT_DATE)";
  
  let seriesInterval = '1 day';
  let dateTruncUnit = 'day';
  let labelFormat = 'Dy';

  const query = `
        WITH time_series AS (
            SELECT generate_series(
                CAST(${seriesStart} AS timestamptz), 
                CAST(${seriesEnd} AS timestamptz), 
                CAST($3 AS interval)
            ) as series_date
        )
        SELECT 
            ts.series_date as date,
            TO_CHAR(ts.series_date, $4) as day_label,
            COUNT(r.id)::int as count,
            COUNT(CASE WHEN r.is_correct THEN 1 END)::int as correct_count
        FROM time_series ts
        LEFT JOIN responses r ON date_trunc($5, r.created_at) = ts.series_date
            AND EXISTS (SELECT 1 FROM quiz_sessions qs WHERE qs.id = r.session_id AND qs.user_id = $1)
        GROUP BY ts.series_date, day_label
        ORDER BY ts.series_date ASC
    `;

  const params = [
    userId,
    null, // anchorDate is null
    seriesInterval,
    labelFormat,
    dateTruncUnit,
  ];

  try {
    console.log('Executing query with COALESCE fix...');
    const result = await db.query(query, params);
    console.log('Success! Result count:', result.rows.length);
    console.log('First row:', result.rows[0]);
  } catch (err) {
    console.error('FAILED even with COALESCE fix:');
    console.error(err);
  } finally {
    process.exit();
  }
}

checkActivity();
