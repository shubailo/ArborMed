const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const migrate = async () => {
    try {
        const migrationFiles = [
            // 'schema.sql',
            // '002_gamification.sql',
            // '003_gamification_logic.sql',
            // '004_smart_shop.sql',
            // '005_iso_coords.sql',
            // '006_flexible_question_types.sql',
            // '007_profile_fields.sql',
            // '008_friendships.sql',
            // '009_system_bot.sql',
            // '010_multi_language_support.sql',
            // '011_ecg_module.sql',
            // '012_otp_support.sql',
            // '013_motivational_quotes.sql',
            // '014_localize_quiz_entities.sql',
            // '015_quote_customization.sql',
            // '016_user_activity_tracking.sql',
            // '017_security_and_performance_fix.sql',
            // '018_admin_and_inbox.sql',
            // '019_subject_based_permissions.sql',
            // '020_supabase_security_fixes.sql',
            // '021_fix_security_lints.sql',
            // '022_standardize_active_column.sql',
            // '023_supabase_performance_optimizations.sql',
            // '024_fix_function_search_paths.sql',
            // '025_increase_slug_length.sql',
            // '026_admin_search_optimization.sql',
            '027_smart_analytics.sql'
        ];

        console.log('🚀 Running sequential migrations...');

        for (const file of migrationFiles) {
            const schemaPath = path.join(__dirname, '../models', file);
            if (!fs.existsSync(schemaPath)) {
                console.warn(`⚠️ Warning: Migration file ${file} not found. Skipping.`);
                continue;
            }
            const schemaSql = fs.readFileSync(schemaPath, 'utf8');
            fs.appendFileSync('migration_progress.log', `Starting: ${file}\n`);
            console.log(`📡 Starting: ${file}`);
            try {
                await db.query(schemaSql);
            } catch (err) {
                // 42P07: duplicate_table
                // 42701: duplicate_column
                if (err.code === '42P07' || err.code === '42701') {
                    console.log(`ℹ️  Skipped ${file} (already applied)`);
                } else {
                    console.error(`❌ Error in ${file} (Code: ${err.code}):`, err.message);
                    throw err;
                }
            }
        }

        console.log('✅ Migration successful!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Migration failed:', err);
        process.exit(1);
    }
};

migrate();
