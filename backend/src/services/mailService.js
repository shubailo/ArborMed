const { Resend } = require('resend');

class MailService {
    constructor() {
        this.resend = null;
        this.isConfigured = false;
        this.init();
    }

    init() {
        const { SMTP_PASS, VERIFIED_SENDER } = process.env;

        // In Resend, the SMTP_PASS is actually the API Key (starts with re_)
        if (SMTP_PASS && SMTP_PASS.startsWith('re_')) {
            this.resend = new Resend(SMTP_PASS);
            this.isConfigured = true;
            console.log('✅ MailService: Configured with Resend API (HTTPS)');
        } else {
            console.log('❌ MailService: Resend API Key (SMTP_PASS) not found or invalid.');
            console.log('📬 MailService: Emails will be logged to console (Mock Mode).');
            this.isConfigured = false;
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
                const sender = process.env.VERIFIED_SENDER || 'onboarding@resend.dev';
                console.log(`📧 [API] Attempting to send OTP to: ${email} from ${sender}`);

                const { data, error } = await this.resend.emails.send({
                    from: `ArborMed Support <${sender}>`,
                    to: [email],
                    subject: subject,
                    html: html,
                    text: text
                });

                if (error) {
                    throw new Error(error.message);
                }

                console.log(`✅ [API] Success! ID: ${data.id}`);
                return data;
            } catch (error) {
                console.error(`❌ [API] CRITICAL FAILURE for ${email}:`, error.message);

                // 🛠️ FAIL-SAFE: Log the OTP to the console so the dev can still test
                console.log('\n--- 🆘 [FAIL-SAFE] OTP RECOVERY LOG ---');
                console.log(`Recipient: ${email}`);
                console.log(`Code:      ${otp}`);
                console.log('--------------------------------------\n');

                throw new Error(`Resend API Error: ${error.message} (Code logged to console)`, { cause: error });
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
