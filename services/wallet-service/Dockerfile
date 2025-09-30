# Use Rust official image for building
FROM rust:1.82 as builder

WORKDIR /usr/src/rx-dex

# Copy the workspace
COPY . .

# Use the custom workspace configuration
COPY Cargo.docker.toml Cargo.toml

# Build the wallet-service
RUN cargo build --release -p wallet-service
RUN rm -rf target/release/deps/wallet-service*

# Runtime stage
FROM debian:bookworm as runtime

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/rx-dex/target/release/wallet-service /usr/local/bin/wallet-service

EXPOSE 8085

CMD ["wallet-service"]