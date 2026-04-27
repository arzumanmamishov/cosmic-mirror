# =============================================================================
# Build stage: compile libswe.so and the Go binary
# swephgo links against /usr/local/lib/libswe.so which we build from source.
# =============================================================================
FROM golang:1.22-bookworm AS builder

# Build dependencies for both the C library and the Go binary
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    libc6-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Build Swiss Ephemeris C library (libswe.so)
# -----------------------------------------------------------------------------
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/aloistr/swisseph.git swisseph-src

WORKDIR /tmp/swisseph-src
# The upstream Makefile builds executables; we build a shared library.
# Source files are at the repo root, not in src/.
RUN gcc -fPIC -c -O2 -Wall \
        swedate.c swehouse.c swejpl.c swemmoon.c swemplan.c \
        sweph.c swephlib.c swecl.c swehel.c \
    && gcc -shared -o libswe.so *.o -lm -ldl \
    && cp libswe.so /usr/local/lib/ \
    && cp swephexp.h sweodef.h /usr/local/include/ \
    && ldconfig

# -----------------------------------------------------------------------------
# Build the Go server (CGO links against /usr/local/lib/libswe.so)
# -----------------------------------------------------------------------------
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=1 GOOS=linux \
    CGO_LDFLAGS="-L/usr/local/lib" \
    CGO_CFLAGS="-I/usr/local/include" \
    go build -ldflags="-w -s" -o /server ./cmd/server

# =============================================================================
# Final stage: small runtime with libswe.so and ephemeris data
# =============================================================================
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -u 1000 -g root appuser

WORKDIR /app

# Runtime: ship the compiled libswe.so and refresh the linker cache
COPY --from=builder /usr/local/lib/libswe.so /usr/local/lib/libswe.so
RUN ldconfig

# Application binary, migrations, and ephemeris data
COPY --from=builder /server                /app/server
COPY --from=builder /app/migrations        /app/migrations
COPY --from=builder /app/ephemeris         /app/ephemeris

ENV EPHEMERIS_PATH=/app/ephemeris

USER appuser

EXPOSE 8080

ENTRYPOINT ["/app/server"]
