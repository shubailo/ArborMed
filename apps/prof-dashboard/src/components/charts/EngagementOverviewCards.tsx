import React from 'react';

interface EngagementOverview {
    avgDailyQuestions: number;
    avgDailyRewardPoints: number;
    totalPurchases: number;
    roomCustomizationRate: number;
}

interface EngagementOverviewCardsProps {
    data: EngagementOverview;
}

export const EngagementOverviewCards: React.FC<EngagementOverviewCardsProps> = ({ data }) => {
    const metrics = [
        { label: "Questions / Day", value: data.avgDailyQuestions, color: "text-blue-600", bg: "bg-blue-50" },
        { label: "Reward Pts / Day", value: data.avgDailyRewardPoints, color: "text-teal-600", bg: "bg-teal-50" },
        { label: "Total Shop Sales", value: data.totalPurchases, color: "text-amber-600", bg: "bg-amber-50" },
        { label: "Room Customization", value: `${Math.round(data.roomCustomizationRate * 100)}%`, color: "text-purple-600", bg: "bg-purple-50" },
    ];

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {metrics.map((m) => (
                <div key={m.label} className={`p-6 rounded-2xl ${m.bg} border border-white/50 backdrop-blur-sm shadow-sm`}>
                    <p className="text-[11px] uppercase font-black text-slate-400 mb-2 tracking-wider">{m.label}</p>
                    <p className={`text-3xl font-black ${m.color}`}>{m.value}</p>
                </div>
            ))}
        </div>
    );
};
