/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  experimental: {
    serverActions: {
      allowedOrigins: [
        process.env.CUSTOM_DOMAIN_NAME,
        `*.${process.env.CUSTOM_DOMAIN_NAME}`,
        `${process.env.CUSTOM_DOMAIN_NAME}:443`,
        `*.${process.env.CUSTOM_DOMAIN_NAME}:443`,
      ],
    },
  },
};

export default nextConfig;
