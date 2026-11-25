const defaults = ['https://arbor-med.netlify.app', 'https://master--arbor-med.netlify.app'];

function isAllowedOrigin(origin, env = process.env) {
  if (origin === undefined) return true; // Native clients can omit Origin.
  const configured = (env.ALLOWED_ORIGINS || '').split(',').map(value => value.trim()).filter(Boolean);
  if (defaults.includes(origin) || configured.includes(origin)) return true;
  return env.NODE_ENV === 'development' &&
    /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/.test(origin);
}

function corsOrigin(origin, callback) {
  callback(null, isAllowedOrigin(origin));
}

module.exports = { isAllowedOrigin, corsOrigin };
