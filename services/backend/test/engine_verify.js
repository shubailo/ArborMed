const analyticsEngine = require('../src/services/analyticsEngine');

console.log('--- SM-2 LOGIC VERIFICATION ---');

// Test 1: Quality 5 (Perfect)
const result5 = analyticsEngine.calculateSM2(5, 2.5, 0, 0);
console.log('Quality 5, first time:', result5);
// Expect: interval 1, repetitions 1, EF increases slightly

// Test 2: Quality 3 (Passable)
const result3 = analyticsEngine.calculateSM2(3, 2.5, 1, 1);
console.log('Quality 3, second time:', result3);
// Expect: interval 6, repetitions 2, EF decreases slightly

// Test 3: Quality 2 (Fail)
const result2 = analyticsEngine.calculateSM2(2, 2.5, 6, 2);
console.log('Quality 2 (Fail):', result2);
// Expect: interval 1, repetitions 0, EF remains or stays above 1.3

console.log('\n--- RETENTION MODIFIER VERIFICATION ---');
const highRetention = [true, true, true, true, true, true, true, true, true, true]; // 100%
console.log('High Retention (>90%):', analyticsEngine.calculateRetentionModifier(highRetention));
// Expect: 1.15

const lowRetention = [false, false, false, true, true, true, false, false, false, false]; // 30%
console.log('Low Retention (<85%):', analyticsEngine.calculateRetentionModifier(lowRetention));
// Expect: 0.85

console.log('\n--- WEIGHTED MASTERY FORMULA CHECK ---');
// Mocking the behavior inside adaptiveEngine.js
function calculateMockMastery(m_l12, m_l34, t_l12, t_l34) {
    const weightedNumerator = (m_l12 * 1.0) + (m_l34 * 2.0);
    const weightedDenominator = (t_l12 * 1.0) + (t_l34 * 2.0);
    return Math.min(100, Math.round((weightedNumerator / weightedDenominator) * 100));
}

console.log('Mastery: 10/10 L12, 0/10 L34:', calculateMockMastery(10, 0, 10, 10), '%');
// Numerator: 10*1 + 0*2 = 10
// Denominator: 10*1 + 10*2 = 10 + 20 = 30
// 10/30 = 33%

console.log('Mastery: 10/10 L12, 5/10 L34:', calculateMockMastery(10, 5, 10, 10), '%');
// Numerator: 10*1 + 5*2 = 10 + 10 = 20
// Denominator: 30
// 20/30 = 67%

console.log('Mastery: 10/10 L12, 10/10 L34:', calculateMockMastery(10, 10, 10, 10), '%');
// Numerator: 10*1 + 10*2 = 10 + 20 = 30
// Denominator: 30
// 30/30 = 100%

process.exit(0);
