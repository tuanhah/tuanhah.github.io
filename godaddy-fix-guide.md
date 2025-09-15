# 🔧 **GoDaddy DNS Fix - Wildcard Record Issue**

## ❌ **Lỗi bạn đang gặp:**
```
Enter either @ or a valid host name such as: "subdomain.domain.tld"
```

## 💡 **Nguyên nhân:**
GoDaddy **không cho phép** CNAME record với name `*` vì:
- CNAME không thể trỏ đến IP address
- CNAME phải trỏ đến domain name (không phải IP)
- Wildcard CNAME conflict với A records

## ✅ **Giải pháp đúng:**

### **Thay vì:**
```
❌ Type: CNAME
❌ Name: *
❌ Value: your-domain.com
```

### **Hãy dùng:**
```
✅ Type: A
✅ Name: *
✅ Value: 3.67.79.37
```

## 📋 **Cấu hình DNS hoàn chỉnh:**

### **Trong GoDaddy DNS Management:**

| Type | Name | Value | TTL | Mô tả |
|------|------|-------|-----|-------|
| A | @ | `3.67.79.37` | 600 | Domain chính |
| A | www | `3.67.79.37` | 600 | www subdomain |
| A | * | `3.67.79.37` | 600 | Tất cả subdomain khác |

### **Ví dụ cụ thể:**
```
Record 1:
Type: A
Name: @
Value: 3.67.79.37
TTL: 600 seconds

Record 2:
Type: A  
Name: www
Value: 3.67.79.37
TTL: 600 seconds

Record 3:
Type: A
Name: *
Value: 3.67.79.37
TTL: 600 seconds
```

## 🎯 **Kết quả sau khi cấu hình:**

Tất cả các URL này sẽ trỏ đến server của bạn:
- ✅ `your-domain.com` → 3.67.79.37
- ✅ `www.your-domain.com` → 3.67.79.37  
- ✅ `api.your-domain.com` → 3.67.79.37
- ✅ `app.your-domain.com` → 3.67.79.37
- ✅ `anything.your-domain.com` → 3.67.79.37

## 📝 **Step-by-step trong GoDaddy:**

### **1. Truy cập DNS Management**
- Đăng nhập GoDaddy
- Chọn domain → "DNS"

### **2. Xóa records cũ (nếu có)**
- Xóa CNAME record bị lỗi
- Xóa A records cũ nếu có

### **3. Thêm 3 A records mới:**

**Record 1:**
```
Type: A
Host: @
Points to: 3.67.79.37
TTL: 1 Hour
```

**Record 2:**
```
Type: A
Host: www
Points to: 3.67.79.37
TTL: 1 Hour
```

**Record 3:**
```
Type: A
Host: *
Points to: 3.67.79.37
TTL: 1 Hour
```

### **4. Save Changes**
- Click "Save" hoặc "Add Record"
- Đợi 15-60 phút để DNS propagate

## 🔍 **Kiểm tra DNS:**

### **Online tools:**
- https://www.whatsmydns.net/
- https://dnschecker.org/

### **Command line:**
```bash
# Kiểm tra domain chính
nslookup your-domain.com

# Kiểm tra www
nslookup www.your-domain.com

# Kiểm tra wildcard
nslookup api.your-domain.com
```

## ⚡ **Tips:**

### **Nếu vẫn gặp lỗi:**
1. **Clear browser cache** và thử lại
2. **Đợi thêm thời gian** - DNS có thể mất đến 24h
3. **Kiểm tra spelling** - đảm bảo IP address đúng
4. **Liên hệ GoDaddy support** nếu vẫn không được

### **Alternative approach:**
Nếu không cần wildcard, chỉ tạo specific subdomains:
```
A | api | 3.67.79.37
A | app | 3.67.79.37  
A | dashboard | 3.67.79.37
```

## 🎉 **Kết luận:**
- ❌ **Không dùng** CNAME cho wildcard (*)
- ✅ **Dùng A record** cho wildcard (*)
- ✅ **Value luôn là IP** cho A record
- ✅ **Value là domain** cho CNAME record

**Bây giờ hãy thử lại với A record!** 🚀
