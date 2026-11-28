jest.mock('socket.io', () => jest.fn());
jest.mock('../../../src/utils/accessToken', () => ({ verifyAccessToken: jest.fn() }));
jest.mock('../../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../../src/utils/logger', () => ({ info: jest.fn(), warn: jest.fn(), error: jest.fn() }));
jest.mock('../../../src/services/walletService', () => ({
  ...jest.requireActual('../../../src/services/walletService'),
  reserve: jest.fn(), start: jest.fn(), cancel: jest.fn(), settlePayouts: jest.fn(), receipt: jest.fn(), recoverExpired: jest.fn()
}));
const service = require('../../../src/services/socketService');
const db = require('../../../src/config/db');
const wallet = require('../../../src/services/walletService');
const sample = { id: 77, question_text_en: 'Q', options: {en:['A','B'], hu:['X','Y']},
  question_type: 'single_choice', correct_answer: '["A"]', explanation_en: 'private',
  content: { secret: 'private' } };
let io, connect, auth;
function socket(id, userId) {
  const events = {};
  const s = {id, userId, accessToken: String(userId), on: (name, fn) => {events[name] = fn;}, emit: jest.fn(), events};
  connect(s);
  return s;
}
beforeEach(() => {
  jest.useFakeTimers();
  jest.clearAllMocks();
  require('../../../src/utils/accessToken').verifyAccessToken.mockImplementation(token => ({ id: Number(token) || 1 }));
  io = {on: (_event, fn) => {connect=fn;}, use: fn => {auth=fn;}, to: jest.fn().mockReturnThis(), emit: jest.fn()};
  require('socket.io').mockReturnValue(io);
  wallet.reserve.mockResolvedValue(true);
  wallet.start.mockResolvedValue(true);
  wallet.receipt.mockResolvedValue(undefined);
  wallet.cancel.mockResolvedValue(true);
  wallet.settlePayouts.mockImplementation(async (_matchId,outcome,winner) =>
    wallet.reserve.mock.calls.map(([,user_id,amount]) => ({
      user_id, payout: outcome === 'draw' ? amount : user_id === winner ? 2*amount : 0
    })));
  wallet.recoverExpired.mockResolvedValue(undefined);
  db.query.mockResolvedValue({rows:[sample]});
  service.initializeSocket({});
});
afterEach(() => {service._clearAllTimers(); jest.useRealTimers();});
it('authenticates the socket against the current verified session', async () => {
  const s = {handshake: {auth: {token: 'token'}, headers: {}}};
  db.query.mockResolvedValueOnce({rows: [{id: 1}]});
  const next = jest.fn();
  await auth(s, next);
  expect(db.query).toHaveBeenCalledWith(expect.stringContaining('is_email_verified IS NOT FALSE'), [1, null]);
  expect(s.userId).toBe(1);
  expect(next).toHaveBeenCalledWith();
});
it('denies the handshake for an unverified account or an obsolete session', async () => {
  const s = {handshake: {auth: {token: 'old'}, headers: {}}};
  db.query.mockResolvedValueOnce({rows: []});
  const next = jest.fn();
  await auth(s, next);
  expect(next).toHaveBeenCalledWith(expect.any(Error));
  expect(s.userId).toBeUndefined();
});
it('refuses malformed and unsupported wagers before debiting', async () => {
  const s = socket('s', 1);
  for(const data of [null, {}, {wager:-1}, {wager:'5'}]) await s.events.join_queue(data);
  expect(wallet.reserve).not.toHaveBeenCalled();
});
it('blocks a second socket for the same account, including an in-flight join', async () => {
  const a = socket('a',1), b = socket('b',1);
  await Promise.all([a.events.join_queue({wager:10}), b.events.join_queue({wager:10})]);
  expect(wallet.reserve).toHaveBeenCalledTimes(1);
  expect(wallet.reserve).toHaveBeenCalledWith(expect.any(String),1,10,{id:1});
  expect(wallet.start).not.toHaveBeenCalled();
  await Promise.all([a.events.leave_queue(), a.events.disconnect()]);
  expect(wallet.cancel).toHaveBeenCalledTimes(1);
});
it('cancels a reservation if the socket leaves during funding', async () => {
  let fund;
  wallet.reserve.mockImplementationOnce(() => new Promise(resolve => {fund=resolve;}));
  const s=socket('s',1);
  const joining=s.events.join_queue({wager:5});
  await s.events.disconnect(); fund(true); await joining;
  expect(wallet.cancel).toHaveBeenCalledTimes(1);
  expect(s.emit).not.toHaveBeenCalledWith('queue_joined', expect.anything());
});
it('exposes only presentation data, grades a choice once, and settles once', async () => {
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  const match=io.emit.mock.calls.find(([event])=>event==='match_found')[1];
  const q=match.questions[0];
  expect(q).toEqual({id:expect.any(Number), q:'Q', options:['A','B'], hu:{q:'Q',options:['X','Y']}});
  await b.events.submit_answer({matchId:match.matchId, questionId:q.id, answer:'A'});
  await b.events.submit_answer({matchId:match.matchId, questionId:String(q.id), answer:'A'});
  expect(io.emit).toHaveBeenLastCalledWith('score_update',{matchId:match.matchId,p1:1,p2:0});
  await jest.advanceTimersByTimeAsync(5000);
  expect(io.emit).toHaveBeenCalledWith('time_sync',{matchId:match.matchId,time:55});
  await Promise.all([a.events.disconnect(),b.events.disconnect()]);
  expect(wallet.settlePayouts).toHaveBeenCalledTimes(1);
});
it('refunds both players if no playable questions are available', async () => {
  db.query.mockResolvedValueOnce({rows:[]});
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  expect(wallet.cancel).toHaveBeenCalledTimes(2); expect(wallet.start).not.toHaveBeenCalled();
});

it('rejects answers from a revoked session on an already-open match socket', async () => {
  const a = socket('a', 1), b = socket('b', 2);
  a.disconnect = jest.fn();
  require('../../../src/utils/accessToken').verifyAccessToken.mockReturnValueOnce({id:1, sessionId:4});
  await a.events.join_queue({wager:5});
  await b.events.join_queue({wager:5});
  const match = io.emit.mock.calls.find(([event]) => event === 'match_found')[1];
  db.query.mockResolvedValueOnce({rows:[]});
  const answer = {matchId:match.matchId, questionId:match.questions[0].id, answer:'A'};
  await Promise.all([a.events.submit_answer(answer), a.events.submit_answer(answer)]);
  expect(db.query).toHaveBeenLastCalledWith(expect.stringContaining('FROM refresh_tokens'), [1, null, 4]);
  expect(a.disconnect).toHaveBeenCalledWith(true);
  expect(io.emit).not.toHaveBeenCalledWith('score_update', expect.anything());
});

it('requires an unexpired same-account credential before funding another wager', async () => {
  const player = socket('a', 1);
  require('../../../src/utils/accessToken').verifyAccessToken.mockImplementationOnce(() => { throw Error('Expired'); });
  await player.events.join_queue({wager:5});
  await player.events.join_queue({wager:5, token:'2'});
  expect(wallet.reserve).not.toHaveBeenCalled();
  await player.events.join_queue({wager:5, token:'1'});
  expect(wallet.reserve).toHaveBeenCalledTimes(1);
});

it('uses the score if a disconnect is observed after the deadline', async () => {
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  const match=io.emit.mock.calls.find(([event])=>event==='match_found')[1];
  await a.events.submit_answer({matchId:match.matchId,questionId:match.questions[0].id,answer:'A'});
  jest.setSystemTime(Date.now() + 61000);
  await a.events.disconnect();
  expect(wallet.settlePayouts).toHaveBeenCalledWith(match.matchId, 'win', 1);
});

it('refunds the original holds even when match activation committed before its acknowledgement failed', async () => {
  wallet.start.mockRejectedValueOnce(new Error('Connection closed after COMMIT'));
  const a = socket('a',1), b = socket('b',2);
  await a.events.join_queue({wager:10});
  await b.events.join_queue({wager:10});
  const [matchId, holds] = wallet.start.mock.calls[0];
  for (const hold of holds) expect(wallet.cancel).toHaveBeenCalledWith(hold, matchId);
  expect(io.emit).not.toHaveBeenCalledWith('match_found', expect.anything());
});

it('reconciles a debit whose acknowledgement failed and acknowledges a repeated leave', async () => {
  wallet.reserve.mockRejectedValueOnce(new Error('Connection closed after COMMIT'));
  const a = socket('a',1);
  await a.events.join_queue({wager:10});
  expect(wallet.cancel).toHaveBeenCalledWith(wallet.reserve.mock.calls[0][0], null);
  await a.events.leave_queue();
  expect(a.emit).toHaveBeenLastCalledWith('queue_left', {refundedWager:0});
  expect(wallet.cancel).toHaveBeenCalledTimes(1);
});

it('delivers confirmed payouts after a settlement acknowledgement is lost', async () => {
  wallet.settlePayouts.mockRejectedValueOnce(new Error('Reply lost')).mockResolvedValueOnce([]);
  wallet.receipt.mockImplementation(async (_id, user) => ({wager:5,payout:user===2 ? 10 : 0}));
  const a = socket('a',1), b = socket('b',2);
  await a.events.join_queue({wager:5});
  await b.events.join_queue({wager:5});
  await a.events.disconnect();
  await jest.advanceTimersByTimeAsync(5000);
  const results = io.emit.mock.calls.filter(([event]) => event==='game_over').map(([,data])=>data);
  expect(results.map(row => row.potWon).sort((a,b)=>a-b)).toEqual([0,10]);
  expect(results.every(row => row.winner==='p1')).toBe(true);
  expect(wallet.settlePayouts).toHaveBeenCalledTimes(2);
});

it('returns only the reconnecting account’s own persisted receipt, including a pending settlement', async () => {
  const matchId = '52732beb-42a8-4c9d-a2b2-3a184ac29173';
  const reconnected = socket('replacement',1);
  wallet.receipt.mockResolvedValueOnce({wager:25,payout:null}).mockResolvedValueOnce({wager:25,payout:50});
  await reconnected.events.duel_result_request({matchId, token:'2'});
  expect(wallet.receipt).not.toHaveBeenCalled();
  await reconnected.events.duel_result_request({matchId});
  expect(reconnected.emit).toHaveBeenLastCalledWith('duel_result',{matchId,status:'pending',wager:25,potWon:null});
  await reconnected.events.duel_result_request({matchId});
  expect(reconnected.emit).toHaveBeenLastCalledWith('duel_result',{matchId,status:'closed',wager:25,potWon:50});
  expect(wallet.receipt).toHaveBeenLastCalledWith(matchId,1,{id:1});
  expect(wallet.reserve).not.toHaveBeenCalled();
});

it('waits for the recovery refund if an expired match has not yet closed', async () => {
  wallet.settlePayouts.mockResolvedValue([]);
  wallet.receipt.mockResolvedValue({wager:5,payout:null});
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  await a.events.disconnect();
  expect(io.emit.mock.calls.some(([event])=>event==='game_over')).toBe(false);
  wallet.receipt.mockResolvedValue({wager:5,payout:5});
  await jest.advanceTimersByTimeAsync(5000);
  for (const player of [a,b]) expect(player.emit).toHaveBeenCalledWith('game_over',
    expect.objectContaining({refunded:true,potWon:5}));
});

it('runs one recovery query at a time while the database is slow', async () => {
  await Promise.resolve();
  let finish;
  wallet.recoverExpired.mockImplementationOnce(() => new Promise(resolve => {finish=resolve;}));
  await jest.advanceTimersByTimeAsync(90000);
  expect(wallet.recoverExpired).toHaveBeenCalledTimes(2); // startup + one pending sweep
  finish();
  await jest.advanceTimersByTimeAsync(30000);
  expect(wallet.recoverExpired).toHaveBeenCalledTimes(3);
});

it('separates a temporary account-store outage from rejected credentials', async () => {
  const s = {handshake:{auth:{token:'1'},headers:{}}};
  db.query.mockRejectedValueOnce(new Error('fixture database unavailable'));
  const next = jest.fn();
  await auth(s, next);
  expect(next.mock.calls[0][0]).toMatchObject({data:{code:'SERVICE_UNAVAILABLE'}});
  expect(s.userId).toBeUndefined();
  expect(require('../../../src/utils/logger').error).toHaveBeenCalled();
});

it('does not advertise an inferred payout for a participant without a durable receipt', async () => {
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  wallet.settlePayouts.mockResolvedValue([{user_id:1,payout:0}]);
  wallet.receipt.mockImplementation(async (_id,user) => user===1 ? {wager:5,payout:0} : undefined);
  await a.events.disconnect();
  const wins = io.emit.mock.calls.filter(([event,data])=>event==='game_over' && data.isWinner);
  expect(wins).toHaveLength(0);
  expect(b.emit).toHaveBeenCalledWith('error', expect.anything());
});

it('ships translated text and labels with the same ordering as canonical submissions', async () => {
  db.query.mockResolvedValueOnce({rows:[{...sample, question_text_hu:'Magyar kérdés'}]});
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  const match=io.emit.mock.calls.find(([event])=>event==='match_found')[1];
  const question=match.questions[0];
  expect(question.hu).toEqual({q:'Magyar kérdés',options:['X','Y']});
  expect(question.options).toEqual(['A','B']);
  await b.events.submit_answer({matchId:match.matchId,questionId:question.id,answer:question.options[0]});
  expect(io.emit).toHaveBeenLastCalledWith('score_update',{matchId:match.matchId,p1:1,p2:0});
});

it('normalizes a question once, including when its stored answer is a serialized single value', async () => {
  const labels = Array.from({length:32}, (_,i) => 'Choice ' + i);
  let reads = 0;
  const question = {...sample, correct_answer:JSON.stringify([labels[25]]),
    get options() { reads++; return { en:labels }; }};
  db.query.mockResolvedValueOnce({rows:[question]});
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  const match=io.emit.mock.calls.find(([event])=>event==='match_found')[1];
  await a.events.submit_answer({matchId:match.matchId,questionId:1,answer:labels[25]});
  expect(io.emit).toHaveBeenLastCalledWith('score_update',{matchId:match.matchId,p1:0,p2:1});
  expect(reads).toBe(1);
});

it('keeps the canonical choices distinct when translated labels collide', async () => {
  db.query.mockResolvedValueOnce({rows:[{...sample, options:{en:['A','B'],hu:['X','X']}}]});
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  const match=io.emit.mock.calls.find(([event])=>event==='match_found')[1];
  expect(match.questions[0].hu.options).toEqual(['A','B']);
});

it('serves the same recoverable answer key and bilingual content prompt as practice', async () => {
  const row = {...sample, question_text_en:' ', question_text_hu:null,
    content:{question_text:{en:'Which cause?',hu:'Mi az oka?'}},
    options:{en:['A, B','C'],hu:['A és B','C']}, correct_answer:'["A","B"]'};
  const gradeable = require('../../../src/services/questionTypes/gradeableQuestion')(row);
  const registry = require('../../../src/services/questionTypes/registry');
  expect(registry.checkAnswer(gradeable, 'A, B').correct).toBe(true);
  db.query.mockResolvedValueOnce({rows:[row]});
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  const match=io.emit.mock.calls.find(([event])=>event==='match_found')?.[1];
  expect(match?.questions).toEqual([{id:1,q:'Which cause?',options:['A, B','C'],
    hu:{q:'Mi az oka?',options:['A és B','C']}}]);
  await a.events.submit_answer({matchId:match.matchId,questionId:1,answer:'A, B'});
  await b.events.submit_answer({matchId:match.matchId,questionId:1,answer:'C'});
  expect(io.emit).toHaveBeenLastCalledWith('score_update',expect.objectContaining({p1:0,p2:1}));
});

it('skips a row with duplicate identities even if only the distractors collide', async () => {
  const ambiguous = {...sample, options:[{id:'x',en:'A'},{id:'x',en:'B'},{id:'y',en:'C'}], correct_answer:'C'};
  expect(require('../../../src/services/questionTypes/gradeableQuestion')(ambiguous)).toBeNull();
  db.query.mockResolvedValueOnce({rows:[ambiguous,sample]});
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  const match=io.emit.mock.calls.find(([event])=>event==='match_found')[1];
  expect(match.questions).toHaveLength(1);
  expect(match.questions[0].options).toEqual(['A','B']);
});

it('ignores a structured question id before recording an answer', async () => {
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  const match=io.emit.mock.calls.find(([event])=>event==='match_found')[1];
  a.events.submit_answer({matchId:match.matchId,questionId:[1],answer:'B'});
  expect(io.emit.mock.calls.some(([event])=>event==='score_update')).toBe(false);
  await a.events.submit_answer({matchId:match.matchId,questionId:'1',answer:'A'});
  expect(io.emit).toHaveBeenLastCalledWith('score_update',expect.objectContaining({p1:0,p2:1}));
});
