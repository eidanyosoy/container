#!/usr/bin/env bash

#shellcheck disable=SC1091
source "/shim/umask.sh"

exec /app/xteve -config /config ${EXTRA_ARGS}
