const nodemailer = require('nodemailer');

class MailService {
    constructor() {
        this.transporter = null;
        this.isConfigured = false;
        this.init();
    }

    init() {
        const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, VERIFIED_SENDER } = process.env;

        if (SMTP_HOST && SMTP_PORT && SMTP_USER && SMTP_PASS) {
            this.transporter = nodemailer.createTransport({
                host: SMTP_HOST,
                port: parseInt(SMTP_PORT),
                secure: parseInt(SMTP_PORT) === 465, // true for 465, false for 587
                auth: {
                    user: SMTP_USER,
                    pass: SMTP_PASS,
                },
                connectionTimeout: 10000, // 10 seconds
                greetingTimeout: 10000,
                socketTimeout: 10000,
                family: 4, // Force IPv4 to avoid IPv6 timeouts in some environments
                tls: {
                    rejectUnauthorized: false
                }
            });

            // Verify connection configuration
            this.transporter.verify((error, success) => {
                if (error) {
                    console.error('❌ MailService: SMTP connection verification failed:', error);
                    console.error('🔍 SMTP Config used:', { host: SMTP_HOST, port: SMTP_PORT, secure: parseInt(SMTP_PORT) === 465, user: SMTP_USER });
                    this.isConfigured = false;
                } else {
                    console.log('✅ MailService: SMTP server is ready to take our messages');
                    this.isConfigured = true;
                }
            });

            console.log(`📬 MailService: SMTP configured with host: ${SMTP_HOST}:${SMTP_PORT}`);
        } else {
            console.log('📬 MailService: SMTP not configured. Emails will be logged to console.');
        }
    }

    async sendOTP(email, otp) {
        const subject = 'ArborMed - Verification Code';
        const text = `Your verification code is: ${otp}\n\nThis code will expire in 10 minutes.`;
        const html = `
            <div style="font-family: sans-serif; padding: 20px; color: #333; max-width: 600px; margin: auto; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #4A90E2;">ArborMed Verification</h2>
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
                console.log(`📧 [SMTP] Attempting to send OTP to: ${email} using ${process.env.VERIFIED_SENDER}`);
                const info = await this.transporter.sendMail({
                    from: `"ArborMed Support" <${process.env.VERIFIED_SENDER || 'onboarding@resend.dev'}>`,
                    to: email,
                    subject,
                    text,
                    html,
                });
                console.log(`✅ [SMTP] Success! ID: ${info.messageId}`);
            } catch (error) {
                console.error(`❌ [SMTP] CRITICAL FAILURE for ${email}:`, error.message);
                if (error.code === 'ETIMEDOUT') {
                    console.error('ℹ️ [SMTP] Connection timed out. Ensure port 587/465 is open and host is reachable.');
                }

                // 🛠️ FAIL-SAFE: Log the OTP to the console so the dev can still test
                console.log('\n--- 🆘 [FAIL-SAFE] OTP RECOVERY LOG ---');
                console.log(`Recipient: ${email}`);
                console.log(`Code:      ${otp}`);
                console.log('--------------------------------------\n');

                throw new Error(`SMTP Error: ${error.message} (Note: The code was logged to server console)`, { cause: error });
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
