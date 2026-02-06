const nodemailer = require('nodemailer');

class MailService {
    constructor() {
        this.transporter = null;
        this.isConfigured = false;
        this.init();
    }

    init() {
        const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;

        if (SMTP_HOST && SMTP_PORT && SMTP_USER && SMTP_PASS) {
            this.transporter = nodemailer.createTransport({
                host: SMTP_HOST,
                port: parseInt(SMTP_PORT),
                secure: parseInt(SMTP_PORT) === 465, // true for 465, false for other ports
                auth: {
                    user: SMTP_USER,
                    pass: SMTP_PASS,
                },
            });
            this.isConfigured = true;
            console.log('📬 MailService: SMTP configured.');
        } else {
            console.log('📬 MailService: SMTP not configured. Emails will be logged to console.');
        }
    }

    async sendOTP(email, otp) {
        const subject = 'MedBuddy - Verification Code';
        const text = `Your verification code is: ${otp}\n\nThis code will expire in 10 minutes.`;
        const html = `
            <div style="font-family: sans-serif; padding: 20px; color: #333; max-width: 600px; margin: auto; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #4A90E2;">MedBuddy Verification</h2>
                <p>Use the following 6-digit code to verify your email address and complete your registration:</p>
                <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #4A90E2; padding: 30px; background: #f9f9f9; text-align: center; border-radius: 8px; margin: 20px 0;">
                    ${otp}
                </div>
                <p style="color: #666; font-size: 14px;">This code will expire in 10 minutes.</p>
                <p style="color: #999; font-size: 12px; border-top: 1px solid #eee; padding-top: 20px;">
                    If you did not request this, please ignore this email.
                </p>
            </div>
        `;

        if (this.isConfigured) {
            try {
                console.log(`📧 Attempting to send OTP email to: ${email}...`);
                const info = await this.transporter.sendMail({
                    from: `"MedBuddy Support" <${process.env.SMTP_USER}>`,
                    to: email,
                    subject,
                    text,
                    html,
                });
                console.log(`✅ MailService: Email sent successfully! ID: ${info.messageId}`);
            } catch (error) {
                console.error('❌ MailService: CRITICAL error sending email:', {
                    recipient: email,
                    error: error.message,
                    code: error.code,
                    stack: error.stack
                });
                throw new Error(`Failed to send email: ${error.message}`);
            }
        } else {
            console.log('\n--- 📧 [MOCK MODE] OTP LOGGED ---');
            console.log(`Target: ${email}`);
            console.log(`Code:   ${otp}`);
            console.log('----------------------------------\n');
        }
    }
}

module.exports = new MailService();
