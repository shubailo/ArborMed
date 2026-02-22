/** @type {import('next').NextConfig} */
const nextConfig = {
    // Enable workspace support for shared packages if needed
    transpilePackages: ["@arbormed/shared-types"]
};

export default nextConfig;
