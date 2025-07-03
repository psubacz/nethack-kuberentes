#!/bin/bash
# Debug version of dgamelaunch startup script

set -e

echo "=== DGAMELAUNCH DEBUG STARTUP ==="
echo "Current user: $(whoami)"
echo "Current working directory: $(pwd)"

echo "=== CHECKING DGAMELAUNCH BINARY ==="
echo "dgamelaunch location: $(which dgamelaunch || echo 'not in PATH')"
echo "dgamelaunch permissions: $(ls -la /usr/local/sbin/dgamelaunch)"
echo "dgamelaunch dependencies:"
ldd /usr/local/sbin/dgamelaunch || echo "ldd failed"

echo "=== CHECKING CONFIG FILE ==="
echo "Config file: $(ls -la /opt/dgl/dgamelaunch.conf)"
echo "Config file readable: $(test -r /opt/dgl/dgamelaunch.conf && echo 'YES' || echo 'NO')"

echo "=== CHECKING CHROOT ENVIRONMENT ==="
echo "Chroot directory: $(ls -la /opt/dgl/chroot/)"
echo "DGL directory: $(ls -la /opt/dgl/chroot/dgldir/)"

echo "=== CHECKING BANNER AND MENU FILES ==="
echo "Banner file: $(ls -la /opt/dgl/chroot/dgl-banner 2>/dev/null || echo 'NOT FOUND')"
echo "Menu files:"
ls -la /opt/dgl/chroot/dgl_menu_* 2>/dev/null || echo "Menu files not found"

echo "=== CHECKING TERMINFO ==="
echo "Terminfo in chroot: $(ls -la /opt/dgl/chroot/usr/share/terminfo/ 2>/dev/null || echo 'NOT FOUND')"

echo "=== CHECKING LIBRARIES IN CHROOT ==="
echo "Lib directories in chroot:"
ls -la /opt/dgl/chroot/lib/ 2>/dev/null || echo "No /lib in chroot"
ls -la /opt/dgl/chroot/usr/lib/ 2>/dev/null || echo "No /usr/lib in chroot"

echo "=== TESTING DGAMELAUNCH DIRECTLY ==="
echo "Testing dgamelaunch without arguments:"
/usr/local/sbin/dgamelaunch 2>&1 | head -10 || echo "dgamelaunch failed"

echo "=== TESTING DGAMELAUNCH WITH -h ==="
echo "Testing dgamelaunch help:"
/usr/local/sbin/dgamelaunch -h 2>&1 || echo "No help flag"

echo "=== COPYING CONFIG FILES ==="
# Ensure all config files are in place
cp /opt/dgl/configs/dgamelaunch.conf /opt/dgl/dgamelaunch.conf 2>/dev/null || echo "Config copy failed"
cp /opt/dgl/configs/dgl-banner /opt/dgl/chroot/dgl-banner 2>/dev/null || echo "Banner copy failed"
cp /opt/dgl/configs/dgl_menu_main_anon.txt /opt/dgl/chroot/dgl_menu_main_anon.txt 2>/dev/null || echo "Menu copy failed"
cp /opt/dgl/configs/dgl_menu_main_user.txt /opt/dgl/chroot/dgl_menu_main_user.txt 2>/dev/null || echo "Menu copy failed"

echo "=== SETTING UP PERMISSIONS ==="
chown -R nethack:games /opt/dgl/chroot/dgldir 2>/dev/null || echo "Permission setup failed"
chmod 4755 /usr/local/sbin/dgamelaunch 2>/dev/null || echo "dgamelaunch chmod failed"

echo "=== SSH DAEMON SETUP ==="
mkdir -p /var/run/sshd
echo "SSH config file: $(ls -la /etc/ssh/sshd_config)"

echo "=== TESTING SSH DAEMON ==="
echo "Testing SSH daemon config:"
/usr/sbin/sshd -t -f /etc/ssh/sshd_config 2>&1 || echo "SSH config test failed"

echo "=== FINAL DGAMELAUNCH TEST ==="
echo "Testing dgamelaunch one more time:"
export TERM=xterm
/usr/local/sbin/dgamelaunch 2>&1 | head -5 || echo "Final dgamelaunch test failed"

echo "=== STARTING SSH DAEMON ==="
echo "Starting SSH daemon in foreground..."
exec /usr/sbin/sshd -D -f /etc/ssh/sshd_config
