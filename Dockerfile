# Clone OpenFrontIO and use their Dockerfile
FROM alpine/git AS clone
WORKDIR /clone
ARG OPENFRONTIO_REPO=https://github.com/openfrontio/OpenFrontIO.git
RUN git clone ${OPENFRONTIO_REPO} .

# Use OpenFrontIO's multi-stage build (without cloudflared)
FROM node:24-slim AS base
WORKDIR /usr/src/app

# Build stage - install ALL dependencies and build
FROM base AS build
ENV HUSKY=0

# Install build dependencies for canvas and other native modules
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    pkg-config \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=clone /clone/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

# Copy only what's needed for build
COPY --from=clone /clone/tsconfig.json ./
COPY --from=clone /clone/vite.config.ts ./
COPY --from=clone /clone/tailwind.config.js ./
COPY --from=clone /clone/postcss.config.js ./
COPY --from=clone /clone/eslint.config.js ./
COPY --from=clone /clone/index.html ./
COPY --from=clone /clone/resources ./resources
COPY --from=clone /clone/proprietary ./proprietary
COPY --from=clone /clone/src ./src

ARG GIT_COMMIT=unknown
ENV GIT_COMMIT="$GIT_COMMIT"
RUN npm run build-prod

# Production dependencies stage
FROM base AS prod-deps
ENV HUSKY=0
ENV NPM_CONFIG_IGNORE_SCRIPTS=1
COPY --from=clone /clone/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

# Final production image
FROM base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    curl \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Update worker_connections in nginx.conf
RUN sed -i 's/worker_connections [0-9]*/worker_connections 8192/' /etc/nginx/nginx.conf

# Setup supervisor configuration
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy Nginx configuration
COPY --from=clone /clone/nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -f /etc/nginx/sites-enabled/default

# Copy and make executable the startup script
COPY startup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup.sh

# Copy production node_modules from prod-deps stage
COPY --from=prod-deps /usr/src/app/node_modules ./node_modules
COPY --from=clone /clone/package*.json ./

# Copy built artifacts from build stage
COPY --from=build /usr/src/app/static ./static

COPY --from=clone /clone/resources ./resources

# Remove maps because they are not used by the server
RUN rm -rf ./resources/maps
COPY --from=clone /clone/tsconfig.json ./
COPY --from=clone /clone/src ./src

ARG GIT_COMMIT=unknown
RUN echo "$GIT_COMMIT" > static/commit.txt

ENV GIT_COMMIT="$GIT_COMMIT"

# Use the startup script as the entrypoint
ENTRYPOINT ["/usr/local/bin/startup.sh"]
