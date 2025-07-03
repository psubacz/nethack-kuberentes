#!/bin/bash
# Startup script for dgamelaunch container with runtime config support

set -e

echo "Starting dgamelaunch SSH server..."
echo "Checking for runtime configuration files..."

# Check and use mounted SSH config or fallback to default
if [ -f /etc/dgamelaunch/sshd_config ]; then
    echo "Using mounted SSH config: /etc/dgamelaunch/sshd_config"
    cp /etc/dgamelaunch/sshd_config /etc/ssh/sshd_config
elif [ ! -f /etc/ssh/sshd_config ]; then
    echo "Using default SSH config"
    cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
fi

# Check and use mounted dgamelaunch config or fallback to default
if [ -f /etc/dgamelaunch/dgamelaunch.conf ]; then
    echo "Using mounted dgamelaunch config: /etc/dgamelaunch/dgamelaunch.conf"
    cp /etc/dgamelaunch/dgamelaunch.conf /opt/dgl/dgamelaunch.conf
elif [ ! -f /opt/dgl/dgamelaunch.conf ]; then
    echo "Using default dgamelaunch config"
    cp /opt/dgl/configs/dgamelaunch.conf /opt/dgl/dgamelaunch.conf
fi

# Check and use mounted banner or fallback to default
if [ -f /etc/dgamelaunch/banner.txt ]; then
    echo "Using mounted banner: /etc/dgamelaunch/banner.txt"
    cp /etc/dgamelaunch/banner.txt /opt/dgl/chroot/dgl-banner
elif [ ! -f /opt/dgl/chroot/dgl-banner ]; then
    echo "Using default banner"
    cp /opt/dgl/configs/dgl-banner /opt/dgl/chroot/dgl-banner
fi

# Check and use mounted watchhelp or fallback to default
if [ -f /etc/dgamelaunch/watchhelp.txt ]; then
    echo "Using mounted watchhelp: /etc/dgamelaunch/watchhelp.txt"
    cp /etc/dgamelaunch/watchhelp.txt /opt/dgl/chroot/dgldir/watchhelp.txt
elif [ ! -f /opt/dgl/chroot/dgldir/watchhelp.txt ]; then
    echo "Using default watchhelp"
    cp /opt/dgl/configs/watchhelp.txt /opt/dgl/chroot/dgldir/watchhelp.txt
fi

# Ensure SSH host keys exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "Generating SSH host keys..."
    ssh-keygen -A
fi

# Set empty password for nethack user (for anonymous SSH access)
echo "Setting up nethack user for anonymous access..."
passwd -d nethack 2>/dev/null || true

# Ensure dgamelaunch directories exist and have correct permissions
mkdir -p /opt/dgl/chroot/dgldir/{inprogress-nh343,userdata,ttyrec}

# Ensure menu files exist in chroot
cp /opt/dgl/configs/dgl_menu_main_anon.txt /opt/dgl/chroot/dgl_menu_main_anon.txt 2>/dev/null || true
cp /opt/dgl/configs/dgl_menu_main_user.txt /opt/dgl/chroot/dgl_menu_main_user.txt 2>/dev/null || true
cp /opt/dgl/configs/dgl_menu_watchmenu_help.txt /opt/dgl/chroot/dgl_menu_watchmenu_help.txt 2>/dev/null || true
cp /opt/dgl/configs/dgl-banner /opt/dgl/chroot/dgl-banner 2>/dev/null || true
cp /opt/dgl/configs/dgl-default-rcfile.nh343 /opt/dgl/chroot/dgl-default-rcfile.nh343 2>/dev/null || true

chown -R nethack:games /opt/dgl/chroot/dgldir
if [ -d /opt/dgl/chroot/dgldir/userdata ]; then
    chown -R nethack:games /opt/dgl/chroot/dgldir/userdata
fi
chmod 4755 /usr/local/sbin/dgamelaunch

# Ensure /var/run/sshd exists
mkdir -p /var/run/sshd

# Test dgamelaunch configuration (no -f flag needed, path is hardcoded)
echo "Testing dgamelaunch configuration..."
echo "Current user: $(whoami)"
echo "dgamelaunch permissions: $(ls -la /usr/local/sbin/dgamelaunch)"
echo "Config file exists: $(ls -la /opt/dgl/dgamelaunch.conf)"
echo "Chroot directory: $(ls -la /opt/dgl/chroot/)"
echo "DGL directory: $(ls -la /opt/dgl/chroot/dgldir/)"

if ! /usr/local/sbin/dgamelaunch -S 2>&1; then
    echo "ERROR: dgamelaunch configuration test failed"
    echo "Config file contents:"
    cat /opt/dgl/dgamelaunch.conf
    echo "Trying to run dgamelaunch manually for debugging:"
    /usr/local/sbin/dgamelaunch 2>&1 || true
    exit 1
fi

echo "Configuration test passed. Starting SSH daemon..."
echo "SSH config: $(ls -la /etc/ssh/sshd_config)"
echo "DGL config: $(ls -la /opt/dgl/dgamelaunch.conf)"

# Start SSH daemon in foreground
exec /usr/sbin/sshd -D -f /etc/ssh/sshd_config
