const fs = require('fs');
const path = require('path');
const { checkFileSignature } = require('../../../src/utils/fileValidation');

describe('fileValidation', () => {
  const testFiles = [];

  const createTestFile = (content, extension = '.tmp') => {
    const filePath = path.join(
      __dirname,
      `test-${Math.random().toString(36).substring(7)}${extension}`
    );
    fs.writeFileSync(filePath, content);
    testFiles.push(filePath);
    return filePath;
  };

  afterAll(() => {
    testFiles.forEach((file) => {
      if (fs.existsSync(file)) {
        fs.unlinkSync(file);
      }
    });
  });

  test('should validate JPEG', async () => {
    const filePath = createTestFile(
      Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46])
    );
    expect(await checkFileSignature(filePath)).toBe(true);
  });

  test('should validate PNG', async () => {
    const filePath = createTestFile(
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    );
    expect(await checkFileSignature(filePath)).toBe(true);
  });

  test('should validate valid SVG', async () => {
    const filePath = createTestFile(
      '<svg xmlns="http://www.w3.org/2000/svg"><circle cx="50" cy="50" r="40" /></svg>',
      '.svg'
    );
    expect(await checkFileSignature(filePath)).toBe(true);
  });

  test('should validate SVG with XML declaration', async () => {
    const filePath = createTestFile(
      '<?xml version="1.0" encoding="UTF-8"?><svg>...</svg>',
      '.svg'
    );
    expect(await checkFileSignature(filePath)).toBe(true);
  });

  test('should validate SVG with comments', async () => {
    const filePath = createTestFile('<!-- comment --><svg>...</svg>', '.svg');
    expect(await checkFileSignature(filePath)).toBe(true);
  });

  test('should REJECT malicious file bypassing SVG check (vulnerability)', async () => {
    // This file contains <svg but is not an SVG file
    const filePath = createTestFile('/* <svg */ alert("XSS");', '.js');
    // Currently this returns true, but it SHOULD return false
    const result = await checkFileSignature(filePath);
    expect(result).toBe(false);
  });

  test('should REJECT file with <svg tag deep in content', async () => {
    // Create a large file where <svg appears after 5000 bytes
    const content = 'a'.repeat(5000) + '<svg>';
    const filePath = createTestFile(content, '.txt');
    expect(await checkFileSignature(filePath)).toBe(false);
  });

  test('should REJECT non-image files', async () => {
    const filePath = createTestFile('Not an image at all', '.txt');
    expect(await checkFileSignature(filePath)).toBe(false);
  });

  test('should sanitize SVG with <script> tag', async () => {
    const content = '<svg><script>alert(1)</script><rect /></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).not.toContain('<script>');
    expect(sanitized).toContain('<rect />');
  });

  test('should sanitize SVG with event handlers', async () => {
    const content =
      '<svg><rect onclick="alert(1)" onmouseover="alert(2)" /></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).not.toContain('onclick');
    expect(sanitized).not.toContain('onmouseover');
  });

  test('should sanitize SVG with javascript: href', async () => {
    const content = '<svg><a href="javascript:alert(1)">link</a></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).not.toContain('javascript:');
  });

  test('should sanitize SVG with foreignObject', async () => {
    const content = '<svg><foreignObject><div>HTML</div></foreignObject></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).not.toContain('<foreignObject>');
    expect(sanitized).not.toContain('<div>HTML</div>');
  });

  test('should sanitize SVG with self-closing <script /> tag', async () => {
    const content = '<svg><script href="http://malicious.com/xss.js" /><rect /></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).not.toContain('<script');
    expect(sanitized).toContain('<rect />');
  });

  test('should sanitize SVG with unquoted event handler', async () => {
    const content = '<svg><rect onclick=alert(1) /></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).not.toContain('onclick');
    expect(sanitized).toContain('<rect />');
  });

  test('should sanitize SVG with javascript: href (entity encoded)', async () => {
    // This bypasses simple regex but whitelist should catch it
    const content = '<svg><a href="&#106;avascript:alert(1)">link</a></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    // Attribute should be removed because it doesn't start with http/https/#/\/
    expect(sanitized).not.toContain('href');
    expect(sanitized).toContain('<a>link</a>');
  });

  test('should ALLOW valid http: href', async () => {
    const content = '<svg><a href="http://google.com">link</a></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).toContain('href="http://google.com"');
  });

  test('should ALLOW valid relative / href', async () => {
    const content = '<svg><a href="/home">link</a></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).toContain('href="/home"');
  });

   test('should sanitize SVG with relative href not starting with /', async () => {
    // Relative paths like "image.png" are blocked by whitelist
    const content = '<svg><image href="image.png" /></svg>';
    const filePath = createTestFile(content, '.svg');
    const result = await checkFileSignature(filePath);
    expect(result).toBe(true);
    const sanitized = fs.readFileSync(filePath, 'utf8');
    expect(sanitized).not.toContain('href="image.png"');
  });
});
