const fs = require('fs');

/**
 * Robustly checks if the content is a valid SVG.
 * Skips XML declarations, processing instructions, comments, and DOCTYPEs.
 * @param {string} content - The file content to check.
 * @returns {boolean} - True if it's an SVG.
 */
function isSVG(content) {
  let index = 0;
  const lowerContent = content.toLowerCase();

  while (index < content.length) {
    // Skip whitespace
    while (index < content.length && /\s/.test(content[index])) {
      index++;
    }
    if (index >= content.length) break;

    if (content.startsWith('<?', index)) {
      // Skip Processing Instructions (like <?xml ... ?> or <?xml-stylesheet ... ?>)
      const end = content.indexOf('?>', index);
      if (end === -1) return false;
      index = end + 2;
    } else if (content.startsWith('<!--', index)) {
      // Skip Comments
      const end = content.indexOf('-->', index);
      if (end === -1) return false;
      index = end + 3;
    } else if (lowerContent.startsWith('<!doctype', index)) {
      // Skip DOCTYPE with possible internal subset
      let end = index + 9;
      let bracketDepth = 0;
      while (end < content.length) {
        if (content[end] === '[') bracketDepth++;
        else if (content[end] === ']') bracketDepth--;
        else if (content[end] === '>' && bracketDepth === 0) break;
        end++;
      }
      if (end >= content.length) return false;
      index = end + 1;
    } else if (lowerContent.startsWith('<svg', index)) {
      // Ensure it's a whole tag name (e.g., <svg> or <svg ... >)
      // but also allow for namespace prefixes if they exist (though rare for root)
      const nextChar = content[index + 4];
      if (
        !nextChar ||
        /\s/.test(nextChar) ||
        nextChar === '>' ||
        nextChar === '/' ||
        nextChar === ':'
      ) {
        return true;
      }
      return false;
    } else {
      // Found something else before <svg
      return false;
    }
  }
  return false;
}

/**
 * Validates the file content by checking its magic numbers.
 * @param {string} filePath - The path to the file.
 * @returns {Promise<boolean>} - Resolves to true if valid, false otherwise.
 */
function checkFileSignature(filePath) {
  return new Promise((resolve, reject) => {
    fs.open(filePath, 'r', (err, fd) => {
      if (err) return reject(err);

      const buffer = Buffer.alloc(4096); // Read first 4KB to handle SVGs with headers
      fs.read(fd, buffer, 0, 4096, 0, (err, bytesRead) => {
        fs.close(fd, () => {}); // Close immediately after reading
        if (err) return reject(err);

        // Check Magic Numbers

        // JPEG: FF D8 FF
        if (
          bytesRead >= 3 &&
          buffer[0] === 0xff &&
          buffer[1] === 0xd8 &&
          buffer[2] === 0xff
        )
          return resolve(true);

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (
          bytesRead >= 8 &&
          buffer[0] === 0x89 &&
          buffer[1] === 0x50 &&
          buffer[2] === 0x4e &&
          buffer[3] === 0x47 &&
          buffer[4] === 0x0d &&
          buffer[5] === 0x0a &&
          buffer[6] === 0x1a &&
          buffer[7] === 0x0a
        )
          return resolve(true);

        // GIF: 47 49 46 38
        if (
          bytesRead >= 4 &&
          buffer[0] === 0x47 &&
          buffer[1] === 0x49 &&
          buffer[2] === 0x46 &&
          buffer[3] === 0x38
        )
          return resolve(true);

        // BMP: 42 4D
        if (bytesRead >= 2 && buffer[0] === 0x42 && buffer[1] === 0x4d)
          return resolve(true);

        // TIFF (Little Endian): 49 49 2A 00
        if (
          bytesRead >= 4 &&
          buffer[0] === 0x49 &&
          buffer[1] === 0x49 &&
          buffer[2] === 0x2a &&
          buffer[3] === 0x00
        )
          return resolve(true);

        // TIFF (Big Endian): 4D 4D 00 2A
        if (
          bytesRead >= 4 &&
          buffer[0] === 0x4d &&
          buffer[1] === 0x4d &&
          buffer[2] === 0x00 &&
          buffer[3] === 0x2a
        )
          return resolve(true);

        // WEBP: RIFF ... WEBP
        if (
          bytesRead >= 12 &&
          buffer[0] === 0x52 &&
          buffer[1] === 0x49 &&
          buffer[2] === 0x46 &&
          buffer[3] === 0x46 &&
          buffer[8] === 0x57 &&
          buffer[9] === 0x45 &&
          buffer[10] === 0x42 &&
          buffer[11] === 0x50
        )
          return resolve(true);

        // SVG Check
        const content = buffer.slice(0, bytesRead).toString('utf8');
        if (isSVG(content)) {
          return resolve(true);
        }

        resolve(false);
      });
    });
  });
}

module.exports = { checkFileSignature };
