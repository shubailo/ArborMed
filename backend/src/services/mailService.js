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
        const subject = 'MedBuddy - Password Reset OTP';
        const text = `Your password reset code is: ${otp}\n\nThis code will expire in 10 minutes.`;
        const html = `
            <div style="font-family: sans-serif; padding: 20px; color: #333;">
                <h2>MedBuddy Password Reset</h2>
                <p>You requested a password reset. Use the following 6-digit code to proceed:</p>
                <div style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #4A90E2; padding: 20px 0;">
                    ${otp}
                </div>
                <p>This code will expire in 10 minutes.</p>
                <p>If you did not request this, please ignore this email.</p>
            </div>
        `;

        if (this.isConfigured) {
            try {
                await this.transporter.sendMail({
                    from: `"MedBuddy" <${process.env.SMTP_USER}>`,
                    to: email,
                    subject,
                    text,
                    html,
                });
                console.log(`✅ MailService: OTP email sent to ${email}`);
            } catch (error) {
                console.error('❌ MailService: Error sending email:', error);
                throw new Error('Failed to send email');
            }
        } else {
            console.log('\n--- 📧 MOCK EMAIL ---');
            console.log(`To: ${email}`);
            console.log(`Subject: ${subject}`);
            console.log(`Body: ${text}`);
            console.log('---------------------\n');
        }
    }
}

module.exports = new MailService();
