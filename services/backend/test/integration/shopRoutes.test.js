const { once } = require('node:events');
const express = require('express');
const shop = require('../../src/routes/shopRoutes');
const { buyItem } = require('../../src/controllers/shopController');
const { getInventory } = require('../../src/controllers/inventoryController');

jest.mock('../../src/middleware/authMiddleware', () => ({
  protect: (req, res, next) => req.get('Authorization') ? next() : res.sendStatus(401),
}));

jest.mock('../../src/controllers/shopController', () => ({
  getCatalog: jest.fn(),
  buyItem: jest.fn((req, res) => res.json(req.body)),
}));

jest.mock('../../src/controllers/inventoryController', () => ({
  getInventory: jest.fn((req, res) => res.json(req.query)),
  equipItem: jest.fn((req, res) => res.sendStatus(200)),
  unequipItem: jest.fn((req, res) => res.sendStatus(200)),
  syncRoomState: jest.fn((req, res) => res.sendStatus(200)),
}));

let server;
let base;
const headers = { Authorization: 'test', 'Content-Type': 'application/json' };

beforeAll(async () => {
  const app = express();
  app.use(express.json());
  app.use('/shop', shop);
  app.use((error, req, res, next) => res.sendStatus(error.statusCode ?? 500));
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = 'http://127.0.0.1:' + server.address().port + '/shop';
});

afterAll(async () => {
  await new Promise(resolve => server.close(resolve));
});

test.each(['/buy', '/equip', '/unequip', '/sync-room'])(
  '%s rejects an array or absent body after authentication',
  async route => {
    expect((await fetch(base + route, { method: 'POST' })).status).toBe(401);
    for (const body of [undefined, '[]', '{}']) {
      expect((await fetch(base + route, { method: 'POST', headers, body })).status).toBe(400);
    }
  }
);

test('valid purchases and inventory views reach their controllers', async () => {
  const purchased = await fetch(base + '/buy', {
    method: 'POST', headers, body: JSON.stringify({ itemId: 3 }),
  });
  expect(await purchased.json()).toEqual({ itemId: 3 });
  expect(buyItem).toHaveBeenCalledTimes(1);

  for (const query of ['?userId=', '?userId=2147483648', '?userId=2&userId=3']) {
    expect((await fetch(base + '/inventory' + query, { headers })).status).toBe(400);
  }
  expect(getInventory).not.toHaveBeenCalled();
  for (const query of ['', '?userId=2']) {
    expect((await fetch(base + '/inventory' + query, { headers })).status).toBe(200);
  }
  expect(getInventory).toHaveBeenCalledTimes(2);
});
