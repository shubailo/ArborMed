jest.mock('socket.io', () => jest.fn());
jest.mock('jsonwebtoken', () => ({ verify: jest.fn(() => ({ id: 1 })) }));
jest.mock('../../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../../src/utils/logger', () => ({ info: jest.fn(), warn: jest.fn(), error: jest.fn() }));
jest.mock('../../../src/services/walletService', () => ({
  ...jest.requireActual('../../../src/services/walletService'),
  reserve: jest.fn(), start: jest.fn(), cancel: jest.fn(), settle: jest.fn(), recoverExpired: jest.fn()
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
  require('jsonwebtoken').verify.mockImplementation(token => ({ id: Number(token) || 1 }));
  io = {on: (_event, fn) => {connect=fn;}, use: fn => {auth=fn;}, to: jest.fn().mockReturnThis(), emit: jest.fn()};
  require('socket.io').mockReturnValue(io);
  wallet.reserve.mockResolvedValue(true);
  wallet.start.mockResolvedValue(true);
  wallet.cancel.mockResolvedValue(true);
  wallet.settle.mockResolvedValue(true);
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
  expect(q).toEqual({id:expect.any(Number), q:'Q', options:['A','B']});
  await b.events.submit_answer({matchId:match.matchId, questionId:q.id, answer:'A'});
  await b.events.submit_answer({matchId:match.matchId, questionId:String(q.id), answer:'A'});
  expect(io.emit).toHaveBeenLastCalledWith('score_update',{p1:1,p2:0});
  await Promise.all([a.events.disconnect(),b.events.disconnect()]);
  expect(wallet.settle).toHaveBeenCalledTimes(1);
});
it('refunds both players if no playable questions are available', async () => {
  db.query.mockResolvedValueOnce({rows:[]});
  const a=socket('a',1), b=socket('b',2);
  await a.events.join_queue({wager:5}); await b.events.join_queue({wager:5});
  expect(wallet.cancel).toHaveBeenCalledTimes(2); expect(wallet.start).not.toHaveBeenCalled();
});

it('requires an unexpired same-account credential before funding another wager', async () => {
  const player = socket('a', 1);
  require('jsonwebtoken').verify.mockImplementationOnce(() => { throw Error('Expired'); });
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
  expect(wallet.settle).toHaveBeenCalledWith(match.matchId, 'win', 1);
});
