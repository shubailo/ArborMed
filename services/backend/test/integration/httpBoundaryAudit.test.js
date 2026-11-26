const { once } = require('node:events');
const handler = require('../../src/middleware/errorHandler');
jest.mock('express-rate-limit', () => {
  const real = jest.requireActual('express-rate-limit');
  function limit(options) {
    if (options.max !== 1000) return real.rateLimit(options);
    return (req,res,next) => req.path === '/audit-limit-fixture' ? res.sendStatus(429) : next();
  }
  return Object.assign(limit, real, {rateLimit:limit});
});
jest.mock('../../src/config/db', () => ({query:jest.fn()}));
jest.mock('../../src/services/mailService', () => ({}));
const {app} = require('../../server');
let http, base;
beforeAll(async () => {
  http=app.listen(0,'127.0.0.1'); await once(http,'listening');
  base='http://127.0.0.1:'+http.address().port;
});
afterAll(async () => { await new Promise(resolve=>http.close(resolve)); });
test('an allowed web client can read the rate-limit response with the usual headers', async () => {
  const origin='https://arbor-med.netlify.app';
  const response=await fetch(base+'/audit-limit-fixture',{headers:{Origin:origin}});
  expect(response.status).toBe(429);
  expect(response.headers.get('access-control-allow-origin')).toBe(origin);
  expect(response.headers.get('x-content-type-options')).toBe('nosniff');
});
test('access logs keep the route and omit query values', async () => {
  const write=jest.spyOn(process.stdout,'write').mockImplementation(()=>true);
  try {
    await (await fetch(base+'/ping?search=audit-fixture-marker')).text();
    const log=write.mock.calls.map(([line])=>String(line)).join(' ');
    expect(log).toContain('/ping');
    expect(log).not.toContain('audit-fixture-marker');
  } finally { write.mockRestore(); }
});
test('unexpected production failures keep internal detail server-side and query values out of error logs', () => {
  const env=process.env.NODE_ENV; process.env.NODE_ENV='production';
  const log=jest.spyOn(console,'error').mockImplementation(()=>{});
  const res={status:jest.fn().mockReturnThis(),json:jest.fn()};
  try {
    handler(new Error('internal-fixture-detail'),{method:'GET',originalUrl:'/fixture?search=audit-fixture-marker'},res);
    expect(res.status).toHaveBeenCalledWith(500);
    expect(JSON.stringify(res.json.mock.calls)).not.toContain('internal-fixture-detail');
    expect(JSON.stringify(log.mock.calls)).toContain('/fixture');
    expect(JSON.stringify(log.mock.calls)).not.toContain('audit-fixture-marker');
  } finally { log.mockRestore(); process.env.NODE_ENV=env; }
});
