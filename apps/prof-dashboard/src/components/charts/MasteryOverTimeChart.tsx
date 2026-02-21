import React from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

interface MasteryOverTimeChartProps {
    data: { date: string; avgMastery: number }[];
}

export const MasteryOverTimeChart: React.FC<MasteryOverTimeChartProps> = ({ data }) => {
    return (
        <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                    <defs>
                        <linearGradient id="colorMastery" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#0d9488" stopOpacity={0.1} />
                            <stop offset="95%" stopColor="#0d9488" stopOpacity={0} />
                        </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                    <XAxis
                        dataKey="date"
                        stroke="#94a3b8"
                        fontSize={12}
                        tickLine={false}
                        axisLine={false}
                        tickFormatter={(str) => {
                            try {
                                return new Date(str).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
                            } catch (e) {
                                return str;
                            }
                        }}
                    />
                    <YAxis
                        stroke="#94a3b8"
                        fontSize={12}
                        tickLine={false}
                        axisLine={false}
                        domain={[0, 100]}
                        tickFormatter={(val) => `${val}%`}
                    />
                    <Tooltip
                        contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                        labelFormatter={(label) => {
                            try {
                                return new Date(label).toLocaleDateString(undefined, { dateStyle: 'long' });
                            } catch (e) {
                                return label;
                            }
                        }}
                    />
                    <Area
                        type="monotone"
                        dataKey="avgMastery"
                        stroke="#0d9488"
                        strokeWidth={3}
                        fillOpacity={1}
                        fill="url(#colorMastery)"
                    />
                </AreaChart>
            </ResponsiveContainer>
        </div>
    );
};
