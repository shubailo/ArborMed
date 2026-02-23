const crypto = require('crypto');

function secureCompare(input, storedHash) {
    const hashedInput = crypto.createHash('sha256').update(input).digest('hex');

    // This is the logic we implemented
    const hashedInputBuffer = Buffer.from(hashedInput, 'hex');
    const storedHashBuffer = Buffer.from(storedHash, 'hex');

    if (hashedInputBuffer.length !== storedHashBuffer.length) {
        return false;
    }

    return crypto.timingSafeEqual(hashedInputBuffer, storedHashBuffer);
}

// Test cases
const refreshToken = 'some-random-token-123';
const correctHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
const wrongHash = crypto.createHash('sha256').update('wrong-token').digest('hex');
const shortHash = 'abc';

console.log('Testing secureCompare...');

const matchResult = secureCompare(refreshToken, correctHash);
console.log(`Matching token: ${matchResult === true ? 'PASS' : 'FAIL'}`);

const nonMatchResult = secureCompare(refreshToken, wrongHash);
console.log(`Non-matching token: ${nonMatchResult === false ? 'PASS' : 'FAIL'}`);

const shortMatchResult = secureCompare(refreshToken, shortHash);
console.log(`Different length hash: ${shortMatchResult === false ? 'PASS' : 'FAIL'}`);

if (matchResult === true && nonMatchResult === false && shortMatchResult === false) {
    console.log('All tests passed!');
    process.exit(0);
} else {
    console.error('Some tests failed!');
    process.exit(1);
}
