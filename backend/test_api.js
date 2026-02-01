const http = require('http');

const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/quiz/admin/questions?page=1&limit=10',
    method: 'GET',
    headers: {
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'  // You'll need to replace with actual token
    }
};

const req = http.request(options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        console.log('Status:', res.statusCode);
        console.log('Response:', data.substring(0, 500));
    });
});

req.on('error', (error) => {
    console.error('Error:', error);
});

req.end();
