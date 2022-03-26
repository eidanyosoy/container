FROM ghcr.io/dusk-labs/dim:dev

EXPOSE 8000
VOLUME ["/opt/dim/config"]

ENV RUST_LOG=info
WORKDIR /opt/dim
CMD ["./dim"]
