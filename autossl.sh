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

# Cài đặt Certbot và plugin cho Nginx
echo "Cài đặt Certbot và plugin cho Nginx..."
apt install certbot python3-certbot-nginx -y

# Cấu hình tường lửa (nếu sử dụng UFW)
if command -v ufw &> /dev/null; then
  echo "Cấu hình tường lửa..."
  ufw allow 'Nginx Full'
fi

# Lấy chứng chỉ SSL từ Let's Encrypt
echo "Lấy chứng chỉ SSL cho $DOMAIN..."
certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"

# Kiểm tra trạng thái gia hạn tự động
echo "Kiểm tra trạng thái gia hạn tự động..."
systemctl status certbot.timer

# Kiểm tra gia hạn thủ công (nếu cần)
echo "Chạy thử gia hạn thủ công..."
certbot renew --dry-run

# Khởi động lại Nginx
echo "Khởi động lại Nginx..."
systemctl reload nginx

echo "Hoàn thành! SSL đã được cài đặt cho $DOMAIN."
