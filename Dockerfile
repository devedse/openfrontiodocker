# Multi-stage Dockerfile that clones and builds OpenFrontIO
FROM node:24-slim AS clone-and-build

# Install git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone OpenFrontIO repository
ARG OPENFRONTIO_REPO=https://github.com/openfrontio/OpenFrontIO.git
RUN git clone ${OPENFRONTIO_REPO} . && \
    echo "Cloned commit: $(git rev-parse HEAD)" && \
    echo "$(git rev-parse HEAD)" > /build/git-commit.txt

# Install dependencies and build
ENV HUSKY=0
RUN npm ci --ignore-scripts && \
    npm run build-prod

# Final production image - copy from OpenFrontIO's approach
FROM node:24-slim

WORKDIR /usr/src/app

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

# Copy files from build stage
COPY --from=clone-and-build /build/static ./static
COPY --from=clone-and-build /build/resources ./resources
COPY --from=clone-and-build /build/src ./src
COPY --from=clone-and-build /build/package*.json ./
COPY --from=clone-and-build /build/tsconfig.json ./
COPY --from=clone-and-build /build/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --from=clone-and-build /build/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=clone-and-build /build/startup.sh /usr/local/bin/
COPY --from=clone-and-build /build/git-commit.txt ./static/commit.txt

# Install production dependencies
ENV HUSKY=0
ENV NPM_CONFIG_IGNORE_SCRIPTS=1
RUN npm ci --omit=dev --ignore-scripts

# Remove maps because they are not used by the server
RUN rm -rf ./resources/maps

# Remove default nginx site
RUN rm -f /etc/nginx/sites-enabled/default

# Make startup script executable
RUN chmod +x /usr/local/bin/startup.sh

# Set git commit env var
ARG GIT_COMMIT=unknown
ENV GIT_COMMIT=${GIT_COMMIT}

# Use the startup script as the entrypoint
ENTRYPOINT ["/usr/local/bin/startup.sh"]
