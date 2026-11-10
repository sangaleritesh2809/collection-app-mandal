# ==============================================================================
# Ultra-Fast Lightweight Web Server for Flutter Web & Privacy Policy on Render
# Image size: ~15MB (Build time on Render: ~10 seconds)
# ==============================================================================
FROM nginx:alpine

# Copy pre-compiled Flutter Web production build
COPY web_build /usr/share/nginx/html

# Explicitly ensure privacy policy files are in place
COPY privacy_policy.html /usr/share/nginx/html/privacy_policy.html

# Copy Nginx SPA routing configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
