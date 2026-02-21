import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaLibSql } from '@prisma/adapter-libsql';
import path from 'path';

let dbUrl = process.env.DATABASE_URL;
if (!dbUrl) {
    dbUrl = `file:${path.resolve(__dirname, '../dev.db')}`;
}

// Convert backslashes for Windows path format issues in LibSQL
dbUrl = dbUrl.replace(/\\/g, '/');

console.log('DEBUG: Connecting to DB URL:', dbUrl);

const adapter = new PrismaLibSql({
    url: dbUrl
});

const prisma = new PrismaClient({ adapter, log: ['error', 'warn'] });

export default prisma;
