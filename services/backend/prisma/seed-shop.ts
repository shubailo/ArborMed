import prisma from '../src/db';

async function seedShop() {
    console.log('Seeding ShopItems...');

    const items = [
        {
            key: 'plant_fern_01',
            name: 'Cozy Fern',
            description: 'A beautiful green fern to brighten up your study space.',
            price: 20,
            category: 'room_item',
            isActive: true
        },
        {
            key: 'lamp_desk_01',
            name: 'Retro Desk Lamp',
            description: 'Classic warm lighting for late-night anatomy sessions.',
            price: 50,
            category: 'room_item',
            isActive: true
        },
        {
            key: 'poster_skeleton_01',
            name: 'Anatomy Poster',
            description: 'A detailed skeletal map to help you memorize every bone.',
            price: 35,
            category: 'room_item',
            isActive: true
        },
        {
            key: 'coffee_mug_01',
            name: 'Endless Coffee Mug',
            description: 'Essential for survival during exam weeks.',
            price: 15,
            category: 'room_item',
            isActive: true
        }
    ];

    for (const item of items) {
        await prisma.shopItem.upsert({
            where: { key: item.key },
            update: item,
            create: item
        });
        console.log(`- Seeded ${item.name}`);
    }

    console.log('Shop seeding complete!');
}

seedShop()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
