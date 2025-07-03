#!/bin/bash

echo "=== DGAMELAUNCH COMPREHENSIVE DEBUG ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo

echo "=== CHECKING DGAMELAUNCH BINARY ==="
echo "Binary location: $(which dgamelaunch 2>/dev/null || echo '/usr/local/sbin/dgamelaunch')"
echo "Binary exists: $(test -f /usr/local/sbin/dgamelaunch && echo 'YES' || echo 'NO')"
echo "Binary permissions: $(ls -la /usr/local/sbin/dgamelaunch 2>/dev/null || echo 'NOT FOUND')"
echo "Binary is executable: $(test -x /usr/local/sbin/dgamelaunch && echo 'YES' || echo 'NO')"
echo

echo "=== CHECKING BINARY DEPENDENCIES ==="
echo "Libraries needed by dgamelaunch:"
ldd /usr/local/sbin/dgamelaunch 2>/dev/null || echo "ldd failed"
echo

echo "=== CHECKING CONFIGURATION ==="
echo "Config file: /opt/dgl/dgamelaunch.conf"
echo "Config exists: $(test -f /opt/dgl/dgamelaunch.conf && echo 'YES' || echo 'NO')"
echo "Config readable: $(test -r /opt/dgl/dgamelaunch.conf && echo 'YES' || echo 'NO')"
echo "Config permissions: $(ls -la /opt/dgl/dgamelaunch.conf 2>/dev/null || echo 'NOT FOUND')"
echo

if [ -f /opt/dgl/dgamelaunch.conf ]; then
    echo "=== CONFIG FILE CONTENTS ==="
    cat /opt/dgl/dgamelaunch.conf
    echo
fi

echo "=== CHECKING CHROOT ENVIRONMENT ==="
echo "Chroot directory: /opt/dgl/chroot"
echo "Chroot exists: $(test -d /opt/dgl/chroot && echo 'YES' || echo 'NO')"
echo "Chroot permissions: $(ls -lad /opt/dgl/chroot 2>/dev/null || echo 'NOT FOUND')"
echo

echo "Chroot contents:"
ls -la /opt/dgl/chroot/ 2>/dev/null || echo "Cannot list chroot contents"
echo

echo "=== CHECKING ESSENTIAL CHROOT FILES ==="
echo "Essential directories in chroot:"
for dir in bin dev dgldir etc lib lib64 usr/share/terminfo; do
    if [ -d "/opt/dgl/chroot/$dir" ]; then
        echo "  $dir: EXISTS"
    else
        echo "  $dir: MISSING"
    fi
done
echo

echo "=== CHECKING BANNER AND MENU FILES ==="
echo "Banner file: /opt/dgl/chroot/dgl-banner"
echo "Banner exists: $(test -f /opt/dgl/chroot/dgl-banner && echo 'YES' || echo 'NO')"
echo "Banner readable: $(test -r /opt/dgl/chroot/dgl-banner && echo 'YES' || echo 'NO')"

echo "Menu files:"
for menu in dgl_menu_main_anon.txt dgl_menu_main_user.txt dgl_menu_watchmenu_help.txt; do
    if [ -f "/opt/dgl/chroot/$menu" ]; then
        echo "  $menu: EXISTS"
    else
        echo "  $menu: MISSING"
    fi
done
echo

echo "=== CHECKING TERMINFO ==="
echo "Terminfo directory: /opt/dgl/chroot/usr/share/terminfo"
echo "Terminfo exists: $(test -d /opt/dgl/chroot/usr/share/terminfo && echo 'YES' || echo 'NO')"
if [ -d /opt/dgl/chroot/usr/share/terminfo ]; then
    echo "Terminfo entries: $(ls /opt/dgl/chroot/usr/share/terminfo/ | wc -l) directories"
    echo "xterm terminfo: $(test -f /opt/dgl/chroot/usr/share/terminfo/x/xterm && echo 'EXISTS' || echo 'MISSING')"
fi
echo

echo "=== CHECKING LIBRARIES IN CHROOT ==="
echo "Dynamic linker in chroot:"
echo "  /lib64/ld-linux-x86-64.so.2: $(test -f /opt/dgl/chroot/lib64/ld-linux-x86-64.so.2 && echo 'EXISTS' || echo 'MISSING')"
echo "  /lib/x86_64-linux-gnu: $(test -d /opt/dgl/chroot/lib/x86_64-linux-gnu && echo 'EXISTS' || echo 'MISSING')"
echo

echo "=== TESTING DGAMELAUNCH EXECUTION ==="
echo "Testing dgamelaunch with different approaches..."

export TERM=xterm
export DISPLAY=
export HOME=/tmp

echo "Test 1: Direct execution"
timeout 5 /usr/local/sbin/dgamelaunch 2>&1 | head -10 || echo "Direct execution failed or timed out"
echo

echo "Test 2: With strace to see what files it's trying to access"
timeout 5 strace -e trace=file /usr/local/sbin/dgamelaunch 2>&1 | head -20 || echo "Strace failed"
echo

echo "Test 3: Check if it's a chroot issue"
echo "Can we chroot manually?"
chroot /opt/dgl/chroot /bin/bash -c "echo 'Chroot test successful'" 2>&1 || echo "Manual chroot failed"
echo

echo "=== TESTING SSH CONFIGURATION ==="
echo "SSH config file exists: $(test -f /etc/ssh/sshd_config && echo 'YES' || echo 'NO')"
echo "SSH config test:"
/usr/sbin/sshd -t -f /etc/ssh/sshd_config 2>&1 || echo "SSH config test failed"
echo

echo "=== ENVIRONMENT VARIABLES ==="
echo "TERM: $TERM"
echo "LANG: $LANG"
echo "LC_ALL: $LC_ALL"
echo "PATH: $PATH"
echo

echo "=== FINAL SUMMARY ==="
echo "If dgamelaunch is failing, the most likely issues are:"
echo "1. Missing libraries in chroot environment"
echo "2. Missing or incorrect terminfo"
echo "3. Configuration file parsing errors"
echo "4. Permission issues with chroot"
echo "5. Missing essential files in chroot (passwd, group, etc.)"
echo

echo "=== DEBUG COMPLETE ==="
