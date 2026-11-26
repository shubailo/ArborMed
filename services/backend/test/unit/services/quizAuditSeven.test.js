const registry = require('../../../src/services/questionTypes/registry');
const gradeable = require('../../../src/services/questionTypes/gradeableQuestion');
const engine = require('../../../src/services/analyticsEngine');
const db = require('../../../src/config/db');
const stats = require('../../../src/controllers/statsController');

jest.mock('../../../src/config/db', () => ({ query: jest.fn() }));

const type = registry.getType('single_choice');
const question = {
    question_type: 'single_choice',
    content: { question_text: { en: 'Select', hu: 'Válassz' },
        options: { en: ['Igaz', 'True'], hu: ['Első', 'Második'] } },
    correct_answer: 'True',
};

test('bilingual authoring, local presentation and authoritative scoring agree on option identity', () => {
    expect(type.validate(question)).toEqual({ valid: true, errors: [] });
    const prepared = registry.prepareForClient(gradeable(question));
    const [wrong, right] = prepared.choice_options;
    for (const answer of [right.id, right.en, right.hu]) {
        expect(registry.checkAnswer(question, answer).correct).toBe(true);
    }
    expect(registry.checkAnswer(question, wrong.id).correct).toBe(false);
    expect(type.validate({ content: { question_text: 3, options: {} }, correct_answer: 'a' }).valid).toBe(false);
    const options = [{id:'a', en:'First'}, {id:'b', en:'Second'}];
    const authored = {...question, content:{question_text:'Pick', options}, correct_answer:'b'};
    const stable = type.prepareForClient(authored).choice_options[1].id;
    options[0].en = stable;
    expect(type.checkAnswer(authored, stable).correct).toBe(true);
    const schema = registry.getAllTypes().find(t => t.id === 'single_choice').schema;
    expect(schema.properties.options.anyOf.some(shape => shape.type === 'object')).toBe(true);
});

test('duplicate stable IDs cannot enter practice, including two differently labelled author options', () => {
    const options = [{id: 'x', en: 'first'}, {id: 'x', en: 'second'}];
    const bad = { ...question, content: {question_text: 'Choose', options}, correct_answer: 'first' };
    expect(gradeable(bad)).toBeNull();
    expect(type.checkAnswer(bad, 'second').correct).toBe(false);
    expect(type.validate(bad).valid).toBe(false);
    expect(gradeable({ ...bad, content: {...bad.content, options: [options[0], {id:'y', en:'second'}]} })).not.toBeNull();
});

test('legacy review state yields a positive interval and an int4 repetition counter', () => {
    expect(engine.calculateSM2(4, '2.5', 0, 3)).toEqual({interval:1, repetitions:4, easinessFactor:2.5});
    expect(engine.calculateSM2(4, 2.5, 6, 2147483647)).toMatchObject({interval:15, repetitions:2147483647});
    expect(engine.calculateSM2(2, 2.5, 6, 3)).toMatchObject({interval:1, repetitions:0});
});

test('future study dates and invalid stability cannot produce retention above 100 or negative readiness', async () => {
    expect(engine.calculateRetention(-2, 1)).toBe(100);
    expect(engine.calculateRetention(1, -1)).toBe(37);
    expect(engine.calculateReadiness(-20, 0)).toBe(0);
    expect(engine.calculateReadiness(200, 0)).toBe(60);
    const rows = [{slug:'renal', name_en:'Renal', last_studied_at:new Date(Date.now()+86400000), stability:1, mastery_score:50},
        {slug:'heart', name_en:'Heart', last_studied_at:null, stability:1, mastery_score:0}];
    db.query.mockResolvedValue({rows});
    const res = {json:jest.fn()};
    await stats.getReadiness({user:{id:7}},res,err => {throw err;});
    expect(res.json.mock.calls[0][0].breakdown).toContainEqual({topic:'Renal', slug:'renal', score:70, metrics:{mastery:50, retention:100}});
    await stats.getSmartReview({user:{id:7}},res,err => {throw err;});
    expect(res.json.mock.calls[1][0].recommendations[0]).toMatchObject({slug:'heart', daysSince:null, retention:0});
});
