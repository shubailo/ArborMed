const axios = require('axios');
const db = require('./src/config/db');

const API_URL = 'http://localhost:3000/auth';
const TEST_EMAIL = 'test_reset@example.com';
const NEW_PASS = 'newsecurepass123';

async function test() {
    try {
        console.log('🧪 Starting Forgot Password Backend Test...');

        // 0. Ensure test user exists
        await db.query(`
            INSERT INTO users (email, password_hash, username, display_name) 
            VALUES ($1, 'dummy', 'testreset', 'Test Reset') 
            ON CONFLICT (email) DO NOTHING
        `, [TEST_EMAIL]);

        // 1. Request OTP
        console.log('Step 1: Requesting OTP...');
        const reqOtp = await axios.post(`${API_URL}/request-otp`, { email: TEST_EMAIL });
        console.log('Response:', reqOtp.data.message);

        // 2. Peek into DB to get the OTP (since we are mocking email)
        console.log('Step 2: Retrieving OTP from DB...');
        const otpResult = await db.query('SELECT otp FROM password_resets WHERE email = $1', [TEST_EMAIL]);
        if (otpResult.rows.length === 0) throw new Error('OTP not found in DB!');
        const otp = otpResult.rows[0].otp;
        console.log(`Retrieved OTP: ${otp}`);

        // 3. Reset Password
        console.log('Step 3: Resetting password...');
        const resetResp = await axios.post(`${API_URL}/reset-password`, {
            email: TEST_EMAIL,
            otp: otp,
            newPassword: NEW_PASS
        });
        console.log('Response:', resetResp.data.message);

        // 4. Verify Login
        console.log('Step 4: Verifying login with new password...');
        const loginResp = await axios.post(`${API_URL}/login`, {
            email: TEST_EMAIL,
            password: NEW_PASS
        });
        console.log('Login successful! Token received:', loginResp.data.token ? 'YES' : 'NO');

        console.log('✅ Forgot Password Backend Test PASSED!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Test failed:', err.response?.data || err.message);
        process.exit(1);
    }
}

test();
