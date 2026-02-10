const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { protect } = require('../middleware/authMiddleware');

// Configure Multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        let folder = 'uploads/';
        if (req.query.folder === 'icons') {
            folder = 'uploads/icons/';
        }

        if (!fs.existsSync(folder)) {
            fs.mkdirSync(folder, { recursive: true });
        }
        cb(null, folder);
    },
    filename: (req, file, cb) => {
        // Safe filename
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 20 * 1024 * 1024 }, // 20MB limit
    fileFilter: (req, file, cb) => {
        const filetypes = /jpeg|jpg|png|gif|webp|bmp|svg\+xml|tiff/;
        const mimetype = filetypes.test(file.mimetype);
        const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
        if (mimetype || extname) {
            return cb(null, true);
        }
        cb(new Error('Only images are allowed!'));
    }
});

// Endpoint
router.post('/', protect, upload.single('image'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }
        // Return relative path
        // Fix path separators for Windows compatibility if needed, though usually / works in URLs
        let imageUrl = req.file.path.replace(/\\/g, '/');
        // Ensure it starts with /uploads
        if (!imageUrl.startsWith('/')) imageUrl = '/' + imageUrl;
        // Make sure we strip any local path parts if they leaked (unlikely with relative destination)
        // Multer 'path' is relative to CWD if destination is relative.
        // We want URL path.
        const folder = req.query.folder === 'icons' ? '/uploads/icons/' : '/uploads/';
        imageUrl = folder + req.file.filename;

        res.json({ imageUrl });
    } catch (error) {
        console.error("Upload error:", error);
        res.status(500).json({ message: 'Upload failed' });
    }
});

// List all uploaded images
router.get('/', (req, res) => {
    let directoryPath = path.join(__dirname, '../../uploads');
    let urlPrefix = '/uploads/';

    if (req.query.folder === 'icons') {
        directoryPath = path.join(__dirname, '../../uploads/icons');
        urlPrefix = '/uploads/icons/';

        // Create if not exists to avoid error on first run
        if (!fs.existsSync(directoryPath)) {
            fs.mkdirSync(directoryPath, { recursive: true });
        }
    }

    fs.readdir(directoryPath, (err, files) => {
        if (err) {
            // console.error("Unable to scan directory:", err); 
            // If directory doesn't exist or empty, just return empty list
            return res.json({ images: [] });
        }

        const images = files.filter(file => {
            const ext = path.extname(file).toLowerCase();
            return ['.png', '.jpg', '.jpeg', '.gif', '.webp'].includes(ext);
        }).map(file => urlPrefix + file);

        res.json({ images });
    });
});

// Delete an image
router.delete('/:filename', protect, (req, res) => {
    const filename = req.params.filename;
    // Basic directory traversal protection
    if (filename.includes('..') || filename.includes('/')) {
        return res.status(400).json({ message: 'Invalid filename' });
    }

    const filePath = path.join(__dirname, '../../uploads', filename);

    if (fs.existsSync(filePath)) {
        fs.unlink(filePath, (err) => {
            if (err) {
                console.error("Error deleting file:", err);
                return res.status(500).json({ message: 'Could not delete file' });
            }
            res.json({ message: 'File deleted successfully' });
        });
    } else {
        res.status(404).json({ message: 'File not found' });
    }
});

module.exports = router;
