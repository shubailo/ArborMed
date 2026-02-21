// packages/shared-types/src/index.ts

export type UserRole = 'STUDENT' | 'PROFESSOR' | 'ADMIN';
export type QuestionStatus = 'DRAFT' | 'REVIEWED' | 'PUBLISHED';

export interface User {
    id: string;
    organizationId: string;
    email: string;
    role: UserRole;
    masteryPoints: number;
}

export interface Question {
    id: string;
    topicId: string;
    organizationId: string;
    bloomLevel: 1 | 2 | 3 | 4 | 5 | 6;
    difficulty: number;
    questionType?: string;
    status: QuestionStatus;
    content: string;
    explanation: string;
    options: AnswerOption[];
}

export interface AnswerOption {
    id: string;
    text: string;
    isCorrect: boolean;
}

export interface UserMastery {
    userId: string;
    questionId: string;
    organizationId: string;
    easiness: number;
    interval: number;
    repetitions: number;
    nextReview: string; // ISO String
}

export interface UserCourseProgress {
    userId: string;
    courseId: string;
    organizationId: string;
    currentBloomLevel: number;
    streakCorrect: number;
    streakWrong: number;
}

// M3: Reward & Economy DTOs
export interface RewardBalanceDto {
    userId: string;
    balance: number;
}

export interface ShopItemDto {
    id: string;
    key: string;
    name: string;
    description?: string;
    price: number;
    category: string;
    isActive: boolean;
}

export interface PurchaseRequestDto {
    userId: string;
    shopItemId: string;
}

export interface PurchaseDto {
    id: string;
    userId: string;
    shopItemId: string;
    pricePaid: number;
    createdAt: string;
}

export interface PurchaseResponseDto {
    success: boolean;
    balance?: number;
    error?: string;
    errorCode?: string;
}

export interface UserInventoryDto {
    userId: string;
    shopItemId: string;
    quantity: number;
    shopItem?: ShopItemDto;
}

// M4: Room Customization DTOs
export interface RoomItemDto {
    id: string;
    userId: string;
    shopItemId: string;
    slotKey: string;
    shopItem: ShopItemDto;
}

export interface RoomStateDto {
    userId: string;
    items: RoomItemDto[];
}

export interface PlaceRoomItemRequestDto {
    slotKey: string;
    shopItemId: string;
}

// M7: Student Progress & Narrative UX DTOs
export type BloomLevelStateDto = {
    bloomLevel: number;      // 1–6
    masteryScore: number;    // 0–100
    achieved: boolean;       // masteryScore >= threshold
};

export type TopicProgressDto = {
    topicId: string;
    topicName: string;
    overallMastery: number;   // weighted average, 0–100
    bloomLevels: BloomLevelStateDto[];
    masteryBadge: 'FOUNDATION' | 'APPLICATION' | 'ADVANCED' | 'EXPERT' | 'NONE';
};

export type CourseProgressDto = {
    courseId: string;
    userId: string;
    topics: TopicProgressDto[];
};
