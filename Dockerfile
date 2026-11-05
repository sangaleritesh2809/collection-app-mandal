# ==============================================================================
# Multi-Stage Dockerfile for Flutter Web on Render
# ==============================================================================

# Stage 1: Build the Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copy dependency files
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and configuration
COPY . .

# Build Flutter Web in release mode
RUN flutter build web --release

# Stage 2: Serve using lightweight Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
