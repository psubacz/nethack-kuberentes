#!/bin/bash
# Health check script for dgamelaunch container

# Check if SSH daemon is running
if ! pgrep -f "sshd.*-D" > /dev/null; then
    echo "FAIL: SSH daemon not running"
    exit 1
fi

# Check if SSH port is listening
if ! ss -tln | grep -q ":22 "; then
    echo "FAIL: SSH port 22 not listening"
    exit 1
fi

# Check if dgamelaunch config file exists and is readable
if [ ! -r /opt/nethack/etc/dgamelaunch.conf ]; then
    echo "FAIL: dgamelaunch config file not readable"
    exit 1
fi

# Check if dgamelaunch binary is executable
if [ ! -x /usr/local/sbin/dgamelaunch ]; then
    echo "FAIL: dgamelaunch binary not executable"
    exit 1
fi

# Test dgamelaunch configuration
if ! /usr/local/sbin/dgamelaunch -f /opt/nethack/etc/dgamelaunch.conf -S 2>/dev/null; then
    echo "FAIL: dgamelaunch configuration invalid"
    exit 1
fi

# Check if chroot directory structure exists
if [ ! -d /opt/nethack/dgldir ]; then
    echo "FAIL: dgamelaunch chroot directory missing"
    exit 1
fi

echo "OK: All health checks passed"
exit 0
