#!/bin/bash

# Khởi động dbus (cần cho xfce4 và xrdp)
service dbus start

# Khởi động pulseaudio ở chế độ system (cho âm thanh qua RDP)
pulseaudio --start --system --disallow-exit --disable-shm

# Khởi động xrdp server
service xrdp start

# Tạo thư mục socket X11 và cấp quyền
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Giữ container chạy và theo dõi log
tail -f /var/log/xrdp-sesman.log
