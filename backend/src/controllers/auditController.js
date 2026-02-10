const db = require('../config/db');
const axios = require('axios');

/**
 * 🛡️ Security Audit Controller
 * Centralized logging for sensitive actions and real-time alerts.
 */

const auditLog = async ({ userId, adminId, actionType, severity = 'INFO', metadata = {} }) => {
    try {
        // 1. Log to PostgreSQL
        await db.query(
            'INSERT INTO security_audits (user_id, admin_id, action_type, severity, metadata) VALUES ($1, $2, $3, $4, $5)',
            [userId, adminId, actionType, severity, metadata]
        );

        // 2. Trigger Webhook Alert (if critical or placeholder exists)
        // GENERIC PLACEHOLDER: Set your DISCORD_WEBHOOK_URL or SLACK_WEBHOOK_URL in .env
        const webhookUrl = process.env.SECURITY_WEBHOOK_URL;

        if (webhookUrl && (severity === 'CRITICAL' || severity === 'WARNING')) {
            await axios.post(webhookUrl, {
                content: `🛡️ **Security Alert: ${actionType}**\nSeverity: ${severity}\nUser ID: ${userId || 'N/A'}\nDetails: ${JSON.stringify(metadata)}`
            }).catch(e => console.error('Failed to send security webhook:', e.message));
        }

        console.log(`[AUDIT] ${actionType} - ${severity} - User: ${userId || 'System'}`);
    } catch (error) {
        console.error('❌ Audit Logging Failed:', error);
    }
};

module.exports = { auditLog };
