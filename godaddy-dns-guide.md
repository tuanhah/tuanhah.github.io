# 🌐 Hướng dẫn cấu hình DNS GoDaddy cho TikTok Auto Scheduler

## Bước 1: Truy cập GoDaddy DNS Management

1. **Đăng nhập GoDaddy**: https://sso.godaddy.com/
2. **Vào "My Products"** → chọn domain của bạn
3. **Click "DNS"** hoặc "Manage DNS"

## Bước 2: Cấu hình DNS Records

### 🎯 **Xóa records cũ (nếu có)**
- Xóa tất cả A records và CNAME records cũ

### 📝 **Thêm DNS Records mới**

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | `YOUR_EC2_IP` | 600 |
| A | www | `YOUR_EC2_IP` | 600 |
| A | * | `YOUR_EC2_IP` | 600 |
| TXT | @ | `tiktok-developers-site-verification=p3FnrLtkMp5BLZ3Sul0FiSrICW3EDOf3` | 600 |

### 📋 **Ví dụ cụ thể:**
```
Type: A
Name: @
Value: 13.123.45.67
TTL: 600 seconds

Type: A  
Name: www
Value: 13.123.45.67
TTL: 600 seconds

Type: A
Name: *
Value: 13.123.45.67
TTL: 600 seconds

Type: TXT
Name: @
Value: tiktok-developers-site-verification=p3FnrLtkMp5BLZ3Sul0FiSrICW3EDOf3
TTL: 600 seconds
```

### ⚠️ **Lưu ý quan trọng về Wildcard Records:**

**GoDaddy không cho phép CNAME với name `*` vì:**
- CNAME không thể trỏ đến IP address
- CNAME phải trỏ đến domain name
- Wildcard CNAME có thể conflict với A records

**✅ Giải pháp đúng:**
- Sử dụng **A record** với name `*` thay vì CNAME
- Value là IP address của server (3.67.79.37)
- Điều này sẽ handle tất cả subdomain như: api.domain.com, app.domain.com, etc.

## 🎯 **Bước đặc biệt: TikTok Domain Verification**

### 📱 **Để xác minh domain với TikTok:**

1. **Thêm TXT Record cho TikTok:**
   ```
   Type: TXT
   Name: @
   Value: tiktok-developers-site-verification=p3FnrLtkMp5BLZ3Sul0FiSrICW3EDOf3
   TTL: 600 seconds
   ```

2. **Các bước thực hiện trên GoDaddy:**
   - Vào DNS Management của domain `tiktokupvid.shop`
   - Click "Add Record"
   - Chọn Type: **TXT**
   - Name: **@** (hoặc để trống)
   - Value: **tiktok-developers-site-verification=p3FnrLtkMp5BLZ3Sul0FiSrICW3EDOf3**
   - TTL: **600** seconds
   - Click "Save"

3. **Xác minh:**
   - Đợi 15-30 phút để DNS propagate
   - Quay lại TikTok để verify domain
   - Kiểm tra bằng lệnh: `dig TXT tiktokupvid.shop`

## Bước 3: Cập nhật Nginx Configuration

### 🔧 **Trên EC2 Server:**
```bash
# Kết nối SSH
ssh -i "your-key.pem" ubuntu@your-ec2-ip

# Chỉnh sửa Nginx config
sudo nano /etc/nginx/sites-available/tiktok-scheduler

# Thay đổi dòng server_name:
server_name your-domain.com www.your-domain.com;

# Test và reload Nginx
sudo nginx -t
sudo systemctl reload nginx
```

## Bước 4: Kiểm tra DNS Propagation

### 🕐 **Thời gian chờ:**
- DNS thường mất **15-60 phút** để propagate
- Có thể mất đến **24-48 giờ** trong một số trường hợp

### 🔍 **Tools kiểm tra:**
```bash
# Command line
nslookup your-domain.com
dig your-domain.com

# Online tools
https://www.whatsmydns.net/
https://dnschecker.org/
```

## Bước 5: Xác minh cấu hình

### ✅ **Kiểm tra hoạt động:**
```bash
# Test từ command line
curl -I http://your-domain.com
curl -I http://www.your-domain.com

# Hoặc mở trình duyệt:
http://your-domain.com
http://www.your-domain.com
```

## 🔒 **Bước 6: Setup SSL Certificate (Tiếp theo)**

Sau khi DNS hoạt động, chạy lệnh sau để setup SSL:
```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

## 🚨 **Troubleshooting**

### **Lỗi thường gặp:**

1. **"DNS_PROBE_FINISHED_NXDOMAIN"**
   - Kiểm tra DNS records
   - Chờ DNS propagation
   - Xóa cache DNS: `ipconfig /flushdns` (Windows) hoặc `sudo dscacheutil -flushcache` (Mac)

2. **"Connection refused"**
   - Kiểm tra Security Group EC2 (port 80, 443)
   - Kiểm tra UFW firewall trên server
   - Kiểm tra Nginx status: `sudo systemctl status nginx`

3. **"502 Bad Gateway"**
   - Kiểm tra Nginx config: `sudo nginx -t`
   - Kiểm tra logs: `sudo tail -f /var/log/nginx/error.log`

4. **Mixed content từ một số region**
   - Chờ đủ 24-48h để DNS propagate hoàn toàn
   - Kiểm tra với VPN từ region khác

## 📞 **Support:**
- GoDaddy Support: https://www.godaddy.com/help
- DNS Help: https://www.godaddy.com/help/manage-dns-zone-files-680
