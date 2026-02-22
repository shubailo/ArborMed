const fs = require('fs');

/**
 * Validates the file content by checking its magic numbers.
 * @param {string} filePath - The path to the file.
 * @returns {Promise<boolean>} - Resolves to true if valid, false otherwise.
 */
function checkFileSignature(filePath) {
    return new Promise((resolve, reject) => {
        fs.open(filePath, 'r', (err, fd) => {
            if (err) return reject(err);

            const buffer = Buffer.alloc(100); // Read first 100 bytes
            fs.read(fd, buffer, 0, 100, 0, (err, bytesRead) => {
                fs.close(fd, () => {}); // Close immediately after reading
                if (err) return reject(err);

                // Check Magic Numbers

                // JPEG: FF D8 FF
                if (bytesRead >= 3 && buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF) return resolve(true);

                // PNG: 89 50 4E 47 0D 0A 1A 0A
                if (bytesRead >= 8 && buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47 &&
                    buffer[4] === 0x0D && buffer[5] === 0x0A && buffer[6] === 0x1A && buffer[7] === 0x0A) return resolve(true);

                // GIF: 47 49 46 38
                if (bytesRead >= 4 && buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x38) return resolve(true);

                // BMP: 42 4D
                if (bytesRead >= 2 && buffer[0] === 0x42 && buffer[1] === 0x4D) return resolve(true);

                // TIFF (Little Endian): 49 49 2A 00
                if (bytesRead >= 4 && buffer[0] === 0x49 && buffer[1] === 0x49 && buffer[2] === 0x2A && buffer[3] === 0x00) return resolve(true);

                // TIFF (Big Endian): 4D 4D 00 2A
                if (bytesRead >= 4 && buffer[0] === 0x4D && buffer[1] === 0x4D && buffer[2] === 0x00 && buffer[3] === 0x2A) return resolve(true);

                // WEBP: RIFF ... WEBP
                if (bytesRead >= 12 && buffer[0] === 0x52 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x46 &&
                    buffer[8] === 0x57 && buffer[9] === 0x45 && buffer[10] === 0x42 && buffer[11] === 0x50) return resolve(true);

                // SVG Check
                // Convert buffer to string and check for <svg or <?xml
                const content = buffer.slice(0, bytesRead).toString('utf8').trim();
                if (content.toLowerCase().startsWith('<?xml') || content.toLowerCase().includes('<svg')) {
                    return resolve(true);
                }

                resolve(false);
            });
        });
    });
}

module.exports = { checkFileSignature };
