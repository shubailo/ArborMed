const { listDirectory, userHistory } = require('../services/adminDirectory');
const db = require('../config/db');
const { questionScope, questionFilter } = require('../services/adminQuestionAccess');
const learningService = require('../services/learningService');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const { positiveId } = require('../utils/quizIds');

const DAYS_MS = 1000 * 60 * 60 * 24;

function calculateTopicMetrics(rows) {
  const now = new Date();
  return rows.map((row) => {
    const daysElapsed = (now - new Date(row.last_studied_at)) / DAYS_MS;
    const retention = learningService.calculateRetention(
      daysElapsed,
      row.stability || 1.0
    );
    const readiness = learningService.calculateReadiness(
      row.mastery_score || 0,
      retention
    );
    return {
      topic: row.name_en,
      slug: row.slug,
      retention,
      readiness,
      daysSince: Math.round(daysElapsed * 10) / 10,
      mastery: row.mastery_score,
    };
  });
}

function buildReadinessResponse(metrics) {
  const total = metrics.reduce((sum, m) => sum + m.readiness, 0);
  return {
    overallReadiness:
      metrics.length > 0 ? Math.round(total / metrics.length) : 0,
    breakdown: metrics
      .map((m) => ({
        topic: m.topic,
        slug: m.slug,
        score: m.readiness,
        metrics: { mastery: m.mastery, retention: m.retention },
      }))
      .sort((a, b) => a.score - b.score),
  };
}

function reviewTopics(metrics) {
  return metrics.filter(topic => topic.retention < 85).sort((a, b) => a.retention - b.retention);
}

const PROGRESS_QUERY = `
    SELECT t.name_en, t.slug, utp.last_studied_at, utp.stability,
           utp.retention_score as last_retention, utp.mastery_score
    FROM user_topic_progress utp
    JOIN topics t ON utp.topic_slug = t.slug
    WHERE utp.user_id = $1
`;

/**
 * Get overall mastery for major subjects
 * Calculates a proficiency percentage based on correct answers and Bloom levels
 */
exports.getSummary = catchAsync(async (req, res) => {
  const userId = req.user.id;

  // Optimized Query: Read aggregated stats from user_topic_progress
  const query = `
        SELECT 
            t_parent.name_en as subject,
            t_parent.name_en as name_en,
            t_parent.name_hu as name_hu,
            t_parent.slug as slug,
            COALESCE(SUM(utp.total_answered), 0)::int as total_answered,
            COALESCE(SUM(utp.correct_answered), 0)::int as correct_answered,
            
            -- Weighted Mastery for Parent Subject (Avg of children for now)
            COALESCE(ROUND(AVG(utp.mastery_score)), 0)::int as mastery_percent

        FROM topics t_parent
        LEFT JOIN topics t_child ON t_child.parent_id = t_parent.id
        LEFT JOIN user_topic_progress utp ON utp.topic_slug = t_child.slug AND utp.user_id = $1
        WHERE t_parent.parent_id IS NULL
        AND t_parent.slug IN ('pathophysiology', 'pathology', 'microbiology', 'pharmacology', 'ecg')
        GROUP BY t_parent.id, t_parent.name_en, t_parent.name_hu, t_parent.slug
    `;

  const result = await db.query(query, [userId]);
  res.json(result.rows);
});

exports.getActivity = catchAsync(async (req, res, next) => {
  const userId = req.user.id;
  const { timeframe = 'week', anchorDate } = req.query; // anchorDate: YYYY-MM-DD

  // Validation
  if (!['day', 'week', 'month'].includes(timeframe)) {
    return next(new AppError('Invalid timeframe', 400));
  }
  if (anchorDate && !/^\d{4}-\d{2}-\d{2}$/.test(anchorDate)) {
    return next(new AppError('Invalid anchorDate format. Use YYYY-MM-DD', 400));
  }

  // Anchor (Target Date)
  let seriesStart, seriesEnd, seriesInterval, dateTruncUnit, labelFormat;

  if (timeframe === 'day') {
    // Hour-by-hour for the specific day [00:00 - 23:00]
    dateTruncUnit = 'hour';
    seriesInterval = '1 hour';
    labelFormat = 'HH24:00';
    seriesStart = "date_trunc('day', COALESCE($2::date, CURRENT_DATE))";
    seriesEnd = "date_trunc('day', COALESCE($2::date, CURRENT_DATE)) + INTERVAL '23 hours'";
  } else if (timeframe === 'month') {
    // Day-by-day for the specific month [1st - End of Month]
    dateTruncUnit = 'day';
    seriesInterval = '1 day';
    labelFormat = 'Dy';
    seriesStart = "date_trunc('month', COALESCE($2::date, CURRENT_DATE))";
    seriesEnd = "date_trunc('month', COALESCE($2::date, CURRENT_DATE)) + INTERVAL '1 month' - INTERVAL '1 day'";
  } else {
    // Week view (Last 7 days relative to anchor)
    dateTruncUnit = 'day';
    seriesInterval = '1 day';
    labelFormat = 'Dy';
    seriesStart = "COALESCE($2::date, CURRENT_DATE) - INTERVAL '6 days'";
    seriesEnd = "COALESCE($2::date, CURRENT_DATE)";
  }

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
            AND (r.user_id = $1 OR EXISTS (SELECT 1 FROM quiz_sessions qs WHERE qs.id = r.session_id AND qs.user_id = $1))
        GROUP BY ts.series_date, day_label
        ORDER BY ts.series_date ASC
    `;

  const params = [
    userId,
    anchorDate || null,
    seriesInterval,
    labelFormat,
    dateTruncUnit,
  ];
  const result = await db.query(query, params);
  res.json(result.rows);
});

/**
 * Get question IDs missed by user in a specific timeframe for review
 */
exports.getMistakesByTimeframe = catchAsync(async (req, res, next) => {
  const userId = req.user.id;
  const { timeframe = 'week', anchorDate } = req.query;

  // Validation
  if (!['day', 'week', 'month'].includes(timeframe)) {
    return next(new AppError('Invalid timeframe', 400));
  }
  if (anchorDate && !/^\d{4}-\d{2}-\d{2}$/.test(anchorDate)) {
    return next(new AppError('Invalid anchorDate format. Use YYYY-MM-DD', 400));
  }

  let interval = '7 days';
  if (timeframe === 'month') interval = '30 days';
  if (timeframe === 'day') interval = '0 day';

  const sqlAnchorLe = "COALESCE($2::date, CURRENT_DATE) + INTERVAL '1 day'";
  const sqlAnchorGe = "COALESCE($2::date, CURRENT_DATE) - CAST($3 AS interval)";

  const query = `
        SELECT DISTINCT r.question_id
        FROM responses r
        LEFT JOIN quiz_sessions s ON r.session_id = s.id
        WHERE (r.user_id = $1 OR s.user_id = $1)
          AND r.is_correct = false
          AND r.created_at <= ${sqlAnchorLe}
          AND r.created_at >= ${sqlAnchorGe}
        ORDER BY r.question_id
    `;

  const params = [userId, anchorDate || null, interval];
  const result = await db.query(query, params);
  res.json(result.rows.map((row) => row.question_id));
});

/**
 * Get detailed mastery for a specific subject (radar chart)
 */
exports.getSubjectDetail = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { subjectSlug } = req.params;

  // ⚡ Bolt: Query Optimization. Pre-aggregated UserResponseTimes via a CTE to prevent an O(N*M) join explosion.
  const query = `
        WITH SubjectTopics AS (
            SELECT t_child.id, t_child.name_en, t_child.name_hu, t_child.slug
            FROM topics t_parent
            JOIN topics t_child ON t_child.parent_id = t_parent.id
            WHERE t_parent.slug = $2
        ),
        UserResponseTimes AS (
            SELECT q.topic_id, AVG(r.response_time_ms) AS avg_time_ms,
                   COUNT(DISTINCT r.session_id)::int AS sessions_count
            FROM responses r
            JOIN questions q ON q.id = r.question_id
            LEFT JOIN quiz_sessions qs ON qs.id = r.session_id
            WHERE (r.user_id = $1 OR qs.user_id = $1)
            GROUP BY q.topic_id
        )
        SELECT 
            st.name_en as section,
            st.name_en as name_en,
            st.name_hu as name_hu,
            st.slug as slug,
            COALESCE(utp.total_answered, 0) as attempts,
            COALESCE(urt.sessions_count, 0) as sessions_count,
            COALESCE(utp.last_studied_at, '1970-01-01'::timestamp) as last_studied,
            COALESCE(utp.current_bloom_level, 1) as bloom_level,
            COALESCE(utp.mastery_score, 0) as proficiency,
            COALESCE(ROUND(urt.avg_time_ms), 0)::int as avg_time_ms
        FROM SubjectTopics st
        LEFT JOIN user_topic_progress utp ON utp.topic_slug = st.slug AND utp.user_id = $1
        LEFT JOIN UserResponseTimes urt ON urt.topic_id = st.id
        ORDER BY st.name_en ASC
    `;

  const result = await db.query(query, [userId, subjectSlug]);
  res.json(result.rows);
});

// Older synchronized answers can identify their learner through the session only.
const studentResponses = `(
    SELECT recorded.* FROM responses recorded
    LEFT JOIN quiz_sessions session ON session.id = recorded.session_id
    JOIN users learner ON learner.id = COALESCE(recorded.user_id, session.user_id)
    WHERE learner.role = 'student'
      AND learner.email NOT IN ('test_reset@example.com', 'hemmy@arbormed.ai', 'endre@medbuddy.ai')
)`;

/**
 * @desc Get aggregate stats for all questions (Admin Panel)
 * @route GET /api/stats/questions
 */
exports.getQuestionStats = catchAsync(async (req, res, next) => {
  const { topicId } = req.query;
  const params = [];
  const conditions = [];
  if (topicId && topicId !== 'null' && topicId !== 'undefined') {
    const id = Number(topicId);
    if (!Number.isSafeInteger(id) || id <= 0 || id > 2147483647) return next(new AppError('Invalid topicId', 400));
    params.push(id);
    conditions.push(`q.topic_id IN (
      WITH RECURSIVE subtree(id) AS (
        SELECT id FROM topics WHERE id = $1
        UNION SELECT t.id FROM topics t JOIN subtree s ON t.parent_id = s.id
      ) SELECT id FROM subtree
    )`);
  }
  const scope = await questionScope(req.user);
  if (scope.topics !== null) conditions.push(questionFilter(scope, params));
  const topicFilter = conditions.length ? 'AND ' + conditions.join(' AND ') : '';
  const responseFilter = topicFilter ? `AND EXISTS (SELECT FROM questions q WHERE q.id = r.question_id ${topicFilter})` : '';

  const query = `
        SELECT 
            q.id::text as question_id,
            q.question_text_en as question_text,
            t.slug as topic_slug,
            q.bloom_level as bloom_level,
            COUNT(r.id)::int as total_attempts,
            COALESCE(SUM(CASE WHEN r.is_correct THEN 1 ELSE 0 END), 0)::int as correct_count,
            ROUND(AVG(r.response_time_ms))::int as avg_time_ms
        FROM questions q
        LEFT JOIN topics t ON q.topic_id = t.id
        LEFT JOIN ${studentResponses} r ON r.question_id = q.id
        WHERE 1=1 ${topicFilter}
        GROUP BY q.id, q.question_text_en, t.slug, q.bloom_level
        ORDER BY total_attempts DESC, question_text ASC
    `;

  const [result, userResults, bloomResult, trendResults] = await Promise.all([
    db.query(query, params),
    db.query(
      `
            SELECT 
                (SELECT COUNT(*)::int FROM users WHERE role = 'student' AND email NOT IN ('test_reset@example.com', 'hemmy@arbormed.ai', 'endre@medbuddy.ai')) as total_users,
                (SELECT COUNT(*)::int FROM users WHERE role = 'student' AND email NOT IN ('test_reset@example.com', 'hemmy@arbormed.ai', 'endre@medbuddy.ai') AND created_at > NOW() - INTERVAL '24 hours') as new_users_24h,
                COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM (COALESCE(qs.completed_at, last_answer.at) - qs.started_at)) / 60)), 0)::int as avg_session_mins
            FROM quiz_sessions qs
            LEFT JOIN LATERAL (SELECT MAX(created_at) AS at FROM responses WHERE session_id = qs.id) last_answer ON true
            WHERE EXISTS (SELECT 1 FROM users u WHERE u.id = qs.user_id AND u.role = 'student' AND u.email NOT IN ('test_reset@example.com', 'hemmy@arbormed.ai', 'endre@medbuddy.ai'))
            ${topicFilter ? `AND EXISTS (SELECT 1 FROM responses r WHERE r.session_id = qs.id ${responseFilter})` : ''}
        `,
      params
    ),
    db.query(
      `
            SELECT COALESCE(AVG(current_bloom_level), 1.0)::float as avg_bloom 
            FROM user_topic_progress utp
            WHERE EXISTS (SELECT 1 FROM users u WHERE u.id = utp.user_id AND u.role = 'student' AND u.email NOT IN ('test_reset@example.com', 'hemmy@arbormed.ai', 'endre@medbuddy.ai'))
            ${topicFilter ? `AND EXISTS (SELECT FROM topics t JOIN questions q ON q.topic_id = t.id WHERE t.slug = utp.topic_slug ${topicFilter})` : ''}
        `,
      params
    ),
    db.query(
      `
            SELECT 
                AVG(CASE WHEN is_correct THEN 100 ELSE 0 END)::float as class_avg_24h,
                AVG(q.bloom_level)::float as avg_bloom_24h
            FROM ${studentResponses} r
            JOIN questions q ON r.question_id = q.id
            WHERE r.created_at > NOW() - INTERVAL '24 hours'
            ${topicFilter}
        `,
      params
    ),
  ]);

  const stats = result.rows.map((row) => ({
    ...row,
    correct_percentage:
      row.total_attempts > 0
        ? Math.round((row.correct_count / row.total_attempts) * 100)
        : 0,
  }));

  const attempts = stats.reduce((sum, row) => sum + row.total_attempts, 0);
  const correct = stats.reduce((sum, row) => sum + row.correct_count, 0);
  const overall_avg = attempts ? 100 * correct / attempts : 0;

  const trend = trendResults.rows[0];
  const classAvg24h = trend.class_avg_24h ?? overall_avg;
  const bloom24h = trend.avg_bloom_24h ?? bloomResult.rows[0].avg_bloom;

  res.json({
    questionStats: stats,
    userStats: {
      ...userResults.rows[0],
      avg_bloom: bloomResult.rows[0].avg_bloom,
      class_avg: overall_avg,
      class_avg_trend: (classAvg24h - overall_avg).toFixed(1),
      bloom_trend: (bloom24h - bloomResult.rows[0].avg_bloom).toFixed(1),
    },
  });
});

/**
 * @desc Get hierarchical inventory summary (Admin Panel)
 */
exports.getInventorySummary = catchAsync(async (req, res) => {
  const query = `
        SELECT 
            p.id as subject_id,
            COALESCE(p.name_en, p.name_hu) as subject_name,
            c.id as section_id,
            COALESCE(c.name_en, c.name_hu) as section_name,
            COALESCE(q.bloom_level, q.difficulty, 1) as bloom_level,
            COUNT(q.id)::int as count
        FROM topics p
        JOIN topics c ON c.parent_id = p.id
        LEFT JOIN questions q ON q.topic_id = c.id
        WHERE p.parent_id IS NULL
        GROUP BY p.id, p.name_en, p.name_hu, c.id, c.name_en, c.name_hu, q.bloom_level, q.difficulty
        ORDER BY subject_name, section_name, bloom_level;
    `;
  const result = await db.query(query);

  const hierarchy = {};
  result.rows.forEach((row) => {
    if (!hierarchy[row.subject_id]) {
      hierarchy[row.subject_id] = {
        id: row.subject_id,
        name: row.subject_name,
        sections: {},
      };
    }
    if (!hierarchy[row.subject_id].sections[row.section_id]) {
      hierarchy[row.subject_id].sections[row.section_id] = {
        id: row.section_id,
        name: row.section_name,
        bloomCounts: { 1: 0, 2: 0, 3: 0, 4: 0 },
        total: 0,
      };
    }
    if (row.bloom_level) {
      hierarchy[row.subject_id].sections[row.section_id].bloomCounts[
        row.bloom_level
      ] = row.count;
      hierarchy[row.subject_id].sections[row.section_id].total += row.count;
    }
  });

  const finalData = Object.values(hierarchy).map((subject) => {
    // ⚡ Bolt: Cache Object.values result to prevent redundant array allocations
    const sections = Object.values(subject.sections);
    return {
      ...subject,
      sections,
      total: sections.reduce((acc, sec) => acc + sec.total, 0),
    };
  });

  res.json(finalData);
});

/**
 * @desc Class-wide success and answer time by subject, or by section inside one subject
 * @route GET /api/stats/admin/summary
 */
exports.getAdminSummary = catchAsync(async (req, res) => {
  const topicId = positiveId(req.query.topicId);
  if (req.query.topicId !== undefined && topicId === null) throw new AppError('Invalid topicId', 400);
  const params = topicId === null ? [] : [topicId];
  const scope = await questionScope(req.user);
  const allowed = questionFilter(scope, params);
  const query = `
    WITH RECURSIVE chart_topics(id, bucket_id) AS (
      SELECT id, id FROM topics WHERE ${topicId === null ? 'parent_id IS NULL' : 'id = $1'}
      UNION
      SELECT t.id, ${topicId === null ? 'parent.bucket_id' : 'CASE WHEN parent.id = $1 THEN t.id ELSE parent.bucket_id END'}
      FROM topics t JOIN chart_topics parent ON parent.id = t.parent_id
    )
    SELECT bucket.name_en AS section, bucket.name_en, bucket.name_hu, bucket.slug,
           COUNT(r.id)::int AS attempts,
           COALESCE(ROUND(100.0 * COUNT(r.id) FILTER (WHERE r.is_correct) / NULLIF(COUNT(r.id), 0)), 0)::int AS proficiency,
           COALESCE(ROUND(AVG(r.response_time_ms)), 0)::int AS avg_time_ms
    FROM chart_topics t
    JOIN topics bucket ON bucket.id = t.bucket_id
    JOIN questions q ON q.topic_id = t.id
    LEFT JOIN ${studentResponses} r ON r.question_id = q.id
    WHERE ${allowed}
    GROUP BY bucket.id, bucket.name_en, bucket.name_hu, bucket.slug
    ORDER BY bucket.name_en, bucket.id
  `;
  const result = await db.query(query, params);
  res.json(result.rows);
});

/**
 * @desc Get all users with performance metrics (Admin Panel - Users Page)
 * @route GET /api/stats/admin/users-performance
 */
exports.getUsersPerformance = catchAsync(async (req, res) => {
    res.json(await listDirectory(req.query, 'student'));
});

/**
 * @desc Get detailed history for a specific user (Admin Panel - User Detail View)
 * @route GET /api/stats/admin/users/:userId/history
 */
exports.getUserHistory = catchAsync(async (req, res) => {
  const userId = positiveId(req.params.userId);
  if (userId === null) throw new AppError('Invalid user ID', 400);
  let limit = parseInt(req.query.limit, 10) || 100;
  if (limit < 1) limit = 100;
  if (limit > 500) limit = 500; // 🛡️ Sentinel: Cap limit to prevent DoS

  res.json(await userHistory(userId, limit));
});

/**
 * @desc Get Smart Review recommendations (Topics with low retention)
 */
exports.getSmartReview = catchAsync(async (req, res) => {
  const result = await db.query(PROGRESS_QUERY, [req.user.id]);
  const review = reviewTopics(calculateTopicMetrics(result.rows));
  res.json({ count: review.length, recommendations: review.slice(0, 5) });
});

/**
 * @desc Get Exam Readiness Score (Weighted Metric)
 */
exports.getReadiness = catchAsync(async (req, res) => {
  const result = await db.query(PROGRESS_QUERY, [req.user.id]);
  res.json(buildReadinessResponse(calculateTopicMetrics(result.rows)));
});

/**
 * @desc Get Analytics for a specific user (Admin Panel)
 */
exports.getAdminUserAnalytics = catchAsync(async (req, res) => {
  const result = await db.query(PROGRESS_QUERY, [req.params.userId]);
  const metrics = calculateTopicMetrics(result.rows);

  res.json({
    readiness: buildReadinessResponse(metrics),
    smartReview: reviewTopics(metrics).slice(0, 5),
  });
});
