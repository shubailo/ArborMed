const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W\_]).{8,}$/;

const testPasswords = [
    { pass: 'asdASD123@#$', expected: true, desc: 'User password with multiple special chars including #' },
    { pass: 'Password123!', expected: true, desc: 'Standard password with !' },
    { pass: 'short1!', expected: false, desc: 'Too short' },
    { pass: 'nonumber!', expected: false, desc: 'No number' },
    { pass: 'nouppercase1!', expected: false, desc: 'No uppercase' },
    { pass: 'NO_LOWER_CASE1!', expected: false, desc: 'No lowercase' },
    { pass: 'NoSpecial123', expected: false, desc: 'No special character' },
    { pass: 'MedBuddy#2026', expected: true, desc: 'Valid password with #' },
    { pass: 'Testing=123', expected: true, desc: 'Valid password with =' },
    { pass: 'Space Pass 1!', expected: true, desc: 'Valid password with space' }
];

console.log('--- Password Regex Verification ---');
let allPassed = true;

testPasswords.forEach(({ pass, expected, desc }) => {
    const result = passwordRegex.test(pass);
    const passed = result === expected;
    console.log(`${passed ? '✅' : '❌'} [${desc}] password: "${pass}" -> ${result} (expected ${expected})`);
    if (!passed) allPassed = false;
});

if (allPassed) {
    console.log('\n✨ All tests passed!');
} else {
    console.log('\n❌ Some tests failed.');
    process.exit(1);
}
