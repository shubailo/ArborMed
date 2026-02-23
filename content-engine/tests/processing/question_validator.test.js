const { validateQuestion } = require('../../src/processing/question_validator');

describe('validateQuestion', () => {
    const fileName = 'test_file.json';

    it('should return no issues for a valid question', () => {
        const question = {
            question_text: 'What is the capital of France?',
            correct_answer: 'Paris',
            options: ['London', 'Berlin', 'Paris', 'Madrid']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toEqual([]);
    });

    it('should return issue if question text is missing', () => {
        const question = {
            correct_answer: 'Paris',
            options: ['Paris', 'London']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toContain('Question text missing or too short');
    });

    it('should return issue if question text is too short', () => {
        const question = {
            question_text: 'Hi',
            correct_answer: 'Paris',
            options: ['Paris', 'London']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toContain('Question text missing or too short');
    });

    it('should return issue if correct answer is missing', () => {
        const question = {
            question_text: 'What is the capital of France?',
            options: ['Paris', 'London']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toContain('Correct answer missing');
    });

    it('should return issue if options are missing', () => {
        const question = {
            question_text: 'What is the capital of France?',
            correct_answer: 'Paris'
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toContain('Options missing or insufficient');
    });

    it('should return issue if options are not an array', () => {
        const question = {
            question_text: 'What is the capital of France?',
            correct_answer: 'Paris',
            options: 'Paris, London'
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toContain('Options missing or insufficient');
    });

    it('should return issue if options have less than 2 items', () => {
        const question = {
            question_text: 'What is the capital of France?',
            correct_answer: 'Paris',
            options: ['Paris']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toContain('Options missing or insufficient');
    });

    it('should return issue if correct answer is not in options', () => {
        const question = {
            question_text: 'What is the capital of France?',
            correct_answer: 'Paris',
            options: ['London', 'Berlin', 'Madrid']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues.length).toBeGreaterThan(0);
        expect(issues[0]).toMatch(/Correct answers \[Paris\] not found in options/);
    });

    it('should handle case insensitivity for correct answer check', () => {
        const question = {
            question_text: 'What is the capital of France?',
            correct_answer: 'Paris',
            options: ['paris', 'London']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toEqual([]);
    });

    it('should handle substring match for correct answer check', () => {
        const question = {
            question_text: 'What is the capital of France?',
            correct_answer: 'Paris',
            options: ['City of Paris', 'London']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toEqual([]);
    });

    it('should handle substring match when option is substring of answer', () => {
        const question = {
            question_text: 'What is the capital of France?',
            correct_answer: 'City of Paris',
            options: ['Paris', 'London']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toEqual([]);
    });

    it('should handle multiple correct answers separated by semicolon', () => {
        const question = {
            question_text: 'Select prime numbers',
            correct_answer: '2; 3',
            options: ['2', '3', '4', '6']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toEqual([]);
    });

    it('should return issue if one of multiple correct answers is missing', () => {
        const question = {
            question_text: 'Select prime numbers',
            correct_answer: '2; 5',
            options: ['2', '3', '4', '6']
        };
        const issues = validateQuestion(question, fileName);
        expect(issues.length).toBeGreaterThan(0);
        expect(issues[0]).toMatch(/Correct answers \[5\] not found in options/);
    });

    it('should handle multiple issues', () => {
        const question = {
            question_text: 'Hi',
            correct_answer: 'Paris',
            options: ['London'] // Also insufficient options
        };
        const issues = validateQuestion(question, fileName);
        expect(issues).toContain('Question text missing or too short');
        expect(issues).toContain('Options missing or insufficient');
         // Since options are insufficient, it might skip the correct answer check or behave differently.
         // Looking at code:
         // if (q.options && q.correct_answer) block runs even if options length < 2 check failed above.
         // So it will check for correct answer existence.
         expect(issues.some(i => i.includes('Correct answers [Paris] not found in options'))).toBe(true);
    });
});
