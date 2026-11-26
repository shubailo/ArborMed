const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const fs = require('node:fs/promises');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');

test('two ArborMed loads preserve both applications’ workers and cached responses', async () => {
  const entry = await fs.readFile(path.join(__dirname, '../apps/student_app/web/index.html'), 'utf8');
  const profile = await fs.mkdtemp(path.join(os.tmpdir(), 'arbormed-entry-'));
  const scopes = ['/app/', '/sibling/'];
  const names = ['flutter-app-cache', 'sibling-resources'];
  const seed = async (scopes, names) => {
    await Promise.all(scopes.map(async (scope, i) => {
      await navigator.serviceWorker.register(scope + 'sw.js', { scope });
      const cache = await caches.open(names[i]);
      await cache.put(scope + 'fixture', new Response('saved-' + i));
    }));
    location.replace('/app/');
  };
  const check = async (names) => {
    if (!sessionStorage.getItem('reloaded')) {
      sessionStorage.setItem('reloaded', 'yes');
      location.reload();
      return;
    }
    const registrations = await navigator.serviceWorker.getRegistrations();
    const contents = await Promise.all(names.map(async (name, i) => {
      const value = await caches.match(['/app/fixture', '/sibling/fixture'][i], { cacheName: name });
      return value ? value.text() : null;
    }));
    await fetch('/result', { method: 'POST', body: JSON.stringify({
      scopes: registrations.map(r => new URL(r.scope).pathname).sort(), contents
    }) });
  };
  const run = (fn, ...args) => '(' + fn.toString() + ')(' + args.map(arg => JSON.stringify(arg)).join(',') +
    ').catch(e => fetch("/result", { method: "POST", body: JSON.stringify({error:String(e)}) }))';
  let finish, fail;
  const result = new Promise((resolve, reject) => { finish = resolve; fail = reject; });
  const server = http.createServer(async (req, res) => {
    const send = (type, data) => { res.setHeader('Content-Type', type); res.end(data); };
    switch (req.url) {
      case '/seed':
        return send('text/html', '<script>' + run(seed, scopes, names) + '</script>');
      case '/app/sw.js':
      case '/sibling/sw.js':
        return send('text/javascript', 'self.addEventListener("install", () => self.skipWaiting());');
      case '/app/':
        res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' 'unsafe-inline'");
        return send('text/html', entry.replace('$FLUTTER_BASE_HREF', '/app/'));
      case '/app/flutter_bootstrap.js':
        return send('text/javascript', run(check, names));
      case '/result': {
        let body = '';
        for await (const chunk of req) body += chunk;
        res.end();
        try { finish(JSON.parse(body)); } catch (err) { fail(err); }
        return;
      }
      default:
        res.writeHead(404).end();
    }
  });
  let browser, timer, closed;
  try {
    await new Promise((r, j) => { server.once('error', j); server.listen(0, '127.0.0.1', r); });
    browser = spawn(process.env.CHROME_BIN || 'google-chrome', [
      '--headless', '--no-sandbox', '--disable-dev-shm-usage', '--disable-background-networking',
      '--no-first-run', '--user-data-dir=' + profile, 'http://127.0.0.1:' + server.address().port + '/seed'
    ], { stdio: 'ignore', windowsHide: true });
    closed = new Promise(r => browser.once('close', code => { fail(Error('Chrome exited: ' + code)); r(); }));
    browser.once('error', fail);
    timer = setTimeout(() => fail(Error('Timed out waiting for the entry page')), 30000);
    assert.deepEqual(await result, { scopes, contents: ['saved-0', 'saved-1'] });
  } finally {
    clearTimeout(timer);
    browser?.kill();
    if (closed) await closed;
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
    await fs.rm(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 });
  }
});
