# Multi-stage Dockerfile for dgamelaunch - Network Game Launcher with SSH
# Based on current setup instructions from NetHack Wiki

# Build stage
FROM debian:bookworm-slim AS builder

# Install build dependencies only
RUN apt-get update && apt-get install -y \
    # Build tools
    build-essential \
    autotools-dev \
    autoconf \
    automake \
    bison \
    flex \
    # Development libraries
    libncursesw5-dev \
    libsqlite3-dev \
    libpthread-stubs0-dev \
    # Version control
    git \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /usr/src/dgamelaunch

# Copy source code
COPY dgamelaunch .

# Build dgamelaunch with modern configuration
# Based on current NetHack wiki recommendations
RUN chmod +x autogen.sh && \
    ./autogen.sh \
        --enable-sqlite \
        --enable-shmem \
        --with-config-file=/opt/nethack/etc/dgamelaunch.conf && \
    make && \
    make install

# Build the included editors (ee and virus)
RUN make ee virus

# Runtime stage
FROM debian:bookworm-slim AS runtime

# Set maintainer info
LABEL maintainer="caboose"
LABEL description=" a contianerized dgamelaunch's for NetHack with SSH access"

# Install only runtime dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # Essential runtime libraries
    libncurses6 \
    libncursesw6 \
    libsqlite3-0 \
    # Core utilities
    ncurses-bin \
    sqlite3 \
    # SSH server
    openssh-server \
    # System essentials
    procps \
    passwd \
    coreutils \
    # Network tools
    iproute2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy built binaries from builder stage
COPY --from=builder /usr/local/sbin/dgamelaunch /usr/local/sbin/
COPY --from=builder /usr/src/dgamelaunch/ee /usr/local/bin/
COPY --from=builder /usr/src/dgamelaunch/virus /usr/local/bin/

# Copy configuration examples and chroot setup script
COPY --from=builder /usr/src/dgamelaunch/examples/ /usr/local/share/dgamelaunch/examples/
COPY --from=builder /usr/src/dgamelaunch/dgl-create-chroot /usr/local/bin/
COPY --from=builder /usr/src/dgamelaunch/dgamelaunch.8 /usr/local/share/man/man8/

# Create the standard chroot structure based on current practices
RUN mkdir -p /opt/nethack/nethack.alt.org \
    && mkdir -p /opt/nethack/dgldir \
    && mkdir -p /opt/nethack/dgldir/inprogress-nh343 \
    && mkdir -p /opt/nethack/dgldir/ttyrec \
    && mkdir -p /opt/nethack/dgldir/userdata \
    && mkdir -p /opt/nethack/etc \
    && mkdir -p /opt/nethack/bin \
    && mkdir -p /opt/nethack/usr/share/terminfo \
    && mkdir -p /opt/nethack/lib \
    && mkdir -p /opt/nethack/dev \
    && mkdir -p /var/log/dgamelaunch \
    && mkdir -p /var/run/sshd

# Create games user and group (modern practice uses numeric IDs)
# Using standardized games user (UID 5, GID 60 on most systems)
RUN groupadd -g 60 games 2>/dev/null || true \
    && useradd -u 5 -g 60 -d /opt/nethack -s /bin/false games 2>/dev/null || true \
    && groupadd -r dgamelaunch \
    && useradd -r -g dgamelaunch -d /opt/nethack -s /bin/false dgamelaunch

# Create nethack user for SSH access
RUN useradd -m -s /usr/local/sbin/dgamelaunch nethack \
    && echo 'nethack:nethack' | chpasswd \
    && mkdir -p /home/nethack/.ssh \
    && chown nethack:nethack /home/nethack/.ssh \
    && chmod 700 /home/nethack/.ssh

# Set up basic chroot environment
# Copy essential libraries and terminfo
RUN cp -a /usr/share/terminfo/x/xterm* /opt/nethack/usr/share/terminfo/ 2>/dev/null || true \
    && cp -a /usr/share/terminfo/s/screen* /opt/nethack/usr/share/terminfo/ 2>/dev/null || true \
    && cp -a /usr/share/terminfo/l/linux /opt/nethack/usr/share/terminfo/ 2>/dev/null || true \
    && mkdir -p /opt/nethack/usr/share/terminfo/x \
    && mkdir -p /opt/nethack/usr/share/terminfo/s \
    && mkdir -p /opt/nethack/usr/share/terminfo/l

# Create device nodes for chroot (skip if not privileged)
RUN mknod /opt/nethack/dev/null c 1 3 2>/dev/null || true \
    && mknod /opt/nethack/dev/zero c 1 5 2>/dev/null || true \
    && chmod 666 /opt/nethack/dev/null /opt/nethack/dev/zero 2>/dev/null || true

# Add configuration files from local configs directory
ADD configs/sshd_config /etc/ssh/sshd_config
ADD configs/dgamelaunch.conf /opt/nethack/etc/dgamelaunch.conf
ADD configs/banner.txt /opt/nethack/dgldir/banner.txt
ADD configs/watchhelp.txt /opt/nethack/dgldir/watchhelp.txt
ADD --chmod=755 configs/start-dgamelaunch.sh /usr/local/bin/start-dgamelaunch.sh
ADD --chmod=755 configs/healthcheck.sh /usr/local/bin/healthcheck.sh

# Set proper permissions
RUN chown -R dgamelaunch:dgamelaunch /opt/nethack/dgldir \
    && chown -R games:games /opt/nethack/dgldir/userdata \
    && chmod 4755 /usr/local/sbin/dgamelaunch \
    && chmod 755 /usr/local/bin/ee /usr/local/bin/virus

# Generate SSH host keys
RUN ssh-keygen -A

# Expose SSH port
EXPOSE 22

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

# Set volumes for persistent data
VOLUME ["/opt/nethack", "/home/nethack/.ssh"]

# Start dgamelaunch SSH server
CMD ["/usr/local/bin/start-dgamelaunch.sh"]