# Sweef Browser Dockerfile
# Use this to build and test Sweef Browser locally

FROM debian:13-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Zig 0.11.0
RUN curl -L https://ziglang.org/builds/zig-linux-x86_64-0.11.0.tar.xz -o /tmp/zig.tar.xz \
    && mkdir -p /usr/local/zig \
    && tar -xf /tmp/zig.tar.xz -C /usr/local/zig --strip-components=1 \
    && rm /tmp/zig.tar.xz \
    && echo 'export PATH="/usr/local/zig:$PATH"' >> /etc/profile.d/zig.sh

# Add Zig to PATH for this session
ENV PATH="/usr/local/zig:$PATH"

# Clone and build Sweef Browser
WORKDIR /workspace/sweef

# Build the core engine
RUN zig build -Doptimize=ReleaseSafe

# Default command
CMD ["zig", "build", "-Doptimize=ReleaseSafe"]
