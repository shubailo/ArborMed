const fs = require('fs');
const path = require('path');
const { checkFileSignature } = require('../src/utils/fileValidation');

const testDir = path.join(__dirname, 'test_files');
if (!fs.existsSync(testDir)) {
    fs.mkdirSync(testDir);
}

// Helper to create file
function createFile(filename, buffer) {
    const filepath = path.join(testDir, filename);
    fs.writeFileSync(filepath, buffer);
    return filepath;
}

// Test cases
async function runTests() {
    console.log('Running file validation tests...');

    // Valid JPEG
    const jpgBuffer = Buffer.from([0xFF, 0xD8, 0xFF]);
    const jpgFile = createFile('test.jpg', jpgBuffer);
    if (await checkFileSignature(jpgFile)) {
        console.log('PASS: Valid JPEG');
    } else {
        console.error('FAIL: Valid JPEG rejected');
    }

    // Valid PNG
    const pngBuffer = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    const pngFile = createFile('test.png', pngBuffer);
    if (await checkFileSignature(pngFile)) {
        console.log('PASS: Valid PNG');
    } else {
        console.error('FAIL: Valid PNG rejected');
    }

    // Valid WEBP
    const webpBuffer = Buffer.alloc(12);
    webpBuffer.write('RIFF', 0);
    webpBuffer.write('WEBP', 8);
    const webpFile = createFile('test.webp', webpBuffer);
    if (await checkFileSignature(webpFile)) {
        console.log('PASS: Valid WEBP');
    } else {
        console.error('FAIL: Valid WEBP rejected');
    }

    // Valid SVG
    const svgBuffer = Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>');
    const svgFile = createFile('test.svg', svgBuffer);
    if (await checkFileSignature(svgFile)) {
        console.log('PASS: Valid SVG');
    } else {
        console.error('FAIL: Valid SVG rejected');
    }

    // Invalid File (Text file simulating JS)
    const jsBuffer = Buffer.from('console.log("malicious")');
    const jsFile = createFile('malicious.js', jsBuffer);
    const result = await checkFileSignature(jsFile);
    if (!result) {
        console.log('PASS: Invalid JS file blocked');
    } else {
        console.error('FAIL: Invalid JS file allowed');
    }

    // Clean up
    fs.rmSync(testDir, { recursive: true, force: true });
}

runTests().catch(err => console.error(err));
