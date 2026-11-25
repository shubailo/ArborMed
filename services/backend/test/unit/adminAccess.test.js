const { isSuperAdmin } = require('../../src/utils/adminPrivileges');

describe('configured administrative capabilities', () => {
    const previousId = process.env.SUPER_ADMIN_USER_ID;
    const previousEmail = process.env.SUPER_ADMIN_EMAIL;
    afterAll(() => {
        if (previousId === undefined) delete process.env.SUPER_ADMIN_USER_ID;
        else process.env.SUPER_ADMIN_USER_ID = previousId;
        if (previousEmail === undefined) delete process.env.SUPER_ADMIN_EMAIL;
        else process.env.SUPER_ADMIN_EMAIL = previousEmail;
    });
    test('only the configured administrator receives the management capability', () => {
        process.env.SUPER_ADMIN_USER_ID = '42';
        process.env.SUPER_ADMIN_EMAIL = 'old-admin@example.org';
        expect(isSuperAdmin({ role: 'admin', id: 42 })).toBe(true);
        expect(isSuperAdmin({ role: 'student', id: 42 })).toBe(false);
        expect(isSuperAdmin({ role: 'admin', id: 41, email: 'old-admin@example.org' })).toBe(false);
        delete process.env.SUPER_ADMIN_USER_ID;
        expect(isSuperAdmin({ role: 'admin', id: 41, email: 'old-admin@example.org' })).toBe(true);
        delete process.env.SUPER_ADMIN_EMAIL;
        expect(isSuperAdmin({ role: 'admin', id: 41 })).toBe(false);
    });
});
