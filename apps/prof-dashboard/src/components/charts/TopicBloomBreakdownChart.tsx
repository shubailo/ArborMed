import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

interface TopicBloomStat {
    topicId: string;
    topicName: string;
    bloomLevel: number;
    correctRate: number;
    avgMastery: number;
}

interface TopicBloomBreakdownChartProps {
    data: TopicBloomStat[];
}

export const TopicBloomBreakdownChart: React.FC<TopicBloomBreakdownChartProps> = ({ data }) => {
    // Transform data for stacked chart
    const transformedData = data.reduce((acc: any[], curr) => {
        let topic = acc.find(t => t.topicName === curr.topicName);
        if (!topic) {
            topic = { topicName: curr.topicName };
            acc.push(topic);
        }
        topic[`Bloom ${curr.bloomLevel}`] = curr.correctRate;
        return acc;
    }, []);

    const colors = ["#94a3b8", "#64748b", "#334155", "#0f172a"]; // Shades for Bloom levels

    return (
        <div className="h-[400px] w-full">
            <ResponsiveContainer width="100%" height="100%">
                <BarChart data={transformedData} layout="vertical" margin={{ left: 20, right: 30 }}>
                    <CartesianGrid strokeDasharray="3 3" horizontal={true} vertical={false} stroke="#e2e8f0" />
                    <XAxis type="number" domain={[0, 100]} hide />
                    <YAxis
                        dataKey="topicName"
                        type="category"
                        stroke="#475569"
                        fontSize={12}
                        width={120}
                        tickLine={false}
                        axisLine={false}
                    />
                    <Tooltip
                        cursor={{ fill: '#f8fafc' }}
                        contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                        formatter={(value) => [`${value}% Accuracy`]}
                    />
                    <Legend iconType="circle" />
                    {[1, 2, 3, 4].map((level) => (
                        <Bar
                            key={level}
                            name={`Bloom ${level}`}
                            dataKey={`Bloom ${level}`}
                            stackId="a"
                            fill={colors[level - 1]}
                            radius={0}
                        />
                    ))}
                </BarChart>
            </ResponsiveContainer>
        </div>
    );
};
