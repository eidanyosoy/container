ARG ALPINE_VERSION=3.17
ARG GOLANG_VERSION=1.17.2

FROM alpine:${ALPINE_VERSION} as stage

RUN apk add --no-cache git && \
    git clone https://github.com/cloudflare/cloudflared.git /tmp/cloudflared

ARG TARGET_GOOS
ARG TARGET_GOARCH
ARG VERSION
FROM golang:${GOLANG_VERSION} as builder
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    TARGET_GOOS=${TARGET_GOOS} \
    TARGET_GOARCH=${TARGET_GOARCH}

COPY --from=stage /tmp/cloudflared /go/src/github.com/cloudflare/cloudflared/
WORKDIR /go/src/github.com/cloudflare/cloudflared/
RUN make cloudflared

FROM gcr.io/distroless/base-debian10:nonroot

COPY --from=stage /tmp/cloudflared /go/src/github.com/cloudflare/cloudflared/
COPY --from=builder --chown=nonroot /go/src/github.com/cloudflare/cloudflared/cloudflared /usr/local/bin/

USER nonroot
ENTRYPOINT ["cloudflared", "--no-autoupdate"]
CMD ["version"]
