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

# =========================
# Nhận các biến môi trường truyền từ bên ngoài Docker build
# =========================
ARG BASE_URL
ARG WS_URL

# Build Flutter Web (release)
# Nhúng giá trị API & WebSocket URL vào app
RUN flutter build web --release \
    --dart-define=BASE_URL=${BASE_URL} \
    --dart-define=WS_URL=${WS_URL}

# =========================
# 2️⃣ Stage chạy Nginx
# =========================
FROM nginx:stable-alpine

# Xóa cấu hình default của Nginx để tránh xung đột
RUN rm /etc/nginx/conf.d/default.conf

# Sao chép cấu hình nginx tùy chỉnh từ dự án (nếu có)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Sao chép Flutter web build từ stage trước
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose cổng 80
EXPOSE 80

# Chạy nginx ở foreground
CMD ["nginx", "-g", "daemon off;"]
