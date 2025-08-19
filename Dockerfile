# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage using nginx:alpine
FROM nginx:alpine

# Copy built application to nginx webroot
COPY --from=builder /app/build /usr/share/nginx/html

# Copy configuration and auth setup scripts
COPY scripts/generate-config.sh /usr/local/bin/generate-config.sh
COPY scripts/setup-nginx.sh /usr/local/bin/setup-nginx.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/generate-config.sh /usr/local/bin/setup-nginx.sh

# Expose configurable port (default 80 for nginx:alpine)
ARG NGINX_PORT=80
ENV NGINX_PORT=${NGINX_PORT}
EXPOSE ${NGINX_PORT}

# Setup nginx config, generate frontend config, and start nginx
CMD ["/bin/sh", "-c", "/usr/local/bin/setup-nginx.sh && /usr/local/bin/generate-config.sh && nginx -g 'daemon off;'"]