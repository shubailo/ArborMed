const fs = require('node:fs/promises');
const path = require('node:path');

const localRoot = path.resolve(__dirname, '../../uploads');
const imageName = /^[\w.-]+\.(?:jpe?g|gif|png|webp|svg|bmp|tiff)$/i;
const remoteName = /^[a-f\d]{8}-(?:[a-f\d]{4}-){3}[a-f\d]{12}\.(?:jpe?g|gif|png|webp|svg|bmp|tiff)$/i;
const groupOf = folder => folder === 'icons' ? 'icons' : 'images';
const localDir = group => group === 'icons' ? path.join(localRoot, 'icons') : localRoot;
const localUrl = (group, name) => '/uploads/' + (group === 'icons' ? 'icons/' : '') + name;
const storedUrl = (group, name) => '/uploads/stored/' + group + '/' + name;
let iconGallery;

function remote() {
  const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY: key, SUPABASE_UPLOAD_BUCKET: bucket } = process.env;
  if (!SUPABASE_URL || !key || !bucket) return null;
  return { base: new URL('/storage/v1/', SUPABASE_URL).href, key, bucket: encodeURIComponent(bucket) };
}

async function request(config, method, endpoint, body, contentType = 'application/json') {
  const response = await fetch(config.base + endpoint, {
    method, body, redirect: 'error', signal: AbortSignal.timeout(30000),
    headers: { apikey: config.key, Authorization: 'Bearer ' + config.key, 'Content-Type': contentType },
  });
  if (!response.ok) throw new Error('Object storage returned ' + response.status);
  return response;
}

async function save(group, name, tempPath, type) {
  const config = remote();
  if (config) {
    await request(config, 'POST', 'object/' + config.bucket + '/' + group + '/' + name, await fs.readFile(tempPath), type);
    if (group === 'icons') iconGallery = null;
    return storedUrl(group, name);
  }
  if (process.env.NODE_ENV === 'production') throw new Error('Persistent upload storage is not configured');
  await fs.mkdir(localDir(group), { recursive: true });
  await fs.copyFile(tempPath, path.join(localDir(group), name), fs.constants.COPYFILE_EXCL);
  if (group === 'icons') iconGallery = null;
  return localUrl(group, name);
}

async function list(group) {
  let files;
  try { files = await fs.readdir(localDir(group), { withFileTypes: true }); }
  catch (err) { if (err.code !== 'ENOENT') throw err; files = []; }
  const images = files.filter(f => f.isFile() && imageName.test(f.name)).map(f => localUrl(group, f.name));
  const config = remote();
  if (config) {
    const limit = 100;
    for (let offset = 0; ; offset += limit) {
      const response = await request(config, 'POST', 'object/list/' + config.bucket,
        JSON.stringify({ prefix: group + '/', offset, limit, sortBy: { column: 'name', order: 'asc' } }));
      const entries = await response.json();
      images.push(...entries.filter(e => e.id !== null && remoteName.test(e.name)).map(e => storedUrl(group, e.name)));
      if (entries.length < limit) break;
    }
  }
  return images;
}

// A quote needs one image. Share the storage listing between simultaneous readers.
async function randomIcon() {
  if (!iconGallery || Date.now() >= iconGallery.expires) {
    iconGallery = { files: list('icons'), expires: Date.now() + 60000 };
  }
  const snapshot = iconGallery;
  try {
    const icons = await snapshot.files;
    return icons.length ? icons[Math.floor(Math.random() * icons.length)] : null;
  } catch (error) {
    if (iconGallery === snapshot) iconGallery = null;
    throw error;
  }
}

async function remove(group, name, stored) {
  if (!imageName.test(name) || name.includes('..')) return false;
  if (stored) {
    const config = remote();
    if (!config || !remoteName.test(name)) return false;
    const result = await request(config, 'DELETE', 'object/' + config.bucket, JSON.stringify({ prefixes: [group + '/' + name] }));
    if (group === 'icons') iconGallery = null;
    return (await result.json()).length > 0;
  } else {
    try { await fs.unlink(path.join(localDir(group), name)); }
    catch (err) { if (err.code === 'ENOENT') return false; throw err; }
  }
    if (group === 'icons') iconGallery = null;
    return true;
}

function publicUrl(group, name) {
  const config = remote();
  if (!config || !['icons', 'images'].includes(group) || !remoteName.test(name)) return null;
  return config.base + 'object/public/' + config.bucket + '/' + group + '/' + name;
}

module.exports = { groupOf, imageName, publicUrl, save, list, randomIcon, remove };
