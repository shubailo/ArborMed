const axios = require('axios');
const API_URL = 'http://localhost:3000';

async function testFilters() {
    try {
        console.log('--- Auth ---');
        const email = `filtertest_${Date.now()}@test.com`;
        const reg = await axios.post(`${API_URL}/auth/register`, { email, password: 'pw', name: 'Tester' });
        const token = reg.data.token;
        const config = { headers: { Authorization: `Bearer ${token}` } };
        console.log('Got token.');

        console.log('--- Testing Shop Filters ---');

        // 1. Test Filter by Slot (Desk)
        console.log('1. Filtering by slot_type=desk...');
        const deskRes = await axios.get(`${API_URL}/shop/items?slot_type=desk`, config);
        console.log(`Found ${deskRes.data.length} desk items.`);
        const isDeskOnly = deskRes.data.every(i => i.slot_type === 'desk');
        console.log('Is Desk Only?', isDeskOnly);

        // 2. Test Filter by Theme (Vintage)
        console.log('2. Filtering by theme=vintage...');
        const vintageRes = await axios.get(`${API_URL}/shop/items?theme=vintage`, config);
        console.log(`Found ${vintageRes.data.length} vintage items.`);
        const isVintageOnly = vintageRes.data.every(i => i.theme === 'vintage');
        console.log('Is Vintage Only?', isVintageOnly);

        // 3. Test Filter by Unlock (JSON check)
        console.log('3. Checking Unlock Req data...');
        const wallRes = await axios.get(`${API_URL}/shop/items?slot_type=wall`, config);
        const lockedItem = wallRes.data.find(i => i.unlock_req);
        if (lockedItem) {
            console.log('Found Item with Unlock Req:', lockedItem.name, lockedItem.unlock_req);
        } else {
            console.log('No locked items found (unexpected).');
        }

    } catch (e) {
        console.error('Test Failed:', e.message);
    }
}

testFilters();
