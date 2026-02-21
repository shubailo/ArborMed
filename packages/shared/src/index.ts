export const VERSION = '1.0.0';

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
