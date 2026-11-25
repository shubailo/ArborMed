const express = require('express');
const multer = require('multer');
const os = require('node:os');
const path = require('node:path');
const fs = require('node:fs/promises');
const { randomUUID } = require('node:crypto');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/adminMiddleware');
const { checkFileSignature } = require('../utils/fileValidation');
const storage = require('../services/uploadStorage');

const router = express.Router();
const mediaTypes = { '.png': 'image/png', '.jpeg': 'image/jpeg', '.jpg': 'image/jpeg', '.gif': 'image/gif',
    '.bmp': 'image/bmp', '.svg': 'image/svg+xml', '.tiff': 'image/tiff', '.webp': 'image/webp' };
const upload = multer({
    dest: os.tmpdir(), limits: { files: 1, fileSize: 20 * 1024 * 1024 },
    fileFilter: (_req, file, cb) => cb(null, mediaTypes[path.extname(file.originalname).toLowerCase()] === file.mimetype),
});

router.use(protect, admin);
router.post('/', upload.single('image'), async (req, res) => {
    if (!req.file) return res.status(400).json({ message: 'Select a supported image' });
    try {
        if (!await checkFileSignature(req.file.path)) return res.status(400).json({ message: 'Invalid file content' });
        const name = randomUUID() + path.extname(req.file.originalname).toLowerCase();
        const imageUrl = await storage.save(storage.groupOf(req.query.folder), name, req.file.path, req.file.mimetype);
        res.json({ imageUrl });
    } finally {
        await fs.rm(req.file.path, { force: true });
    }
});

router.get('/', async (req, res) => res.json({ images: await storage.list(storage.groupOf(req.query.folder)) }));
router.delete('/:filename', async (req, res) => {
    const { filename } = req.params;
    if (!storage.imageName.test(filename) || filename.includes('..')) return res.status(400).json({ message: 'Invalid filename' });
    if (!await storage.remove(storage.groupOf(req.query.folder), filename, req.query.stored === 'true')) {
        return res.status(404).json({ message: 'File not found' });
    }
    res.json({ message: 'File deleted successfully' });
});

router.use((err, _req, res, next) => {
    if (!(err instanceof multer.MulterError)) return next(err);
    if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ message: 'Images must be at most 20 MiB' });
    return res.status(400).json({ message: 'Select one image for upload' });
});

module.exports = router;
