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
  expect(databaseOptions({ NODE_ENV: 'production' }).ssl.rejectUnauthorized).toBe(true);
});
