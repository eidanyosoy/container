  #####################################
  # DockServer Local-Persist Container#
  # Docker Volume Plugin              #
  #####################################
  # Based on local-persist by CWSpear #
  # Enhanced for DockServer ecosystem #
  #####################################

  FROM alpine:3.22.1 AS builder

  LABEL org.opencontainers.image.source="https://github.com/smashingtags/container"

  ### BUILD STAGE
  ARG TARGETPLATFORM
  ARG BUILDPLATFORM
  ARG LOCAL_PERSIST_VERSION=v1.3.0

  RUN \
    echo "**** update packages ****" && \
      apk --quiet --no-cache --no-progress update && \
      apk --quiet --no-cache --no-progress upgrade && \
    echo "**** install build packages ****" && \
      apk add -U --update --no-cache --quiet curl && \
    echo "**** download local-persist binary ****" && \
      curl -L https://github.com/CWSpear/local-persist/releases/download/v1.3.0/local-persist-linux-amd64 -o /usr/local/bin/local-persist && \
      chmod +x /usr/local/bin/local-persist && \
    echo "*** cleanup build dependencies ****" && \
      apk del --purge --quiet curl && \
    echo "*** cleanup build system ****" && \
      apk del --quiet --clean-protected --no-progress && \
      rm -rf /var/cache/apk/* /tmp/*

  FROM ghcr.io/linuxserver/baseimage-alpine:3.22-6a2f7be2-ls7

  ARG TARGETPLATFORM
  ARG BUILDPLATFORM
  ARG BASE_VERSION=3.22.1
  ARG ALPINE_VERSION=3.22-6a2f7be2-ls7
  ARG LOCAL_PERSIST_VERSION=v1.3.0

  # Add container metadata
  LABEL \
    org.opencontainers.image.title="DockServer Local-Persist Volume Plugin" \
    org.opencontainers.image.description="Docker volume plugin for local volumes with custom mountpoints - DockServer Edition" \
    org.opencontainers.image.vendor="smashingtags" \
    org.opencontainers.image.version="${LOCAL_PERSIST_VERSION}" \
    org.opencontainers.image.source="https://github.com/smashingtags/container" \
    org.opencontainers.image.documentation="https://github.com/smashingtags/container/blob/main/apps/docker-local-persist/README.md" \
    maintainer="smashingtags <https://github.com/smashingtags>"

  RUN \
    echo "**** update packages ****" && \
      apk --quiet --no-cache --no-progress update && \
    apk --quiet --no-cache --no-progress upgrade && \
    echo "**** install runtime packages ****" && \
      apk add -U --update --no-cache --quiet bash curl jq && \
    echo "**** create directories ****" && \
      mkdir -p /var/lib/docker/plugin-data && \
      mkdir -p /run/docker/plugins && \
      mkdir -p /opt/appdata && \
      mkdir -p /mnt && \
    echo "*** cleanup system ****" && \
      apk del --quiet --clean-protected --no-progress && \
      rm -rf /var/cache/apk/* /tmp/*

  # Copy the local-persist binary
  COPY --from=builder --chown=abc --chmod=755 /usr/local/bin/local-persist /usr/local/bin/local-persist

  # Copy DockServer customizations
  COPY --chown=abc --chmod=755 ./root/ /

  # Create plugin socket directory with correct permissions
  RUN chown -R abc:abc /var/lib/docker/plugin-data /run/docker/plugins /opt/appdata /mnt

  # Expose plugin socket path
  VOLUME ["/var/lib/docker/plugin-data", "/run/docker/plugins", "/opt/appdata", "/mnt"]

  # Health check for DockServer monitoring integration
  HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD test -S /run/docker/plugins/local-persist.sock || exit 1

  ENTRYPOINT ["/init"]

  ##EOF
