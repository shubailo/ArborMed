const TrueFalseType = require('../../../../src/services/questionTypes/TrueFalseType');

describe('TrueFalseType Unit Tests', () => {
  let tfHandler;

  beforeEach(() => {
    tfHandler = new TrueFalseType();
  });

  describe('prepareForClient', () => {
    it('should provide [{ value: "true", label: "Igaz" }, { value: "false", label: "Hamis" }] options', () => {
      const question = {
        id: 14,
        question_type: 'true_false',
        content: {
          question_text_hu: 'A hipofízis hátulsó lebenye szintetizálja az oxitocint.',
        },
        correct_answer: 'false',
        explanation_hu: 'A hipotalamusz szintetizálja.',
      };

      const prepared = tfHandler.prepareForClient(question);
      expect(prepared.options).toEqual([
        { value: 'true', label: 'Igaz' },
        { value: 'false', label: 'Hamis' },
      ]);
    });
  });

  describe('checkAnswer: Bilingual True/False Evaluation', () => {
    describe('When DB correct_answer is "false" / false', () => {
      const questionEnDbFalse = {
        id: 101,
        question_type: 'true_false',
        correct_answer: 'false',
        content: { question_text: 'Test Q' },
        explanation_en: 'False explanation',
      };

      const questionHuDbFalse = {
        id: 102,
        question_type: 'true_false',
        correct_answer: 'Hamis',
        content: { question_text_hu: 'Teszt kérdés' },
        explanation_hu: 'Hamis magyarázat',
      };

      const questionBoolFalse = {
        id: 103,
        question_type: 'true_false',
        correct_answer: false,
        content: { question_text_hu: 'Teszt kérdés' },
        explanation_hu: 'Hamis magyarázat',
      };

      it('evaluates Hungarian "Hamis" as correct when DB is "false"', () => {
        const res = tfHandler.checkAnswer(questionEnDbFalse, 'Hamis');
        expect(res.correct).toBe(true);
        expect(res.score).toBe(1);
      });

      it('evaluates Hungarian "hamis" (lowercase) as correct when DB is "false"', () => {
        const res = tfHandler.checkAnswer(questionEnDbFalse, 'hamis');
        expect(res.correct).toBe(true);
      });

      it('evaluates English "false" as correct when DB is "false"', () => {
        const res = tfHandler.checkAnswer(questionEnDbFalse, 'false');
        expect(res.correct).toBe(true);
      });

      it('evaluates English "False" as correct when DB is "false"', () => {
        const res = tfHandler.checkAnswer(questionEnDbFalse, 'False');
        expect(res.correct).toBe(true);
      });

      it('evaluates Hungarian "Hamis" as correct when DB is "Hamis"', () => {
        const res = tfHandler.checkAnswer(questionHuDbFalse, 'Hamis');
        expect(res.correct).toBe(true);
        expect(res.correctAnswer).toBe('Hamis');
      });

      it('evaluates English "false" as correct when DB is "Hamis"', () => {
        const res = tfHandler.checkAnswer(questionHuDbFalse, 'false');
        expect(res.correct).toBe(true);
      });

      it('evaluates Hungarian "Hamis" as correct when DB is boolean false', () => {
        const res = tfHandler.checkAnswer(questionBoolFalse, 'Hamis');
        expect(res.correct).toBe(true);
      });

      it('evaluates "0" as false/Hamis', () => {
        const res = tfHandler.checkAnswer(questionEnDbFalse, '0');
        expect(res.correct).toBe(true);
      });

      it('evaluates Hungarian "Igaz" as incorrect when DB is "false"', () => {
        const res = tfHandler.checkAnswer(questionEnDbFalse, 'Igaz');
        expect(res.correct).toBe(false);
        expect(res.score).toBe(0);
        expect(res.correctAnswer).toBe('Hamis');
      });

      it('evaluates English "True" as incorrect when DB is "false"', () => {
        const res = tfHandler.checkAnswer(questionEnDbFalse, 'True');
        expect(res.correct).toBe(false);
      });
    });

    describe('When DB correct_answer is "true" / true', () => {
      const questionEnDbTrue = {
        id: 201,
        question_type: 'true_false',
        correct_answer: 'true',
        content: { question_text: 'Test Q' },
        explanation_en: 'True explanation',
      };

      const questionHuDbTrue = {
        id: 202,
        question_type: 'true_false',
        correct_answer: 'Igaz',
        content: { question_text_hu: 'Teszt kérdés' },
        explanation_hu: 'Igaz magyarázat',
      };

      const questionBoolTrue = {
        id: 203,
        question_type: 'true_false',
        correct_answer: true,
        content: { question_text_hu: 'Teszt kérdés' },
        explanation_hu: 'Igaz magyarázat',
      };

      it('evaluates Hungarian "Igaz" as correct when DB is "true"', () => {
        const res = tfHandler.checkAnswer(questionEnDbTrue, 'Igaz');
        expect(res.correct).toBe(true);
        expect(res.score).toBe(1);
      });

      it('evaluates Hungarian "igaz" (lowercase) as correct when DB is "true"', () => {
        const res = tfHandler.checkAnswer(questionEnDbTrue, 'igaz');
        expect(res.correct).toBe(true);
      });

      it('evaluates English "true" as correct when DB is "true"', () => {
        const res = tfHandler.checkAnswer(questionEnDbTrue, 'true');
        expect(res.correct).toBe(true);
      });

      it('evaluates English "True" as correct when DB is "true"', () => {
        const res = tfHandler.checkAnswer(questionEnDbTrue, 'True');
        expect(res.correct).toBe(true);
      });

      it('evaluates Hungarian "Igaz" as correct when DB is "Igaz"', () => {
        const res = tfHandler.checkAnswer(questionHuDbTrue, 'Igaz');
        expect(res.correct).toBe(true);
        expect(res.correctAnswer).toBe('Igaz');
      });

      it('evaluates English "true" as correct when DB is "Igaz"', () => {
        const res = tfHandler.checkAnswer(questionHuDbTrue, 'true');
        expect(res.correct).toBe(true);
      });

      it('evaluates Hungarian "Igaz" as correct when DB is boolean true', () => {
        const res = tfHandler.checkAnswer(questionBoolTrue, 'Igaz');
        expect(res.correct).toBe(true);
      });

      it('evaluates "1" as true/Igaz', () => {
        const res = tfHandler.checkAnswer(questionEnDbTrue, '1');
        expect(res.correct).toBe(true);
      });

      it('evaluates Hungarian "Hamis" as incorrect when DB is "true"', () => {
        const res = tfHandler.checkAnswer(questionEnDbTrue, 'Hamis');
        expect(res.correct).toBe(false);
        expect(res.score).toBe(0);
        expect(res.correctAnswer).toBe('Igaz');
      });

      it('evaluates English "False" as incorrect when DB is "true"', () => {
        const res = tfHandler.checkAnswer(questionEnDbTrue, 'False');
        expect(res.correct).toBe(false);
      });
    });

    describe('Edge Cases and Graceful Degradation', () => {
      const question = {
        id: 301,
        question_type: 'true_false',
        correct_answer: 'false',
        content: { question_text_hu: 'Teszt kérdés' },
        explanation_hu: 'Magyarázat',
      };

      it('handles null answer without throwing', () => {
        const res = tfHandler.checkAnswer(question, null);
        expect(res.correct).toBe(false);
        expect(res.correctAnswer).toBe('Hamis');
      });

      it('handles undefined answer without throwing', () => {
        const res = tfHandler.checkAnswer(question, undefined);
        expect(res.correct).toBe(false);
      });

      it('handles non-boolean arbitrary string without throwing', () => {
        const res = tfHandler.checkAnswer(question, 'Random gibberish');
        expect(res.correct).toBe(false);
      });

      it('handles whitespace padded inputs like "  Hamis  "', () => {
        const res = tfHandler.checkAnswer(question, '  Hamis  ');
        expect(res.correct).toBe(true);
      });
    });
  });
});
