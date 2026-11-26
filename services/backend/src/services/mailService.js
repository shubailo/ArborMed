const nodemailer = require('nodemailer');
const { Resend } = require('resend');
const logger = require('../utils/logger');

class MailService {
  constructor() {
    this.resend = null;
    this.transporter = null;
    this.mode = 'disabled';
    this.isConfigured = false;
    this.init();
  }

  init() {
    this.transporter = null;
    this.resend = null;
    const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;

    // 1. Resend API mode (when SMTP_PASS starts with 're_')
    if (SMTP_PASS && SMTP_PASS.startsWith('re_') && (!SMTP_HOST || SMTP_HOST.toLowerCase() === 'smtp.resend.com')) {
      this.resend = new Resend(SMTP_PASS);
      this.mode = 'resend';
      this.isConfigured = true;
      logger.info('✅ MailService: Configured with Resend API (HTTPS)');
      return;
    }

    if (SMTP_PASS && SMTP_USER) {
      const port = SMTP_PORT ? Number(SMTP_PORT) : 465;
      if (!Number.isInteger(port) || port < 1 || port > 65535 ||
          (SMTP_PORT && !/^\d+$/.test(SMTP_PORT))) {
        this.mode = 'disabled';
        this.isConfigured = false;
        logger.error('SMTP port must be an integer between 1 and 65535.');
        return;
      }
      const transportOptions = {
        host: SMTP_HOST || 'smtp.gmail.com',
        port,
        secure: port === 465,
        auth: { user: SMTP_USER, pass: SMTP_PASS },
        connectionTimeout: 5000,
        greetingTimeout: 5000,
        socketTimeout: 5000,
      };
      this.transporter = nodemailer.createTransport(transportOptions);
      this.mode = 'smtp';
      this.isConfigured = true;
      logger.info('MailService: Configured with SMTP');
      return;
    }

    this.mode = 'disabled';
    this.isConfigured = false;
    logger.info('MailService: email delivery is disabled until a transport is configured.');
  }

  async sendOTP(email, otp, purpose = 'registration') {
    const subject = purpose === 'password-reset' ? 'Reset your ArborMed password' : 'Verify your ArborMed email';
    const text = `${subject}\n\nYour verification code is ${otp}. It expires in 10 minutes.`;

    // Brand Colors
    const brandColor = '#8CAA8C'; // Sage Green
    const textColor = '#4A3728'; // Deep Brown
    const bgColor = '#FDFCF8'; // Ivory Cream

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
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="card">
                        
                        <div class="logo">Arbor<span>Med</span></div>
                        
                        <h1>${subject}</h1>
                        <p>Use this code to complete your request.</p>
                        
                        <div class="otp-box">
                            <span class="otp-code">${otp}</span>
                        </div>
                        
                        <p>This code will remain valid for the next 10 minutes.</p>
                        <p style="font-size: 14px; margin-top: 30px;">Happy studying!<br>The ArborMed Team 🌿</p>
                    </div>
                    
                    <div class="footer">
                        <p>© ${new Date().getFullYear()} ArborMed. All rights reserved.<br>
                        If you did not request this code, you can ignore this email.</p>
                    </div>
                </div>
            </body>
            </html>
        `;

    if (this.mode === 'resend') {
      try {
        const sender = process.env.VERIFIED_SENDER || 'onboarding@resend.dev';
        logger.info('[API] Sending verification email.');

        const { data, error } = await this.resend.emails.send({
          from: `ArborMed Support <${sender}>`,
          to: [email],
          subject: subject,
          html: html,
          text: text,
        }, { signal: AbortSignal.timeout(10000) });

        if (error) {
          throw new Error(error.message);
        }

        logger.info(`✅ [API] Success! ID: ${data.id}`);
        return data;
      } catch (error) {
        logger.error('[API] Verification email delivery failed.');

        throw new Error('Resend API delivery failed', { cause: error });
      }
    } else if (this.mode === 'smtp') {
      try {
        const sender = process.env.SMTP_FROM || process.env.SMTP_USER;
        logger.info('[SMTP] Sending verification email.');

        const info = await this.transporter.sendMail({
          from: `ArborMed Support <${sender}>`,
          to: email,
          subject: subject,
          html: html,
          text: text,
        });

        logger.info(`✅ [SMTP] Success! Message ID: ${info.messageId}`);
        return info;
      } catch (error) {
        logger.error('[SMTP] Verification email delivery failed.');

        throw new Error('SMTP delivery failed', { cause: error });
      }
    } else {
      throw new Error('Email delivery is unavailable.');
    }
  }
}

module.exports = new MailService();
