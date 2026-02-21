"use client";

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { MasteryOverTimeChart } from '@/components/charts/MasteryOverTimeChart';
import { TopicBloomBreakdownChart } from '@/components/charts/TopicBloomBreakdownChart';
import { EngagementOverviewCards } from '@/components/charts/EngagementOverviewCards';
import { RetentionOverTimeChart } from '@/components/charts/RetentionOverTimeChart';
import { BloomUsageSummaryChart } from '@/components/charts/BloomUsageSummaryChart';

export interface AnalyticsData {
    avgReadiness: number;
    weakTopics: { id: string; name: string; score: number }[];
    correctnessRate: string;
    students: { id: string; email: string; readiness: number; risk: boolean }[];
}

export interface MasteryPoint {
    date: string;
    avgMastery: number;
}

export interface TopicBloomStat {
    topicId: string;
    topicName: string;
    bloomLevel: number;
    correctRate: number;
    avgMastery: number;
}

export interface EngagementOverview {
    avgDailyQuestions: number;
    avgDailyRewardPoints: number;
    totalPurchases: number;
    roomCustomizationRate: number;
}

export interface RetentionPoint {
    date: string;
    actualRetention: number;
}

export interface BloomUsageSummary {
    bloomLevel: number;
    questionCount: number;
    avgMastery: number;
}

export default function CourseOverview() {
    const { courseId } = useParams();
    const [overview, setOverview] = useState<AnalyticsData | null>(null);
    const [masteryData, setMasteryData] = useState<MasteryPoint[]>([]);
    const [bloomData, setBloomData] = useState<TopicBloomStat[]>([]);
    const [engagement, setEngagement] = useState<EngagementOverview | null>(null);
    const [retentionData, setRetentionData] = useState<RetentionPoint[]>([]);
    const [bloomSummary, setBloomSummary] = useState<BloomUsageSummary[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchAllData() {
            try {
                const [overviewRes, masteryRes, bloomRes, engagementRes, retentionRes, bloomSummaryRes] = await Promise.all([
                    fetch(`http://localhost:3000/analytics/course/${courseId}/overview`),
                    fetch(`http://localhost:3000/analytics/course/${courseId}/mastery-over-time`),
                    fetch(`http://localhost:3000/analytics/course/${courseId}/topic-bloom-breakdown`),
                    fetch(`http://localhost:3000/analytics/course/${courseId}/engagement`),
                    fetch(`http://localhost:3000/analytics/course/${courseId}/retention-over-time`),
                    fetch(`http://localhost:3000/analytics/course/${courseId}/bloom-usage-summary`)
                ]);

                const [overviewData, masteryPoints, bloomStats, engagementData, retentionPoints, bloomSummaryData] = await Promise.all([
                    overviewRes.json(),
                    masteryRes.json(),
                    bloomRes.json(),
                    engagementRes.json(),
                    retentionRes.json(),
                    bloomSummaryRes.json()
                ]);

                setOverview(overviewData);
                setMasteryData(masteryPoints || []);
                setBloomData(bloomStats || []);
                setEngagement(engagementData);
                setRetentionData(retentionPoints || []);
                setBloomSummary(bloomSummaryData || []);
            } catch (error) {
                console.error('Failed to fetch analytics:', error);
            } finally {
                setLoading(false);
            }
        }
        if (courseId) fetchAllData();
    }, [courseId]);

    if (loading) return (
        <div className="p-8 min-h-screen bg-slate-50 flex items-center justify-center">
            <div className="text-center">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600 mx-auto mb-4"></div>
                <p className="text-slate-500 font-bold uppercase tracking-widest text-xs">Loading Analytics 2.0...</p>
            </div>
        </div>
    );

    if (!overview) return (
        <div className="p-8 max-w-5xl mx-auto bg-slate-50 min-h-screen">
            <h1 className="text-3xl font-bold text-slate-900 mb-4">Course: {courseId}</h1>
            <div className="p-6 bg-red-50 border border-red-200 rounded-xl">
                <p className="text-red-800 font-semibold text-lg">Failed to load analytics</p>
                <p className="text-red-600">Please check if the backend server is running and try again.</p>
            </div>
        </div>
    );

    return (
        <div className="p-8 max-w-7xl mx-auto bg-slate-50 min-h-screen">
            {/* Header */}
            <div className="flex justify-between items-end mb-10">
                <div>
                    <h1 className="text-4xl font-black text-slate-900 mb-2">Analytics 2.0</h1>
                    <p className="text-slate-500 font-medium">Insights for <span className="text-teal-600 font-bold">{courseId}</span></p>
                </div>
                <div className="flex gap-4">
                    <div className="bg-white px-6 py-3 rounded-2xl shadow-sm border border-slate-100">
                        <p className="text-[10px] text-slate-400 uppercase font-black tracking-widest mb-1">Avg Readiness</p>
                        <p className="text-3xl font-black text-teal-600">{overview.avgReadiness}%</p>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
                {/* Mastery Over Time Section */}
                <div className="bg-white p-8 rounded-3xl shadow-sm border border-slate-100">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-xl font-black text-slate-800 uppercase tracking-tight">Mastery Growth</h2>
                        <span className="px-3 py-1 bg-teal-50 text-teal-700 text-[10px] font-black rounded-full uppercase">Entire Course</span>
                    </div>
                    <MasteryOverTimeChart data={masteryData} />
                </div>

                {/* Retention Over Time Section */}
                <div className="bg-white p-8 rounded-3xl shadow-sm border border-slate-100">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-xl font-black text-slate-800 uppercase tracking-tight">Actual Retention</h2>
                        <span className="px-3 py-1 bg-emerald-50 text-emerald-700 text-[10px] font-black rounded-full uppercase">Last 30 Days</span>
                    </div>
                    <RetentionOverTimeChart data={retentionData} />
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                {/* Topic Breakdown Section */}
                <div className="lg:col-span-8 space-y-8">
                    <div className="bg-white p-8 rounded-3xl shadow-sm border border-slate-100">
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-black text-slate-800 uppercase tracking-tight">Topic & Bloom Breakdown</h2>
                        </div>
                        <TopicBloomBreakdownChart data={bloomData} />
                    </div>

                    <div className="bg-white p-8 rounded-3xl shadow-sm border border-slate-100">
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-black text-slate-800 uppercase tracking-tight">Bloom Usage & Mastery</h2>
                        </div>
                        <BloomUsageSummaryChart data={bloomSummary} />
                    </div>
                </div>

                {/* Engagement & Roster Section */}
                <div className="lg:col-span-4 space-y-8">
                    {/* Engagement Metrics */}
                    <div className="bg-white p-8 rounded-3xl shadow-sm border border-slate-100">
                        <h2 className="text-xl font-black text-slate-800 uppercase tracking-tight mb-6">Engagement</h2>
                        {engagement && <EngagementOverviewCards data={engagement} />}
                    </div>

                    {/* Student Roster */}
                    <div className="bg-white p-8 rounded-3xl shadow-sm border border-slate-100">
                        <h2 className="text-xl font-black text-slate-800 uppercase tracking-tight mb-6">Student Roster</h2>
                        <div className="space-y-4 max-h-[300px] overflow-y-auto pr-2 custom-scrollbar">
                            {overview.students.map((student) => (
                                <div key={student.id} className="flex items-center justify-between p-4 bg-slate-50 rounded-2xl transition-all hover:bg-slate-100 group">
                                    <div className="min-w-0">
                                        <p className="text-sm font-bold text-slate-800 truncate">{student.email}</p>
                                        <div className="flex items-center gap-2">
                                            <div className="w-16 h-1.5 bg-slate-200 rounded-full overflow-hidden">
                                                <div
                                                    className={`h-full ${student.readiness < 50 ? 'bg-red-500' : 'bg-teal-500'}`}
                                                    style={{ width: `${student.readiness}%` }}
                                                />
                                            </div>
                                            <span className="text-[10px] font-black text-slate-400">{student.readiness}%</span>
                                        </div>
                                    </div>
                                    {student.risk && (
                                        <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse" title="At Risk" />
                                    )}
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
