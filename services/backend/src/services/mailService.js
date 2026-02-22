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
        const subject = 'Welcome to ArborMed! 🌿';
        const text = `Welcome to ArborMed!\n\nYour verification code is: ${otp}\n\nPlease enter this code to complete your registration. it expires in 10 minutes.`;

        // Brand Colors
        const brandColor = '#8CAA8C'; // Sage Green
        const accentColor = '#C48B76'; // Soft Clay
        const textColor = '#4A3728';   // Deep Brown
        const bgColor = '#FDFCF8';     // Ivory Cream

        const html = `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { margin: 0; padding: 0; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: ${bgColor}; }
                    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
                    .card { background-color: #ffffff; border-radius: 16px; padding: 40px; box-shadow: 0 4px 12px rgba(74, 55, 40, 0.05); text-align: center; }
                    .logo { font-size: 24px; font-weight: bold; color: ${textColor}; margin-bottom: 20px; text-decoration: none; }
                    .logo span { color: ${brandColor}; }
                    h1 { color: ${textColor}; font-size: 24px; margin-bottom: 10px; font-weight: 700; }
                    p { color: #8D6E63; font-size: 16px; line-height: 1.6; margin-bottom: 20px; }
                    .otp-box { background-color: #F5F7F5; border: 2px dashed ${brandColor}; border-radius: 12px; padding: 20px; margin: 30px 0; display: inline-block; }
                    .otp-code { font-size: 32px; font-weight: 800; color: ${textColor}; letter-spacing: 5px; font-family: monospace; }
                    .footer { margin-top: 30px; color: #9CA3AF; font-size: 12px; text-align: center; }
                    .icon { width: 64px; height: 64px; margin-bottom: 20px; border-radius: 16px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="card">
                        <!-- App Icon Placeholder (Replace src with actual hosted URL if available) -->
                        <img src="https://placehold.co/128x128/8CAA8C/ffffff/png?text=AM" alt="ArborMed Icon" class="icon">
                        
                        <div class="logo">Arbor<span>Med</span></div>
                        
                        <h1>Welcome to the Family!</h1>
                        <p>We're so excited to have you on board. To get started, please verify your email address using the code below:</p>
                        
                        <div class="otp-box">
                            <span class="otp-code">${otp}</span>
                        </div>
                        
                        <p>This code will remain valid for the next 10 minutes.</p>
                        <p style="font-size: 14px; margin-top: 30px;">Happy studying!<br>The ArborMed Team 🌿</p>
                    </div>
                    
                    <div class="footer">
                        <p>© ${new Date().getFullYear()} ArborMed. All rights reserved.<br>
                        If you didn't create an account, you can safely ignore this email.</p>
                    </div>
                </div>
            </body>
            </html>
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
