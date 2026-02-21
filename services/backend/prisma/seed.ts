import prisma from '../src/db';
import fs from 'fs';
import path from 'path';

async function main() {
    console.log('🌱 Seeding database...');

    // 1. Create Organization
    const org = await prisma.organization.upsert({
        where: { id: 'med-uni-01' },
        update: {},
        create: {
            id: 'med-uni-01',
            name: 'Medical University 01',
        },
    });
    console.log(`✅ Organization created: ${org.name}`);

    // 2. Create Topic
    const topic = await prisma.topic.upsert({
        where: { id: 'hematology' },
        update: {},
        create: {
            id: 'hematology',
            organizationId: org.id,
            name: 'Hematology',
        },
    });
    console.log(`✅ Topic created: ${topic.name}`);

    // 3. Load Questions from Bundle
    const bundlePath = path.join(__dirname, '../../../apps/student_app/assets/content/curriculum.bundle.json');

    if (!fs.existsSync(bundlePath)) {
        console.error('❌ Error: curriculum.bundle.json not found! Run content-engine build first.');
        return;
    }

    const questions = JSON.parse(fs.readFileSync(bundlePath, 'utf-8'));
    console.log(`📦 Loading ${questions.length} questions...`);

    for (const q of questions) {
        await prisma.question.upsert({
            where: { id: q.id },
            update: {
                status: q.status || 'PUBLISHED',
            },
            create: {
                id: q.id,
                organizationId: org.id,
                topicId: topic.id,
                bloomLevel: q.bloomLevel,
                status: q.status || 'PUBLISHED',
                content: q.content,
                explanation: q.explanation,
                options: {
                    create: q.options.map((opt: any) => ({
                        text: opt.text,
                        isCorrect: opt.isCorrect,
                    })),
                },
            },
        });
    }

    // 4. Create Mock Students
    const students = [
        { id: 'ae30193e-83b3-c392-1192-9cad0e1f2031', email: 'student1@med.edu' },
        { id: 'student-risk-01', email: 'atrisk@med.edu' }
    ];

    for (const s of students) {
        await prisma.user.upsert({
            where: { id: s.id },
            update: {},
            create: {
                id: s.id,
                email: s.email,
                organizationId: org.id,
                role: 'STUDENT'
            }
        });
    }

    console.log('🏁 Seeding complete!');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
