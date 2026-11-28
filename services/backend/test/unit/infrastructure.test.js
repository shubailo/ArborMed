const { isAllowedOrigin } = require('../../src/config/origins');
const { databaseOptions } = require('../../src/config/databaseOptions');

test('limits browser origins to the configured sites and development loopback', () => {
  expect(isAllowedOrigin(undefined)).toBe(true);
  expect(isAllowedOrigin('https://arbor-med.netlify.app')).toBe(true);
  expect(isAllowedOrigin('https://unrelated.netlify.app')).toBe(false);
  expect(isAllowedOrigin('http://localhost:5000', { NODE_ENV: 'development' })).toBe(true);
  expect(isAllowedOrigin('http://localhost:5000', { NODE_ENV: 'production' })).toBe(false);
  expect(isAllowedOrigin('https://custom.test', { ALLOWED_ORIGINS: 'https://custom.test' })).toBe(true);
});

test('production connections always verify the peer, including when a URL contains TLS options', () => {
  const options = databaseOptions({
    DATABASE_URL: 'postgres://localhost/test?sslmode=disable&application_name=arbormed',
    NODE_ENV: 'production', DB_CA_CERT: 'first\\nsecond',
  });
  expect(options.ssl).toEqual({ rejectUnauthorized: true, ca: 'first\nsecond' });
  expect(new URL(options.connectionString).searchParams.has('sslmode')).toBe(false);
  expect(new URL(options.connectionString).searchParams.get('application_name')).toBe('arbormed');
  expect(() => databaseOptions({ NODE_ENV: 'production' })).toThrow('DATABASE_URL');
});

test('TLS opt-out applies only to local development without URL overrides', () => {
  const options = url => databaseOptions({NODE_ENV:'test', DATABASE_URL:url});
  expect(options('postgres://localhost/test').ssl).toBe(false);
  for (const url of ['postgres://localhost/test?host=remote.invalid', 'postgres://localhost/test?ssl=true']) {
    const config = options(url);
    const ConnectionParameters = require('pg/lib/connection-parameters');
    expect(new ConnectionParameters(config).ssl).toEqual({rejectUnauthorized:true});
  }
});

test('malformed connection settings report a configuration error without the supplied URL', () => {
  expect(() => databaseOptions({ DATABASE_URL: 'not-a-database-url' })).toThrow(/^Invalid DATABASE_URL$/);
  expect(() => databaseOptions({ DATABASE_URL: 'https://example.test/db' })).toThrow(/^Invalid DATABASE_URL$/);
  expect(() => databaseOptions({ NODE_ENV: 'production', DATABASE_URL: 'postgres:' })).toThrow(/^Invalid DATABASE_URL$/);
});
