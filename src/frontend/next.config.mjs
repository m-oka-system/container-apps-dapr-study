/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  experimental: {
    serverActions: {
      allowedOrigins: [
        process.env.CUSTOM_DOMAIN,
        `*.${process.env.CUSTOM_DOMAIN}`,
      ],
    },
  },
};

export default nextConfig;
