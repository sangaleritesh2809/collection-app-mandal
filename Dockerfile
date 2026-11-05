# ==============================================================================
# Multi-Stage Dockerfile for Flutter Web on Render
# ==============================================================================

# Stage 1: Build the Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Arguments for environment configuration
ARG SUPABASE_URL=https://qdipaztpwcfbgktajkyz.supabase.co
ARG SUPABASE_ANON_KEY=sb_publishable_szI_G_sLgUsqWgs_60iaPQ_HpO0r3RV

# Copy dependency files
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and configuration
COPY . .

# Generate .env file for Flutter asset bundling if not present
RUN if [ ! -f .env ]; then \
      printf "SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\n" "$SUPABASE_URL" "$SUPABASE_ANON_KEY" > .env; \
    fi

# Build Flutter Web in release mode
RUN flutter build web --release

# Stage 2: Serve using lightweight Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

