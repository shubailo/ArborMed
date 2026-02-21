import { PrismaClient } from '@prisma/client';
import { PrismaLibSql } from '@prisma/adapter-libsql';

const adapter = new PrismaLibSql({
    url: 'file:C:/Users/shuba/Desktop/Med_buddy/services/backend/dev.db'
});
const prisma = new PrismaClient({ adapter, log: ['error', 'warn'] });

async function main() {
    console.log('Testing DB connection...');
    await prisma.$queryRaw`SELECT 1`;
    console.log('✅ DB Connection Successful');

    console.log('Fetching topics...');
    const topics = await prisma.topic.findMany();
    console.log(`Found ${topics.length} topics`);
}

main()
    .catch((e) => {
        console.error('❌ Connection failed:');
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
