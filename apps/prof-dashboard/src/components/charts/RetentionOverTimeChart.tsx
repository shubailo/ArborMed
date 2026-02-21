import React from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceArea } from 'recharts';

interface RetentionPoint {
    date: string;
    actualRetention: number;
}

interface RetentionOverTimeChartProps {
    data: RetentionPoint[];
}

export const RetentionOverTimeChart: React.FC<RetentionOverTimeChartProps> = ({ data }) => {
    return (
        <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                    <defs>
                        <linearGradient id="colorRetention" x1="0" y1="0" x2="0" y2="1">
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
                        domain={[0, 1]}
                        tickFormatter={(val) => `${(val * 100).toFixed(0)}%`}
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
                        formatter={(value: any) => [`${(Number(value || 0) * 100).toFixed(1)}%`, 'Actual Retention']}
                    />
                    {/* Shaded Reference Area for Target Band (85-90%) */}
                    <ReferenceArea
                        y1={0.85}
                        y2={0.90}
                        fill="#10b981"
                        fillOpacity={0.1}
                        label={{ position: 'right', value: 'Target', fill: '#059669', fontSize: 10, fontWeight: 'bold' }}
                    />
                    <Area
                        type="monotone"
                        dataKey="actualRetention"
                        stroke="#0d9488"
                        strokeWidth={3}
                        fillOpacity={1}
                        fill="url(#colorRetention)"
                    />
                </AreaChart>
            </ResponsiveContainer>
        </div>
    );
};
