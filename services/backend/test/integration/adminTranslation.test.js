const express = require('express');
const { once } = require('node:events');

jest.mock('google-translate-api-x', () => jest.fn());
jest.mock('../../src/middleware/authMiddleware', () => ({protect: (req,res,next) => next()}));

describe('editor translation over HTTP', () => {
    let provider, app, address, calls, response;
    const run = async server => {
        const listener = server.listen(0, '127.0.0.1');
        await once(listener, 'listening');
        return listener;
    };
    beforeAll(async () => {
        const libre = express();
        libre.use(express.json());
        libre.post('/translate', (req, res) => {
            calls.push(req.body);
            if (response === 'error') return res.sendStatus(503);
            if (response === 'empty') return res.json({});
            return res.json({translatedText: req.body.q + ' (' + req.body.target + ')'});
        });
        provider = await run(libre);
        jest.replaceProperty(process, 'env', {...process.env, TRANSLATION_PROVIDER:'LIBRE',
            LIBRETRANSLATE_URL:'http://127.0.0.1:' + provider.address().port});
        const api = express();
        api.use(express.json());
        api.use('/api', require('../../src/routes/translate'));
        api.use(require('../../src/middleware/errorHandler'));
        app = await run(api);
        address = 'http://127.0.0.1:' + app.address().port;
    });
    afterAll(async () => {
        for (const server of [app, provider]) if (server) await new Promise(resolve => server.close(resolve));
        jest.restoreAllMocks();
    });
    beforeEach(() => {
        calls = [];
        response = 'ok';
        require('google-translate-api-x').mockReset().mockRejectedValue(new Error('fallback offline'));
    });
    const post = (path, body) => fetch(address + '/api/translate' + path, {
        method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({from:'en',to:'hu',...body}),
    });
    test('retains every translated field, option order and empty option slots', async () => {
        const res = await post('/question', {questionData:{questionText:'Example', options:['One','','Two'], explanation:'Reason'}});
        expect(res.status).toBe(200);
        expect(await res.json()).toEqual({translatedQuestion:{questionText:'Example (hu)',options:['One (hu)','','Two (hu)'],explanation:'Reason (hu)'}});
        expect(calls).toContainEqual({q:'Example',source:'en',target:'hu',format:'text'});
    });
    test('malformed success falls back and total provider failure can be retried', async () => {
        response = 'empty';
        const failed = await post('', {text:'Blue'});
        expect(failed.status).toBe(502);
        expect((await failed.json()).message).toBeTruthy();
        require('google-translate-api-x').mockResolvedValueOnce({text:'Kék'});
        expect(await (await post('', {text:'Blue'})).json()).toEqual({translated:'Kék'});
        response='error';
        expect((await post('/question', {questionData:{options:['One']}})).status).toBe(502);
        response='ok';
        expect((await post('/question', {questionData:{options:['One']}})).status).toBe(200);
    });
    test('auto is accepted only as a source language', async () => {
        expect((await post('', {text:'Blue', from:'auto'})).status).toBe(200);
        expect(calls).toHaveLength(1);
        expect(calls[0].source).toBe('auto');
        expect((await post('/question', {questionData:{questionText:'Blue'}, to:'auto'})).status).toBe(400);
        expect(calls).toHaveLength(1);
    });
    test('invalid language tags are rejected before provider calls on both routes', async () => {
        expect((await post('', {text:'Blue', from:'bad tag'})).status).toBe(400);
        expect((await post('/question', {questionData:{questionText:'Blue'}, to:'hu\nen'})).status).toBe(400);
        expect(calls).toHaveLength(0);
        expect(require('google-translate-api-x')).not.toHaveBeenCalled();
    });
    test('invalid or empty forms never make a provider request', async () => {
        for (const questionData of [[], {}, {questionText:' '}, {questionText:'Example',options:[{}]}, {lefts:'One'}]) {
            expect((await post('/question', {questionData})).status).toBe(400);
        }
        for (const body of [{text:5}, {text:' '}, {text:'Example', from:9}]) expect((await post('', body)).status).toBe(400);
        expect(calls).toEqual([]);
    });
});
