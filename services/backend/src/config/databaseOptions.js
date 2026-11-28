function databaseOptions(env) {
  if (env.NODE_ENV === 'production' && !env.DATABASE_URL) {
    throw new Error('DATABASE_URL is required in production');
  }
  // A thrown URL constructor error can include the entire credentials string.
  if (env.DATABASE_URL && !URL.canParse(env.DATABASE_URL)) throw new Error('Invalid DATABASE_URL');
  const url = env.DATABASE_URL ? new URL(env.DATABASE_URL) : null;
  if (url && !['postgres:', 'postgresql:'].includes(url.protocol)) throw new Error('Invalid DATABASE_URL');
  if (env.NODE_ENV === 'production' && !url.hostname && !url.searchParams.get('host')) {
    throw new Error('Invalid DATABASE_URL');
  }
  const local = url && ['127.0.0.1', 'localhost', '[::1]'].includes(url.hostname);
  const sslOptions = ['ssl', 'sslmode', 'sslrootcert', 'sslcert', 'sslkey', 'uselibpqcompat'];
  if (local && ['test', 'development'].includes(env.NODE_ENV) &&
      !url.searchParams.has('host') && !sslOptions.some(key => url.searchParams.has(key))) {
    return { connectionString: env.DATABASE_URL, ssl: false };
  }
  // pg parses these URL parameters after the Pool options and can replace ssl entirely.
  for (const key of sslOptions) {
    url?.searchParams.delete(key);
  }
  const ssl = { rejectUnauthorized: true };
  if (env.DB_CA_CERT && env.DB_CA_CERT !== 'your_ca_certificate_if_applicable') {
    ssl.ca = env.DB_CA_CERT.replace(/\\n/g, '\n');
  }
  return { connectionString: url?.toString(), ssl };
}

module.exports = { databaseOptions };
