const nodemailer = require('nodemailer');
require('dotenv').config({ path: './backend/.env' });

async function testConnection() {
    const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;

    console.log(`Testing connection to ${SMTP_HOST}:${SMTP_PORT}...`);

    const transporter = nodemailer.createTransport({
        host: SMTP_HOST,
        port: parseInt(SMTP_PORT),
        secure: parseInt(SMTP_PORT) === 465,
        auth: {
            user: SMTP_USER,
            pass: SMTP_PASS,
        },
        connectionTimeout: 10000, // 10s
    });

    try {
        await transporter.verify();
        console.log('✅ Connection successful!');
    } catch (error) {
        console.error('❌ Connection failed:', error.message);

        if (SMTP_PORT === '465') {
            console.log('Trying alternative: Port 587 with STARTTLS...');
            const altTransporter = nodemailer.createTransport({
                host: SMTP_HOST,
                port: 587,
                secure: false, // STARTTLS
                auth: {
                    user: SMTP_USER,
                    pass: SMTP_PASS,
                },
            });
            try {
                await altTransporter.verify();
                console.log('✅ Connection successful on port 587!');
            } catch (altError) {
                console.error('❌ Alternative failed:', altError.message);
            }
        }
    }
}

testConnection();
