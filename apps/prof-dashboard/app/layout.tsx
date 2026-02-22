import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "ArborMed Professor Dashboard",
    description: "Advanced pedagogical management for ArborMed",
};

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="en">
            <body>{children}</body>
        </html>
    );
}
