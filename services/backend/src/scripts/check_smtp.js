require('dotenv').config();
const { Resend } = require('resend');

async function testResend() {
  console.log('🔍 Testing Resend API Connection (HTTPS)...');

  const apiKey = process.env.SMTP_PASS;

  if (!apiKey || !apiKey.startsWith('re_')) {
    console.error(
      '❌ Error: SMTP_PASS does not look like a valid Resend API key (should start with "re_").'
    );
    return;
  }

  const resend = new Resend(apiKey);
  const sender = process.env.VERIFIED_SENDER || 'onboarding@resend.dev';

  try {
    console.log(`📧 Attempting to send test email from ${sender}...`);

    const { data, error } = await resend.emails.send({
      from: `Resend Test <${sender}>`,
      to: 'test_recipient@example.com', // Replace with real email if needed, or just let it bounce/deliver
      subject: 'Resend API Test',
      html: '<strong>It works!</strong>',
    });

    if (error) {
      console.error('❌ API Request Failed:', error);
    } else {
      console.log('✅ API Request Successful!');
      console.log('Message ID:', data.id);
    }
  } catch (err) {
    console.error('❌ Unexpected Error:', err);
  }
}

testResend();
