const QuestionType = require('./QuestionType');
const { scalarAnswer } = require('./storedAnswer');
const { schema, hasPresentation } = require('./relationSchema');

const options = [
  {value:'A', en:'Both statements are true, and there is a causal link', hu:'Mindkét állítás igaz, és van köztük ok-okozati összefüggés'},
  {value:'B', en:'Both statements are true, but there is no causal link', hu:'Mindkét állítás igaz, de nincs köztük összefüggés'},
  {value:'C', en:'Only the first statement is true', hu:'Csak az 1. állítás igaz'},
  {value:'D', en:'Only the second statement is true', hu:'Csak a 2. állítás igaz'},
  {value:'E', en:'Neither statement is true', hu:'Egyik állítás sem igaz'},
];

function answerCode(value) {
  if (typeof value !== 'string') return null;
  const code = value.trim().toUpperCase();
  return /^[A-E]$/.test(code) ? code : null;
}

class RelationAnalysisType extends QuestionType {
  constructor() {
    super('relation_analysis', 'Relation Analysis', 'Analyze the relationship between two medical statements');
  }

  get shouldShuffleOptions() {
    return false;
  }

  validate(question) {
    const errors = [];
    if (!hasPresentation(question)) errors.push('Provide both statements, or a full question prompt without a partial pair.');
    if (!answerCode(scalarAnswer(question?.correct_answer))) errors.push('correct_answer must contain one code from A to E.');
    return {valid:errors.length === 0, errors};
  }

  solutionFor(question) {
    return hasPresentation(question) ? answerCode(scalarAnswer(question.correct_answer)) : null;
  }

  checkAnswer(question, userAnswer) {
    const correctAnswer = this.solutionFor(question);
    const correct = correctAnswer !== null && answerCode(userAnswer) === correctAnswer;
    const expected = options.find(option => option.value === correctAnswer);
    return {
      correct, correctAnswer, score:correct ? 1 : 0,
      feedback:correct ? 'Helyes!' : expected
        ? 'Helytelen. A helyes válasz: ' + correctAnswer + ' (' + expected.hu + ')'
        : 'A kérdés nem értékelhető.',
    };
  }

  getSchema() {
    return schema;
  }

  prepareForClient(question) {
    return {
      ...super.prepareForClient(question),
      correct_answer:this.solutionFor(question),
      options:options.map(option => ({...option, label:option.hu})),
    };
  }

  prepareForAdmin(question) {
    return {
      ...super.prepareForAdmin(question),
      options:options.map(option => ({...option, label:option.value + ' (' + option.en + ')'})),
    };
  }
}

module.exports = RelationAnalysisType;
