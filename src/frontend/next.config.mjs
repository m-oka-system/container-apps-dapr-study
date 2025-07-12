/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  experimental: {
    serverActions: {
      allowedOrigins: [
        process.env.CUSTOM_DOMAIN,
        `*.${process.env.CUSTOM_DOMAIN}`,
        `${process.env.CUSTOM_DOMAIN}:443`,
        `*.${process.env.CUSTOM_DOMAIN}:443`,
      ],
    },
  },
};

export default nextConfig;
