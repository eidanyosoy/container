FROM ghcr.io/dusk-labs/dim:dev

LABEL org.opencontainers.image.source="https://github.com/dockserver/container"

EXPOSE 8000
VOLUME ["/opt/dim/config"]

ENV RUST_LOG=info
WORKDIR /opt/dim
CMD ["./dim"]
