# ============================================================================
# MULTI-STAGE DOCKERFILE - 3 ENVIRONMENTS
# ============================================================================

# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
# Fix: Remove package-lock.json and use npm install to regenerate it
RUN rm -f package-lock.json && npm install --only=production && npm cache clean --force
COPY . .

# ============================================================================
# DEVELOPMENT STAGE - Full shell access + debugging tools
# ============================================================================
FROM node:18-alpine AS development
RUN apk add --no-cache \
    curl \
    bash \
    htop \
    procps \
    net-tools \
    tcpdump \
    strace \
    vim

WORKDIR /app
COPY --from=builder /app .

RUN addgroup -g 1001 -S nodejs && \
    adduser -S shopbot -u 1001 -G nodejs && \
    chown -R shopbot:nodejs /app

USER shopbot

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000
CMD ["npm", "start"]

# ============================================================================
# STAGING STAGE - Distroless debug (minimal shell access)
# ============================================================================
FROM gcr.io/distroless/nodejs18-debian11:debug AS staging
WORKDIR /app
COPY --from=builder --chown=1001:1001 /app /app
USER 1001
EXPOSE 3000
CMD ["app.js"]

# ============================================================================
# PRODUCTION STAGE - Pure distroless (NO shell access)
# ============================================================================
FROM gcr.io/distroless/nodejs18-debian11 AS production
WORKDIR /app
COPY --from=builder --chown=1001:1001 /app /app
USER 1001
EXPOSE 3000
CMD ["app.js"]
