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
    && rm -rf /var/lib/apt/lists/*

# Create nethack user and games group in builder stage
RUN useradd -m -s /bin/bash nethack \
    && usermod -a -G games nethack

# Set working directory
WORKDIR /build

# Copy source code and change ownership
COPY NetHack /build/NetHack
RUN chown -R nethack:nethack /build/NetHack

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

# Final runtime stage
FROM ubuntu:22.04

# Install runtime dependencies - we dont need gdb as its for build time logging. 
RUN apt-get update && apt-get install -y \
    libncurses5 \
    libncursesw5 \
    lua5.4 \
    # gdb \ 
    && rm -rf /var/lib/apt/lists/*

# Copy NetHack installation from builder
COPY --from=builder /home/nethack/nh/install /home/nethack/nh/install

# Create nethack user and add to games group (matching builder)
RUN useradd -m -s /bin/bash nethack \
    && usermod -a -G games nethack

# Fix sysconf to remove gdb dependency
RUN sed -i 's/^GDBPATH=/#GDBPATH=/' /home/nethack/nh/install/games/lib/nethackdir/sysconf

# Switch to nethack user
USER nethack
WORKDIR /home/nethack

# Default command
CMD ["/home/nethack/nh/install/games/nethack"]