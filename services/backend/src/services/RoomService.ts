import { prisma } from '../db';
import { Prisma } from '@prisma/client';

export class RoomService {
    // ... rest of the same code but with Prisma.TransactionClient for tx ...
    // Mapping of slots to allowed categories
    private static SLOT_CATEGORIES: Record<string, string[]> = {
        'wall_left': ['poster', 'wall_decor'],
        'wall_right': ['poster', 'wall_decor'],
        'desk_main': ['tech', 'stationary', 'lamp'],
        'floor_corner': ['furniture', 'plant'],
        'floor_center': ['furniture', 'plant'],
    };

    /**
     * Get user room state
     */
    static async getRoomState(userId: string) {
        return await prisma.userRoomItem.findMany({
            where: { userId },
            include: {
                shopItem: true
            }
        });
    }

    /**
     * Place an item in a slot (Usage Mode)
     */
    static async placeItem(userId: string, slotKey: string, shopItemId: string) {
        // 1. Get Item info
        const item = await prisma.shopItem.findUnique({
            where: { id: shopItemId }
        });

        if (!item) throw new Error('Item not found');

        // 2. Validate Slot Category
        const allowedCategories = this.SLOT_CATEGORIES[slotKey];
        if (!allowedCategories) throw new Error(`Invalid slotKey: ${slotKey}`);

        if (!allowedCategories.includes(item.category)) {
            const error: any = new Error(`Item category '${item.category}' is not allowed in slot '${slotKey}'`);
            error.errorCode = 'INVALID_ITEM_FOR_SLOT';
            throw error;
        }

        return await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
            // 3. Check Inventory (Available quantity)
            const inventory = await tx.userInventory.findUnique({
                where: { userId_shopItemId: { userId, shopItemId } }
            });

            if (!inventory || inventory.quantity <= 0) {
                const error: any = new Error('You don\'t have this item available in your inventory.');
                error.errorCode = 'NO_INVENTORY_FOR_ITEM';
                throw error;
            }

            // 4. Handle Slot Overwrite
            const existingInSlot = await tx.userRoomItem.findFirst({
                where: { userId, slotKey }
            });

            if (existingInSlot) {
                // Return old item to inventory
                await tx.userInventory.upsert({
                    where: { userId_shopItemId: { userId, shopItemId: existingInSlot.shopItemId } },
                    update: { quantity: { increment: 1 } },
                    create: { userId, shopItemId: existingInSlot.shopItemId, quantity: 1 }
                });

                // Remove old room item
                await tx.userRoomItem.delete({
                    where: { id: existingInSlot.id }
                });
            }

            // 5. Deduct new item from inventory
            await tx.userInventory.update({
                where: { userId_shopItemId: { userId, shopItemId } },
                data: { quantity: { decrement: 1 } }
            });

            // 6. Create Room Item
            const placed = await tx.userRoomItem.create({
                data: {
                    userId,
                    slotKey,
                    shopItemId
                },
                include: {
                    shopItem: true
                }
            });

            return { success: true, item: placed };
        });
    }

    /**
     * Clear a slot
     */
    static async clearSlot(userId: string, slotKey: string) {
        return await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
            const existing = await tx.userRoomItem.findFirst({
                where: { userId, slotKey }
            });

            if (!existing) return { success: true, removed: false };

            // Return to inventory
            await tx.userInventory.upsert({
                where: { userId_shopItemId: { userId, shopItemId: existing.shopItemId } },
                update: { quantity: { increment: 1 } },
                create: { userId, shopItemId: existing.shopItemId, quantity: 1 }
            });

            // Delete record
            await tx.userRoomItem.delete({
                where: { id: existing.id }
            });

            return { success: true, removed: true };
        });
    }
}
