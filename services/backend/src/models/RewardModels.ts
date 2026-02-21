
export interface ShopItem {
    id: string;
    name: string;
    category: string;
    price: number;
    spriteKey: string;
}

export interface UserInventory {
    userId: string;
    shopItemId: string;
    quantity: number;
}

export interface UserRoomItem {
    userId: string;
    shopItemId: string;
    slotIndex: number;
}
