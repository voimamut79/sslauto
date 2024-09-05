#!/bin/bash

# Kiểm tra người dùng có quyền root hay không
if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script dưới quyền root."
  exit
fi

# Nhập tên miền
read -p "Nhập tên miền của bạn (ví dụ: example.com): " DOMAIN

# Kiểm tra tên miền không rỗng
if [ -z "$DOMAIN" ]; then
  echo "Tên miền không hợp lệ."
  exit
fi

# Cập nhật hệ thống
echo "Cập nhật hệ thống..."
apt update && apt upgrade -y

# Cài đặt acme.sh nếu chưa cài
if ! command -v acme.sh &> /dev/null; then
  echo "Cài đặt acme.sh..."
  curl https://get.acme.sh | sh
  source ~/.bashrc
fi

# Đăng ký tài khoản (Let’s Encrypt hoặc ZeroSSL)
echo "Đăng ký tài khoản Freessl (qua Let's Encrypt hoặc ZeroSSL)..."
read -p "Bạn muốn sử dụng ZeroSSL không? (y/n): " USE_ZEROSSL
if [ "$USE_ZEROSSL" = "y" ]; then
  acme.sh --register-account --accountemail "youremail@example.com" --server zerossl
  SERVER="zerossl"
else
  acme.sh --register-account --accountemail "youremail@example.com"
  SERVER="letsencrypt"
fi

# Lấy chứng chỉ SSL từ Freessl.org
echo "Lấy chứng chỉ SSL cho $DOMAIN..."
acme.sh --issue -d "$DOMAIN" -d "www.$DOMAIN" --nginx --server "$SERVER"

# Tạo thư mục SSL nếu chưa tồn tại
mkdir -p /etc/nginx/ssl

# Cài đặt chứng chỉ SSL vào Nginx
echo "Cài đặt chứng chỉ SSL vào Nginx..."
acme.sh --install-cert -d "$DOMAIN" \
--key-file /etc/nginx/ssl/$DOMAIN.key \
--fullchain-file /etc/nginx/ssl/$DOMAIN.cer \
--reloadcmd "systemctl reload nginx"

# Cấu hình gia hạn tự động
echo "Cấu hình gia hạn tự động..."
acme.sh --upgrade --auto-upgrade
acme.sh --install-cronjob

# Khởi động lại Nginx
echo "Khởi động lại Nginx..."
systemctl reload nginx

echo "Hoàn thành! SSL đã được cài đặt cho $DOMAIN từ Freessl.org."
