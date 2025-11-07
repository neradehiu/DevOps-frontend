# =========================
# 1️⃣ Stage build Flutter Web
# =========================
FROM debian:stable-slim AS build

# Cài đặt dependencies cần thiết cho Flutter
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa chromium && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài đặt Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Kiểm tra Flutter đã cài thành công
RUN flutter --version

# Sao chép mã nguồn vào container
WORKDIR /app
COPY . .

# Bật chế độ web cho Flutter
RUN flutter config --enable-web

# =========================
#  Nhận các biến môi trường khi build
# =========================
# Sử dụng giá trị mặc định nếu không được truyền vào
ARG BASE_URL=http://165.22.55.126/api
ARG WS_URL=ws://165.22.55.126/ws

# Build Flutter Web (release) và nhúng biến môi trường vào app
RUN flutter build web --release \
    --dart-define=BASE_URL=${BASE_URL} \
    --dart-define=WS_URL=${WS_URL}

# =========================
# 2️⃣ Stage chạy Nginx
# =========================
FROM nginx:stable-alpine

# Xóa cấu hình default của Nginx để tránh xung đột
RUN rm /etc/nginx/conf.d/default.conf

# Sao chép file cấu hình Nginx tùy chỉnh
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Sao chép build Flutter Web từ stage trước
COPY --from=build /app/build/web /usr/share/nginx/html

# Mở cổng 80 để phục vụ web
EXPOSE 80

# Chạy Nginx ở foreground
CMD ["nginx", "-g", "daemon off;"]
