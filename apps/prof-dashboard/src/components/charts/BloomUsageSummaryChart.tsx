import React from 'react';
import {
    ComposedChart,
    Bar,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    Legend,
    ResponsiveContainer,
    Cell
} from 'recharts';

interface BloomUsageSummaryPoint {
    bloomLevel: number;
    questionCount: number;
    avgMastery: number;
}

interface BloomUsageSummaryChartProps {
    data: BloomUsageSummaryPoint[];
}

const bloomNames = [
    '',
    'Remember',
    'Understand',
    'Apply',
    'Analyze',
    'Evaluate',
    'Create'
];

export const BloomUsageSummaryChart: React.FC<BloomUsageSummaryChartProps> = ({ data }) => {
    // Ensure all 6 levels are present and sorted
    const sortedData = [...data].sort((a, b) => a.bloomLevel - b.bloomLevel);

    const colors = ["#94a3b8", "#64748b", "#475569", "#334155", "#1e293b", "#0f172a"];

    return (
        <div className="h-[400px] w-full">
            <ResponsiveContainer width="100%" height="100%">
                <ComposedChart data={sortedData} margin={{ top: 20, right: 30, left: 20, bottom: 20 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                    <XAxis
                        dataKey="bloomLevel"
                        stroke="#475569"
                        fontSize={12}
                        tickLine={false}
                        axisLine={false}
                        tickFormatter={(val) => bloomNames[val] || val}
                    />
                    {/* Primary Y-axis: Question Count */}
                    <YAxis
                        yAxisId="left"
                        stroke="#94a3b8"
                        fontSize={12}
                        tickLine={false}
                        axisLine={false}
                        label={{ value: 'Question Count', angle: -90, position: 'insideLeft', offset: 0, fill: '#94a3b8', fontSize: 10, fontWeight: 'bold' }}
                    />
                    {/* Secondary Y-axis: Avg Mastery */}
                    <YAxis
                        yAxisId="right"
                        orientation="right"
                        stroke="#0d9488"
                        fontSize={12}
                        tickLine={false}
                        axisLine={false}
                        domain={[0, 100]}
                        tickFormatter={(val) => `${val}%`}
                        label={{ value: 'Avg Mastery', angle: 90, position: 'insideRight', offset: 0, fill: '#0d9488', fontSize: 10, fontWeight: 'bold' }}
                    />
                    <Tooltip
                        contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                        formatter={(value, name) => {
                            if (name === 'avgMastery') return [`${value}%`, 'Average Mastery'];
                            return [value, 'Questions'];
                        }}
                        labelFormatter={(label) => bloomNames[label] || `Level ${label}`}
                    />
                    <Legend verticalAlign="top" height={36} />
                    <Bar
                        yAxisId="left"
                        dataKey="questionCount"
                        name="Questions"
                        fill="#cbd5e1"
                        radius={[4, 4, 0, 0]}
                        barSize={40}
                    >
                        {sortedData.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={colors[entry.bloomLevel - 1] || "#cbd5e1"} />
                        ))}
                    </Bar>
                    <Line
                        yAxisId="right"
                        type="monotone"
                        dataKey="avgMastery"
                        name="Average Mastery"
                        stroke="#0d9488"
                        strokeWidth={3}
                        dot={{ r: 4, fill: '#0d9488', strokeWidth: 2, stroke: '#fff' }}
                        activeDot={{ r: 6 }}
                    />
                </ComposedChart>
            </ResponsiveContainer>
        </div>
    );
};
