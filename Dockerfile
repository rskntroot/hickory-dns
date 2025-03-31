FROM alpine:latest AS builder

RUN apk add --no-cache \
    build-base \
    curl \
    openssl-dev \
    rust cargo

RUN apk add --no-cache git

RUN cd /root && git clone https://github.com/hickory-dns/hickory-dns.git

RUN cd /root/hickory-dns && cargo build --bin hickory-dns --features=blocklist --release

FROM alpine:latest

RUN apk add --no-cache curl libgcc

COPY --from=builder /root/hickory-dns/target/release/hickory-dns /usr/local/bin/hickory-dns

EXPOSE 53/udp 53/tcp 443/tcp 443/udp

CMD ["/etc/hickory/entrypoint.sh"]
