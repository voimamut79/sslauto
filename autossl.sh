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

# Kiểm tra xem thư mục chứa chứng chỉ đã tồn tại hay chưa
SSL_DIR="/etc/nginx/ssl"
if [ ! -d "$SSL_DIR" ]; then
  mkdir -p "$SSL_DIR"
fi

# Lấy chứng chỉ SSL từ Let's Encrypt
echo "Lấy chứng chỉ SSL cho $DOMAIN..."
certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"

# Kiểm tra nếu quá trình lấy chứng chỉ thất bại
if [ $? -ne 0 ]; then
  echo "Lỗi: Không thể lấy chứng chỉ SSL cho $DOMAIN."
  exit 1
fi

# Cài đặt chứng chỉ SSL vào Nginx (sao lưu file cấu hình)
echo "Cài đặt chứng chỉ SSL vào Nginx..."
if [ -f "/etc/nginx/sites-available/$DOMAIN" ]; then
  cp "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-available/${DOMAIN}.bak"
fi

# Cấu hình gia hạn tự động
echo "Cấu hình gia hạn tự động..."
systemctl enable certbot.timer
systemctl start certbot.timer

# Kiểm tra trạng thái gia hạn tự động
echo "Kiểm tra trạng thái gia hạn tự động..."
systemctl status certbot.timer

# Kiểm tra gia hạn thủ công (nếu cần)
echo "Chạy thử gia hạn thủ công..."
certbot renew --dry-run

# Khởi động lại Nginx
echo "Khởi động lại Nginx..."
systemctl reload nginx

# Kiểm tra Nginx có khởi động thành công không
if [ $? -ne 0 ]; then
  echo "Lỗi: Khởi động lại Nginx thất bại."
  exit 1
fi

echo "Hoàn thành! SSL đã được cài đặt và cấu hình cho $DOMAIN."
