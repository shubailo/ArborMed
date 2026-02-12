
require('dotenv').config();
const nodemailer = require('nodemailer');

async function testSMTP() {
    console.log('🔍 Testing SMTP Connection...');
    console.log(`Host: ${process.env.SMTP_HOST}`);
    console.log(`Port: ${process.env.SMTP_PORT}`);
    console.log(`User: ${process.env.SMTP_USER}`);
    console.log(`Secure: ${parseInt(process.env.SMTP_PORT) === 465}`);

    const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT),
        secure: parseInt(process.env.SMTP_PORT) === 465,
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS,
        },
        connectionTimeout: 10000,
        // Force IPv4 to avoid IPv6 issues in some cloud environments
        family: 4,
        debug: true, // Enable debug output
        logger: true // Log to console
    });

    try {
        console.log('⏳ Verifying connection...');
        await transporter.verify();
        console.log('✅ SMTP Connection Successful!');

        // Optional: Send a test email
        if (process.argv.includes('--send')) {
            console.log('📧 Sending test email...');
            const info = await transporter.sendMail({
                from: process.env.VERIFIED_SENDER || 'onboarding@resend.dev',
                to: 'test_recipient@example.com', // Change this or pass via args
                subject: 'SMTP Test',
                text: 'If you receive this, SMTP is working.',
            });
            console.log(`✅ Test email sent: ${info.messageId}`);
        }
    } catch (error) {
        console.error('❌ SMTP Connection Failed:', error);
        console.error('Code:', error.code);
        console.error('Command:', error.command);
    }
}

testSMTP();
