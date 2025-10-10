# syntax=docker/dockerfile:1

FROM oven/bun:1 AS base

# Install git for git http endpoints
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies into temp directory
# This will cache them and speed up future builds
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lockb /temp/dev/
RUN cd /temp/dev && bun install --frozen-lockfile

# Install with --production (exclude devDependencies)
RUN mkdir -p /temp/prod
COPY package.json bun.lockb /temp/prod/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# Copy node_modules from temp directory
# Then copy all project files into the image
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# Build the Next.js application
ENV NODE_ENV=production
RUN bun run build

# Copy production dependencies and built output to a lean image
FROM base AS release
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease /app/.next .next
COPY --from=prerelease /app/public public
COPY --from=prerelease /app/package.json .
COPY --from=prerelease /app/drizzle drizzle
COPY --from=prerelease /app/drizzle.config.ts .
COPY --from=prerelease /app/src/db src/db

# Create git repositories directory
RUN mkdir -p /data/repositories && chown -R bun:bun /data/repositories

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
ENV GIT_REPOS_PATH=/data/repositories

# Run the app
USER bun
CMD ["bun", "run", "start"]
