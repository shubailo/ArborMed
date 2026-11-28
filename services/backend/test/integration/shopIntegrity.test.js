const { randomUUID } = require('crypto');
const { readFileSync } = require('fs');
const { join } = require('path');
const { Pool, Client } = require('pg');
jest.mock('../../src/config/db', () => ({query: jest.fn(),pool:{connect:jest.fn()}}));
const db = require('../../src/config/db');
const shop = require('../../src/controllers/shopController');
const inventory = require('../../src/controllers/inventoryController');
const social = require('../../src/controllers/socialController');
const crate = require('../../src/services/crateService');
const crateHttp = require('../../src/controllers/crateController');
const { seedGoldCatalog } = require('../../src/scripts/seeders/seedGoldCatalog');
const run = process.env.TEST_DATABASE_URL ? describe : describe.skip;

run('shop ownership and purchase transactions', () => {
    const schema = 'shop_test_' + randomUUID().replaceAll('-', '');
    let admin, pool;
    beforeAll(async () => {
        const connectionString = process.env.TEST_DATABASE_URL;
        admin = new Client({connectionString});
        await admin.connect();
        await admin.query(`CREATE SCHEMA ${schema}`);
        pool = new Pool({connectionString, options:`-c search_path=${schema}`});
        await pool.query('CREATE TABLE users(id integer PRIMARY KEY, coins integer)');
        for (const name of ['002_gamification.sql','004_smart_shop.sql','005_iso_coords.sql']) {
            await pool.query(readFileSync(join(__dirname,'../../migrations',name),'utf8'));
        }
        await pool.query('CREATE TABLE room_likes(liker_id integer, receiver_id integer, UNIQUE(liker_id, receiver_id))');
        await pool.query(readFileSync(join(__dirname,'../../migrations/065_shop_integrity.sql'),'utf8'));
        db.pool.connect.mockImplementation(() => pool.connect());
        db.query.mockImplementation((...args) => pool.query(...args));
    });
    afterAll(async () => {
        await pool?.end();
        if (admin) {
            try { await admin.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`); } finally { await admin.end(); }
        }
    });
    beforeEach(async () => {
        await pool.query(`TRUNCATE users, items, user_rooms, user_items, crate_purchases, room_likes RESTART IDENTITY;
            INSERT INTO users VALUES(1,200),(2,200);
            INSERT INTO items(id,name,type,slot_type,price,asset_path,theme)
            VALUES(19,'Desk','furniture','desk',40,'desk.png','clinical'),(20,'Lamp','furniture','desk',50,'lamp.png','dark')`);
    });
    async function call(handler, body, user=1) {
        let result;
        const res = {json:data=>{result=data;}, status:()=>res};
        await handler({body,user:{id:user}}, res, error=>{throw error;});
        return result;
    }
    const balance = async () => (await pool.query('SELECT coins FROM users WHERE id=1')).rows[0].coins;
    it('concurrent taps and replays unlock once, while a stale purchase quote rolls back', async () => {
        const buy = () => call(shop.buyItem,{itemId:19});
        const [a,b] = await Promise.all([buy(),buy()]);
        expect(a.userItemId).toBe(b.userItemId);
        expect(await buy()).toEqual(a);
        await expect(call(shop.buyItem,{itemId:20,expectedPrice:0})).rejects.toMatchObject({statusCode:409});
        expect(await balance()).toBe(160);
        expect((await pool.query('SELECT FROM user_items')).rowCount).toBe(1);
        await pool.query('UPDATE users SET coins=coins+10 WHERE id=1');
        expect(await buy()).toEqual({...a,newBalance:170});
        expect((await pool.query('SELECT FROM user_items')).rowCount).toBe(1);
    });
    it('allows a free unlock with a historical null balance and repeats the same unlock', async () => {
        await pool.query('UPDATE users SET coins=NULL WHERE id=1');
        await pool.query('UPDATE items SET price=0 WHERE id=19');
        const buy = () => call(shop.buyItem,{itemId:'19',expectedPrice:0});
        const first = await buy();
        expect(first.newBalance).toBe(0);
        expect(await buy()).toEqual(first);
        expect(await balance()).toBe(0);
        expect((await pool.query('SELECT FROM user_items')).rowCount).toBe(1);
    });
    it('rejects missing crate request objects and malformed IDs before checkout', async () => {
        const checkouts = db.pool.connect.mock.calls.length;
        for (const body of [undefined, [], {purchaseId:null}, {purchaseId:' '}]) {
            await expect(call(crateHttp.openCrate,body)).rejects.toMatchObject({statusCode:400});
        }
        expect(db.pool.connect.mock.calls).toHaveLength(checkouts);
        expect(await balance()).toBe(200);
    });
    it('reports a removed account consistently and rolls back an opening without stock', async () => {
        await expect(call(shop.buyItem,{itemId:19},99)).rejects.toMatchObject({statusCode:404});
        await expect(call(crateHttp.openCrate,{purchaseId:'opening-1'},99)).rejects.toMatchObject({statusCode:404});
        await pool.query("UPDATE items SET theme='dark'");
        await expect(call(crateHttp.openCrate,{purchaseId:'opening-1'})).rejects.toMatchObject({statusCode:409});
        expect(await balance()).toBe(200);
        expect((await pool.query('SELECT FROM crate_purchases')).rowCount).toBe(0);
        expect((await pool.query('SELECT FROM user_items')).rowCount).toBe(0);
    });
    it('replays the same keyed crate across aliases and supports subsequent keyed or legacy opens', async () => {
        const open = type => crate.openCrate(1,type,'opening-1');
        const [a,b] = await Promise.all([open('clinical'),open('clinical_crate')]);
        expect(a).toEqual(b);
        expect(a.item.id).toBe(19);
        await expect(crate.openCrate(1,'dark')).rejects.toMatchObject({statusCode:400});
        await crate.openCrate(1,'clinical','opening-2');
        await crate.openCrate(1);
        await crate.openCrate(1);
        expect(await balance()).toBe(0);
        expect((await pool.query('SELECT FROM user_items')).rowCount).toBe(4);
    });
    it('rejects foreign rooms and rolls back the entire layout on an invalid item', async () => {
        await pool.query(`INSERT INTO user_rooms(id,user_id,room_type) VALUES (5,1,'exam'),(6,2,'exam');
            INSERT INTO user_items(id,user_id,item_id) VALUES(41,1,19),(42,1,20),(43,2,19)`);
        const equip = id => call(inventory.equipItem,{roomId:5,slot:'desk',x:null,y:null,userItemId:id});
        await Promise.all([equip(41),equip(42)]);
        const placed = async () => (await pool.query('SELECT id FROM user_items WHERE is_placed ORDER BY id')).rows;
        const before = await placed();
        expect(before).toHaveLength(1);
        await expect(call(inventory.syncRoomState,{roomId:6,items:[{userItemId:41}]})).rejects.toMatchObject({statusCode:404});
        await expect(call(inventory.syncRoomState,{roomId:5,items:[{userItemId:43}]})).rejects.toMatchObject({statusCode:404});
        expect(await placed()).toEqual(before);
        await pool.query('DELETE FROM user_rooms WHERE id=5');
        expect(await placed()).toEqual([]);
        expect((await pool.query('SELECT FROM user_items')).rowCount).toBe(3);
    });
    it('repeated catalog seeding keeps historical IDs, inventory, and placement', async () => {
        await pool.query(`INSERT INTO items(id,name,type,slot_type,asset_path) VALUES(700,'Historical cabinet','furniture','cabinet','legacy.png'),
                (850,'Historical desk','furniture','desk','assets/images/furniture/desk_0.webp');
            INSERT INTO user_rooms(id,user_id,room_type) VALUES(8,1,'exam');
            INSERT INTO user_items(user_id,item_id,is_placed,placed_at_room_id,placed_at_slot) VALUES(1,700,true,8,'cabinet')`);
        await seedGoldCatalog();
        await seedGoldCatalog();
        const {rows} = await pool.query('SELECT name,is_placed,placed_at_room_id FROM user_items JOIN items ON items.id=user_items.item_id');
        expect(rows).toEqual([{name:'Historical cabinet',is_placed:true,placed_at_room_id:8}]);
        expect((await pool.query('SELECT FROM items WHERE id=19')).rowCount).toBe(1);
        const rug = await pool.query("SELECT id FROM items WHERE asset_path='assets/images/furniture/rug_0.webp'");
        expect(rug.rowCount).toBe(1);
        expect(rug.rows[0].id).toBeGreaterThan(850);
        const desk = await pool.query("SELECT id FROM items WHERE asset_path='assets/images/furniture/desk_0.webp'");
        expect(desk.rows).toEqual([{id:850}]);
    });
    it('credits a real like recipient once and rolls back missing recipients', async () => {
        await expect(call(social.likeRoom,{targetUserId:50})).rejects.toMatchObject({statusCode:404});
        expect((await pool.query('SELECT FROM room_likes')).rowCount).toBe(0);
        await call(social.likeRoom,{targetUserId:1},2);
        await expect(call(social.likeRoom,{targetUserId:1},2)).rejects.toMatchObject({statusCode:400});
        expect(await balance()).toBe(205);
    });
});
