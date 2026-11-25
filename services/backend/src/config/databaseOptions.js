function databaseOptions(env) {
  const url = env.DATABASE_URL ? new URL(env.DATABASE_URL) : null;
  const local = url && ['127.0.0.1', 'localhost', '[::1]'].includes(url.hostname);
  if (local && ['test', 'development'].includes(env.NODE_ENV) && !url.searchParams.has('sslmode')) {
    return { connectionString: env.DATABASE_URL, ssl: false };
  }
  // pg parses these URL parameters after the Pool options and can replace ssl entirely.
  for (const key of ['ssl', 'sslmode', 'sslrootcert', 'sslcert', 'sslkey', 'uselibpqcompat']) {
    url?.searchParams.delete(key);
  }
  const ssl = { rejectUnauthorized: true };
  if (env.DB_CA_CERT && env.DB_CA_CERT !== 'your_ca_certificate_if_applicable') {
    ssl.ca = env.DB_CA_CERT.replace(/\\n/g, '\n');
  }
  return { connectionString: url?.toString(), ssl };
}

module.exports = { databaseOptions };
