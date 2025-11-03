# =========================
# 1️⃣ Stage build Flutter Web
# =========================
FROM debian:stable-slim AS build

# Cài đặt dependencies cần thiết
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa chromium && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài đặt Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Kiểm tra Flutter đã cài thành công
RUN flutter --version

# Sao chép toàn bộ mã nguồn vào container
WORKDIR /app
COPY . .

# Bật chế độ web cho Flutter
RUN flutter config --enable-web

# Build Flutter Web (release)
RUN flutter build web --release --dart-define=DOCKER_ENV=true

# =========================
# 2️⃣ Stage chạy Nginx
# =========================
FROM nginx:stable-alpine

# Xóa cấu hình default của Nginx để tránh xung đột
RUN rm /etc/nginx/conf.d/default.conf

# Sao chép cấu hình nginx tùy chỉnh từ dự án
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Sao chép Flutter web build từ stage trước
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose cổng 80
EXPOSE 80

# Chạy nginx ở foreground
CMD ["nginx", "-g", "daemon off;"]
