# ---- Builder Stage ----
FROM node:lts-alpine AS builder

WORKDIR /usr/src/app

COPY package.json package-lock.json* npm-shrinkwrap.json* ./
RUN npm ci --silent

COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ---- Runner Stage ----
FROM node:lts-alpine

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED 1
ENV HOST=0.0.0.0
WORKDIR /usr/src/app

RUN addgroup -g 1001 -S nodejs && \
  adduser -S nextjs -u 1001 -G nodejs

COPY --from=builder --chown=nextjs:nodejs /usr/src/app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /usr/src/app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
