FROM alpine:latest

RUN apk add --no-cache \
    build-base \
    curl \
    openssl-dev \
    rust cargo

# Install Hickory DNS Server
RUN cargo install hickory-dns
RUN /root/.cargo/bin/hickory-dns -V

# Create directory for configuration
RUN mkdir -p /etc/hickory

# Expose DNS and Web ports
EXPOSE 53/udp 53/tcp 443/tcp 443/udp

# Run Hickory on startup
CMD ["/root/.cargo/bin/hickory-dns", "--debug", "--config", "/etc/hickory/config.toml"]
