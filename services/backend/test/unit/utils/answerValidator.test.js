const { normalize, validateBilingual } = require('../../../src/utils/answerValidator');

describe('Answer Validator Utilities', () => {
    describe('normalize()', () => {
        // ... (existing tests)
        it('should return empty array for null or undefined input', () => {
            expect(normalize(null)).toEqual([]);
            expect(normalize(undefined)).toEqual([]);
        });
        it('should return the array itself if input is an array (items trimmed/lowercase)', () => {
            expect(normalize([' A ', 'B'])).toEqual(['a', 'b']);
            expect(normalize(['test', 123])).toEqual(['test', '123']);
        });
        it('should handle JSON array string input', () => {
            expect(normalize('["A", "B"]')).toEqual(['a', 'b']);
            expect(normalize("['A', 'B']")).toEqual(["['a', 'b']"]);
        });
        it('should handle comma-separated string input', () => {
            expect(normalize('A, B, C')).toEqual(['a', 'b', 'c']);
            expect(normalize('  one, two  ')).toEqual(['one', 'two']);
        });
        it('should handle simple string input', () => {
            expect(normalize('Simple String')).toEqual(['simple string']);
            expect(normalize('  Trim Me  ')).toEqual(['trim me']);
        });
        it('should fallback to single item array for invalid JSON-like string', () => {
            expect(normalize('[invalid json')).toEqual(['[invalid json']);
        });
        it('should not split by comma if string contains quotes or braces (likely JSON-ish or complex)', () => {
            expect(normalize('{"a":1, "b":2}')).toEqual(['{"a":1, "b":2}']);
            expect(normalize('"quoted, string"')).toEqual(['"quoted, string"']);
        });
        it('should handle number input', () => {
            expect(normalize(123)).toEqual(['123']);
        });
    });

    describe('validateBilingual()', () => {
        // --- Tests WITHOUT bilingual options ---
        describe('Without bilingual options', () => {
            it('should validate exact string matches (case-insensitive)', () => {
                const result = validateBilingual('Answer', 'answer');
                expect(result.isCorrect).toBe(true);
                expect(result.normalizedCorrect).toEqual('answer');
            });

            it('should validate matching arrays', () => {
                const result = validateBilingual(['A', 'B'], ['b', 'a']);
                // The implementation uses `cNorms.every(c => uNorms.includes(c))` and length check.
                // So order shouldn't matter for set equality.
                expect(result.isCorrect).toBe(true);
            });

            it('should fail on partial matches', () => {
                const result = validateBilingual(['A'], ['A', 'B']);
                expect(result.isCorrect).toBe(false);
            });

            it('should fail on extra user answers', () => {
                const result = validateBilingual(['A', 'B', 'C'], ['A', 'B']);
                expect(result.isCorrect).toBe(false);
            });

            it('should fail on complete mismatch', () => {
                const result = validateBilingual('Wrong', 'Right');
                expect(result.isCorrect).toBe(false);
            });
        });

        // --- Tests WITH bilingual options ---
        describe('With bilingual options', () => {
            const options = {
                en: ['Apple', 'Banana', 'Cherry', 'True', 'False'],
                hu: ['Alma', 'Banán', 'Cseresznye', 'Igaz', 'Hamis']
            };

            it('should validate correct English answer against English DB answer', () => {
                const result = validateBilingual('Apple', 'Apple', options);
                expect(result.isCorrect).toBe(true);
                expect(result.normalizedCorrect).toBe('Apple'); // Returns from options.en
            });

            it('should validate correct Hungarian answer against English DB answer', () => {
                // DB has 'Apple', User says 'Alma'. 'Apple' is index 0 in EN. 'Alma' is index 0 in HU. Match!
                const result = validateBilingual('Alma', 'Apple', options);
                expect(result.isCorrect).toBe(true);
                expect(result.normalizedCorrect).toBe('Alma'); // Should return localized correct answer
            });

            it('should validate correct English answer against Hungarian DB answer', () => {
                 // DB has 'Alma', User says 'Apple'.
                 const result = validateBilingual('Apple', 'Alma', options);
                 expect(result.isCorrect).toBe(true);
                 expect(result.normalizedCorrect).toBe('Apple'); // User used EN, so return EN
            });

            it('should validate boolean True/Igaz mapping', () => {
                // "True" in EN is index 3. "Igaz" in HU is index 3.
                // Special logic: if c='igaz' -> idx=indexOf('true').

                // Case 1: DB='True', User='Igaz'
                let result = validateBilingual('Igaz', 'True', options);
                expect(result.isCorrect).toBe(true);
                expect(result.normalizedCorrect).toBe('Igaz');

                // Case 2: DB='Igaz', User='True'
                // Note: The code handles explicit boolean labels if options are English but DB/User has Hungarian.
                // "if (c === 'igaz') idx = enOptsLower.indexOf('true');"
                result = validateBilingual('True', 'Igaz', options);
                expect(result.isCorrect).toBe(true);
                expect(result.normalizedCorrect).toBe('True');
            });

            it('should validate boolean False/Hamis mapping', () => {
                 const result = validateBilingual('Hamis', 'False', options);
                 expect(result.isCorrect).toBe(true);
                 expect(result.normalizedCorrect).toBe('Hamis');
            });

            it('should handle multi-select bilingual validation', () => {
                // Correct: Apple, Banana (indices 0, 1)
                // User: Alma, Banana (indices 0, 1)
                const result = validateBilingual(['Alma', 'Banana'], ['Apple', 'Banana'], options);
                expect(result.isCorrect).toBe(true);
                // Normalized correct should respect user's choice of language if mixed?
                // Code: "const isUserHu = uNorms.some(u => huOptsLower.includes(u));"
                // If ANY user answer is Hungarian, it treats user as HU.
                // So it should return ['Alma', 'Banán'] (from options.hu)
                expect(result.normalizedCorrect).toEqual(['Alma', 'Banán']);
            });

            it('should return English correct answers if user uses English', () => {
                const result = validateBilingual(['Apple', 'Banana'], ['Apple', 'Banana'], options);
                expect(result.isCorrect).toBe(true);
                expect(result.normalizedCorrect).toEqual(['Apple', 'Banana']);
            });

            it('should return Hungarian correct answers if user uses Hungarian', () => {
                const result = validateBilingual(['Alma', 'Banán'], ['Apple', 'Banana'], options);
                expect(result.isCorrect).toBe(true);
                expect(result.normalizedCorrect).toEqual(['Alma', 'Banán']);
            });

             it('should fail if indices do not match', () => {
                // Apple (0) vs Cherry (2)
                const result = validateBilingual('Apple', 'Cherry', options);
                expect(result.isCorrect).toBe(false);
            });

            it('should handle missing options gracefully (fallback to simple validation)', () => {
                 const result = validateBilingual('Apple', 'Apple', {});
                 expect(result.isCorrect).toBe(true);
            });

            it('should fallback to simple validation if options are incomplete (missing en or hu)', () => {
                const partialOptions = { en: ['Apple'] }; // missing hu
                const result = validateBilingual('Apple', 'Apple', partialOptions);
                expect(result.isCorrect).toBe(true);
                // Should behave like simple validation
                expect(result.normalizedCorrect).toBe('apple'); // because simple validation lowercases everything
            });

            it('should handle case insensitivity in bilingual check', () => {
                const result = validateBilingual('ALMA', 'apple', options);
                expect(result.isCorrect).toBe(true);
                expect(result.normalizedCorrect).toBe('Alma'); // From options array
            });

            it('should handle dbCorrectAnswer being in Hungarian while options.en provided', () => {
                 // If DB has 'Alma', and options has 'Apple' at index 0 and 'Alma' at index 0.
                 // The code checks enOptsLower first, then huOptsLower.
                 const result = validateBilingual('Apple', 'Alma', options);
                 expect(result.isCorrect).toBe(true);
            });
        });
    });
});
