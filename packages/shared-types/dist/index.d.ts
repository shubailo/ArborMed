export type UserRole = 'student' | 'admin' | 'professor';
export interface User {
    id: number;
    email: string;
    username: string;
    display_name: string;
    role: UserRole;
    coins: number;
    xp: number;
    level: number;
    streak_count: number;
    longest_streak: number;
    is_email_verified: boolean;
    created_at?: Date;
    updated_at?: Date;
}
export interface Question {
    id: number;
    topic_id: number;
    type: string;
    question_type: string;
    bloom_level: number;
    difficulty: number;
    question_text_en: string;
    question_text_hu: string;
    explanation_en: string;
    explanation_hu: string;
    correct_answer: any;
    options: any;
    active: boolean;
    created_at?: Date;
    updated_at?: Date;
}
export interface Topic {
    id: number;
    parent_id: number | null;
    slug: string;
    name_en: string;
    name_hu: string;
    question_count?: number;
}
export interface QuizSession {
    id: number;
    user_id: number;
    started_at: Date;
    completed_at: Date | null;
    score?: number;
}
