import { PrismaClient } from '@prisma/client';
// @ts-ignore
const prisma = new PrismaClient({
    datasourceUrl: "file:C:/Users/shuba/Desktop/Med_buddy/services/backend/dev.db"
});
async function main() {
    console.log('Testing DB connection...');
    try {
        await prisma.$connect();
        console.log('✅ Connection successful!');
        const users = await prisma.user.findMany({ take: 1 });
        console.log('✅ Query successful, users count:', users.length);
    }
    catch (e) {
        console.error('❌ Connection failed:');
        console.error(e);
        process.exit(1);
    }
    finally {
        await prisma.$disconnect();
    }
}
main();
