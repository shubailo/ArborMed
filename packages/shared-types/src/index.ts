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
    bloomLevel: 1 | 2 | 3 | 4;
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
