# Build stage
FROM rust:1.75 as builder

WORKDIR /usr/src/rx-dex-web

# Install trunk and wasm32 target
RUN cargo install trunk --version 0.16.0 || cargo install trunk
RUN rustup target add wasm32-unknown-unknown

# Copy web client files
COPY Cargo.toml .
COPY Cargo.lock .
RUN mkdir -p src
RUN echo "fn main() {}" > src/main.rs

# Build dependencies to cache them
RUN cargo build --release --target wasm32-unknown-unknown
RUN rm -rf target

# Copy source code
COPY src ./src
COPY index.html .

# Build the web app
RUN trunk build --release

# Runtime stage
FROM caddy:2-alpine

# Copy the built web app
COPY --from=builder /usr/src/rx-dex-web/dist /usr/share/caddy

# Copy Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 8082

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]