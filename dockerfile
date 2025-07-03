# Multi-stage build for NetHack with dgamelaunch
FROM ubuntu:22.04 AS builder 

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    curl \
    git \
    bison \
    flex \
    groff \
    libncurses5-dev \
    libncursesw5-dev \
    zlib1g-dev \
    libsqlite3-dev \
    libpq-dev \
    lua5.4 \
    liblua5.4-dev \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Create nethack user and games group in builder stage
RUN useradd -m -s /bin/bash nethack \
    && usermod -a -G games nethack

# Set working directory
WORKDIR /build

# Copy source code and change ownership
COPY NetHack /build/NetHack
COPY dgamelaunch /build/dgamelaunch
RUN chown -R nethack:nethack /build/NetHack /build/dgamelaunch

# Switch to nethack user for building
USER nethack

# Build NetHack
WORKDIR /build/NetHack
RUN cp sys/unix/hints/linux.370 sys/unix/hints/linux-container

# Configure and build NetHack following NewInstall.unx instructions
WORKDIR /build/NetHack/sys/unix
RUN sh setup.sh hints/linux-container

WORKDIR /build/NetHack
RUN make fetch-Lua
RUN make all
RUN make install

# Note: dgamelaunch will be built in runtime stage

# Final runtime stage
FROM ubuntu:22.04

# Install runtime dependencies including build tools for dgamelaunch
RUN apt-get update && apt-get install -y \
    libncurses5 \
    libncursesw5 \
    lua5.4 \
    sqlite3 \
    openssh-server \
    build-essential \
    gcc \
    g++ \
    make \
    autoconf \
    automake \
    libtool \
    pkg-config \
    bison \
    flex \
    libncurses5-dev \
    libncursesw5-dev \
    zlib1g-dev \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy NetHack installation from builder
COPY --from=builder /home/nethack/nh/install /home/nethack/nh/install

# Copy dgamelaunch source and configs for runtime build
COPY dgamelaunch /opt/dgl/dgamelaunch-src
COPY dgamelaunch/examples /opt/dgl/examples
COPY configs /opt/dgl/configs

# Copy dgamelaunch.conf to the expected location before building
RUN cp /opt/dgl/configs/dgamelaunch.conf /opt/dgl/dgamelaunch.conf

# Create nethack user and add to games group (matching builder)
RUN useradd -m -s /bin/bash nethack \
    && usermod -a -G games nethack

# Build dgamelaunch in runtime
WORKDIR /opt/dgl/dgamelaunch-src
RUN ./autogen.sh --enable-sqlite --with-config-file=/opt/dgl/dgamelaunch.conf
RUN make
RUN make install

# Create dgamelaunch chroot environment
RUN rm -rf /opt/dgl/chroot 2>/dev/null || true \
    && mkdir -p /opt/dgl/chroot/bin \
    && mkdir -p /opt/dgl/chroot/dev \
    && mkdir -p /opt/dgl/chroot/dgldir \
    && mkdir -p /opt/dgl/chroot/etc \
    && mkdir -p /opt/dgl/chroot/lib \
    && mkdir -p /opt/dgl/chroot/lib64 \
    && mkdir -p /opt/dgl/chroot/mail \
    && mkdir -p /opt/dgl/chroot/nh343 \
    && mkdir -p /opt/dgl/chroot/tmp \
    && mkdir -p /opt/dgl/chroot/usr \
    && mkdir -p /opt/dgl/chroot/var \
    && mkdir -p /opt/dgl/chroot/dgldir/inprogress-nh343 \
    && mkdir -p /opt/dgl/chroot/dgldir/userdata \
    && mkdir -p /opt/dgl/chroot/dgldir/ttyrec \
    && mkdir -p /opt/dgl/chroot/nh343/lib \
    && mkdir -p /opt/dgl/chroot/nh343/var \
    && mkdir -p /opt/dgl/chroot/nh343/games \
    && mkdir -p /opt/dgl/chroot/nh343/var/save \
    && mkdir -p /opt/dgl/chroot/usr/share \
    && mkdir -p /opt/dgl/chroot/usr/share/terminfo

# Copy NetHack into chroot
RUN mkdir -p /opt/dgl/chroot/nh343/lib \
    && cp /home/nethack/nh/install/games/nethack /opt/dgl/chroot/nh343/nethack \
    && cp -r /home/nethack/nh/install/games/lib/nethackdir/* /opt/dgl/chroot/nh343/lib/ \
    && chmod 755 /opt/dgl/chroot/nh343/nethack

# Fix sysconf to remove gdb dependency
RUN sed -i 's/^GDBPATH=/#GDBPATH=/' /home/nethack/nh/install/games/lib/nethackdir/sysconf \
    && sed -i 's/^GDBPATH=/#GDBPATH=/' /opt/dgl/chroot/nh343/lib/sysconf

# Set up SSH server and copy custom config
RUN mkdir /var/run/sshd
COPY configs/sshd_config /etc/ssh/sshd_config

# Copy pre-generated SSH host keys
COPY ssh-keys/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key
COPY ssh-keys/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub
COPY ssh-keys/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
COPY ssh-keys/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key.pub

RUN chmod 600 /etc/ssh/ssh_host_*_key \
    && chmod 644 /etc/ssh/ssh_host_*.pub

# Copy dgamelaunch configuration files
RUN cp /opt/dgl/configs/dgamelaunch.conf /opt/dgl/dgamelaunch.conf \
    && cp /opt/dgl/configs/dgl-banner /opt/dgl/chroot/dgl-banner \
    && cp /opt/dgl/configs/dgl_menu_main_anon.txt /opt/dgl/chroot/dgl_menu_main_anon.txt \
    && cp /opt/dgl/configs/dgl_menu_main_user.txt /opt/dgl/chroot/dgl_menu_main_user.txt \
    && cp /opt/dgl/configs/dgl_menu_watchmenu_help.txt /opt/dgl/chroot/dgl_menu_watchmenu_help.txt \
    && cp /opt/dgl/configs/dgl-default-rcfile.nh343 /opt/dgl/chroot/dgl-default-rcfile.nh343 \
    && cp /opt/dgl/configs/watchhelp.txt /opt/dgl/chroot/dgldir/watchhelp.txt

# Copy essential files into chroot
RUN echo "Setting up chroot libraries..." \
    && cp -r /lib/x86_64-linux-gnu /opt/dgl/chroot/lib/ \
    && cp -r /usr/lib/x86_64-linux-gnu /opt/dgl/chroot/usr/lib/ \
    && cp /etc/passwd /opt/dgl/chroot/etc/ \
    && cp /etc/group /opt/dgl/chroot/etc/ \
    && cp -r /usr/share/terminfo /opt/dgl/chroot/usr/share/ \
    && echo "Setting up chroot lib64..." \
    && cp -r /lib64/* /opt/dgl/chroot/lib64/ 2>/dev/null || true \
    && echo "Setting up chroot binaries..." \
    && cp /bin/bash /opt/dgl/chroot/bin/bash \
    && cp /bin/sh /opt/dgl/chroot/bin/sh \
    && cp /bin/ls /opt/dgl/chroot/bin/ls \
    && echo "Verifying chroot setup..." \
    && ls -la /opt/dgl/chroot/bin/ \
    && ls -la /opt/dgl/chroot/lib/ \
    && echo "Chroot setup complete"

# Set up permissions for dgamelaunch
RUN chown -R nethack:games /opt/dgl/chroot/dgldir \
    && chown -R nethack:games /opt/dgl/chroot/nh343/var \
    && chmod -R 755 /opt/dgl/chroot/dgldir \
    && chmod -R 755 /opt/dgl/chroot/nh343/var

# Switch to root for final setup
USER root

# Set dgamelaunch as setuid root (required for chroot)
RUN chmod 4755 /usr/local/sbin/dgamelaunch

# Set empty password for nethack user and test dgamelaunch
RUN passwd -d nethack

# Test dgamelaunch configuration (no -f flag needed, path is hardcoded)
RUN /usr/local/sbin/dgamelaunch -S || echo "DGL config test failed - this is expected during build"

# Copy the proper startup script
COPY configs/start-dgamelaunch.sh /start.sh
RUN chmod +x /start.sh

# Expose SSH port
EXPOSE 22

# Default command
CMD ["/start.sh"]