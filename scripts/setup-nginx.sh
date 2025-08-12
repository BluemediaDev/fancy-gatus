#!/bin/sh

# Setup nginx configuration for fancy-gatus
# This script runs at container startup to configure nginx

NGINX_CONF="/etc/nginx/conf.d/default.conf"
NGINX_CONF_DIR=$(dirname "$NGINX_CONF")

# Ensure the nginx config directory exists
mkdir -p "$NGINX_CONF_DIR"

# Set the port (default to 80 for nginx:alpine)
NGINX_PORT="${NGINX_PORT:-80}"

echo "Setting up nginx configuration on port $NGINX_PORT..."

# Create nginx configuration for fancy-gatus
cat > "$NGINX_CONF" << EOF
server {
    listen $NGINX_PORT;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # Handle SPA routing - serve index.html for all routes
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Handle static assets with caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # Handle config.json with no caching (so env changes are picked up)
    location = /config.json {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        try_files \$uri =404;
    }
    
    # Handle API proxy if GATUS_API_URL is provided
    location /api/ {
EOF

# Add API proxy configuration if GATUS_API_URL is provided
if [ -n "$GATUS_API_URL" ]; then
    cat >> "$NGINX_CONF" << EOF
        proxy_pass ${GATUS_API_URL};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers for API requests
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
EOF
else
    cat >> "$NGINX_CONF" << EOF
        return 404;
EOF
fi

cat >> "$NGINX_CONF" << EOF
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Hide nginx version
    server_tokens off;
    
    # Access logs
    access_log /var/log/nginx/access.log;
    error_log /dev/stderr warn;
}
EOF

echo "Nginx configuration created at $NGINX_CONF"
echo "Configuration contents:"
cat "$NGINX_CONF"