"use client";

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';

export interface AnalyticsData {
    avgReadiness: number;
    weakTopics: { id: string; name: string; score: number }[];
    correctnessRate: number;
    students: { id: string; email: string; readiness: number; risk: boolean }[];
}

export default function CourseOverview() {
    const { courseId } = useParams();
    const [data, setData] = useState<AnalyticsData | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchAnalytics() {
            try {
                const response = await fetch(`http://localhost:3000/analytics/course/${courseId}/overview`);
                const result = await response.json();
                setData(result);
            } catch (error) {
                console.error('Failed to fetch analytics:', error);
            } finally {
                setLoading(false);
            }
        }
        if (courseId) fetchAnalytics();
    }, [courseId]);

    if (loading) return <div className="p-8">Loading Analytics...</div>;

    return (
        <div className="p-8 max-w-5xl mx-auto bg-slate-50 min-h-screen">
            <div className="flex justify-between items-end mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-slate-900 mb-1">Course: {courseId}</h1>
                    <p className="text-slate-500">Instructor Insights & Student Readiness</p>
                </div>
                <div className="flex gap-4">
                    <div className="bg-white px-4 py-2 rounded-lg shadow-sm border border-slate-200">
                        <p className="text-xs text-slate-400 uppercase font-bold">Avg Readiness</p>
                        <p className="text-2xl font-black text-teal-600">{data.avgReadiness}%</p>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
                {/* Statistics Cards */}
                <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
                        <h3 className="text-sm font-bold text-slate-400 mb-4 uppercase">Weak Topics</h3>
                        <ul className="space-y-3">
                            {data.weakTopics.map((topic) => (
                                <li key={topic.id} className="flex justify-between items-center p-3 bg-red-50 rounded-xl">
                                    <span className="text-sm font-semibold text-red-900">{topic.name}</span>
                                    <span className="text-xs font-bold text-red-400">{Math.round(topic.score * 40)}% Mastery</span>
                                </li>
                            ))}
                        </ul>
                    </div>
                    <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
                        <h3 className="text-sm font-bold text-slate-400 mb-4 uppercase">Overall Correctness</h3>
                        <div className="flex items-center justify-center h-24">
                            <span className="text-5xl font-black text-blue-600">{data.correctnessRate}</span>
                        </div>
                    </div>
                </div>

                {/* Student Risk List */}
                <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
                    <h3 className="text-sm font-bold text-slate-400 mb-4 uppercase">Student Roster</h3>
                    <div className="space-y-4 max-h-[400px] overflow-y-auto pr-2">
                        {data.students.map((student) => (
                            <div key={student.id} className="flex items-center justify-between p-3 border-b border-slate-50 last:border-0">
                                <div className="min-w-0">
                                    <p className="text-sm font-bold text-slate-800 truncate">{student.email}</p>
                                    <p className="text-xs text-slate-400">Score: {student.readiness}%</p>
                                </div>
                                {student.risk && (
                                    <span className="px-2 py-0.5 rounded-full bg-red-100 text-red-600 text-[10px] font-black uppercase">At Risk</span>
                                )}
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
