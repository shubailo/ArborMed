const economy = require('../../../src/services/economyService');
const client = {query: jest.fn()};
beforeEach(() => client.query.mockReset());
test('rejects unknown quests before consulting the ledger', async () => {
  await expect(economy.processQuestClaim(client, 12, 'unknown')).rejects.toMatchObject({statusCode:400});
  expect(client.query).not.toHaveBeenCalled();
});
test('requires recorded progress before granting a daily reward', async () => {
  client.query.mockResolvedValueOnce({rows:[{daily_1:0, daily_2:0, daily_3:0, claimed:[], date:'2026-11-25'}]});
  await expect(economy.processQuestClaim(client, 12, 'daily_2')).rejects.toMatchObject({statusCode:409});
  expect(client.query).toHaveBeenCalledTimes(1);
});
test('uses the canonical daily event and amount for new and legacy clients', async () => {
  client.query.mockResolvedValueOnce({rows:[{daily_1:5, daily_2:5, daily_3:0, claimed:[], date:'2026-11-25'}]})
    .mockResolvedValueOnce({rowCount:1}).mockResolvedValueOnce({rows:[{coins:25}]});
  expect(await economy.processQuestClaim(client, 12, 'daily_2_1700000000000', 500)).toMatchObject({newBalance:25});
  expect(client.query.mock.calls[1][1]).toEqual([12,'daily_2_2026-11-25']);
  expect(client.query.mock.calls[2][1]).toEqual([20,12]);
});
