const API_BASE = 'http://localhost:3000';

const log = (msg) => console.log(`[VERIFY] ${msg}`);

async function runCheck() {
    log('Starting Final Security Verification (Reordered)...');

    const results = [];

    // 1. Test Password Policy (MUST BE FIRST)
    log('Testing Password Policy (Min 8 chars)...');
    try {
        const respReg = await fetch(`${API_BASE}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'test@sec.com', password: '1' })
        });
        const dataReg = await respReg.json();
        log(`Register response for weak password: ${JSON.stringify(dataReg)}`);
        if (respReg.status === 400 && dataReg.message.includes('at least 8 characters')) {
            results.push('✅ Weak Password Policy (Min 8) is enforced.');
        } else {
            results.push('❌ Weak Password Policy NOT ENFORCED.');
        }
    } catch (e) { log(`Error: ${e.message}`); }

    // 2. Test Account Enumeration in OTP
    log('Testing Account Enumeration in /auth/request-otp...');
    try {
        const invalidEmail = `non-existent-${Math.random()}@test.com`;
        const respOtp = await fetch(`${API_BASE}/auth/request-otp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: invalidEmail })
        });
        const dataOtp = await respOtp.json();
        log(`Response for invalid email: ${JSON.stringify(dataOtp)}`);
        if (dataOtp.message.includes('If this email is registered')) {
            results.push('✅ Account Enumeration mitigated in OTP flow.');
        } else {
            results.push('❌ Account Enumeration STILL POSSIBLE.');
        }
    } catch (e) { log(`Error: ${e.message}`); }

    // 3. Test Unprotected Routes (Now Protected)
    log('Testing /api/upload (Anonymous)...');
    try {
        const resp = await fetch(`${API_BASE}/api/upload`, { method: 'POST' });
        log(`Status: ${resp.status}`);
        if (resp.status === 401 || resp.status === 403) {
            results.push('✅ /api/upload is now protected.');
        } else {
            results.push('❌ /api/upload IS STILL UNPROTECTED!');
        }
    } catch (e) { log(`Error: ${e.message}`); }

    // 4. Test Rate Limiting (destructive)
    log('Testing Rate Limiting on /auth/login...');
    let limitReached = false;
    for (let i = 0; i < 55; i++) {
        const resp = await fetch(`${API_BASE}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'non-existent@test.com', password: 'wrong' })
        });
        if (resp.status === 429) {
            limitReached = true;
            log(`Rate limit triggered at attempt ${i + 1}`);
            break;
        }
    }
    if (limitReached) {
        results.push('✅ Rate Limiting is active (429 received).');
    } else {
        results.push(`❌ Rate Limiting NOT WORKING (last status: ${resp.status})`);
    }

    // Report Summary
    console.log('\n--- FINAL SECURITY VERIFICATION SUMMARY ---');
    results.forEach(r => console.log(r));
    console.log('-------------------------------------------\n');
}

runCheck();
