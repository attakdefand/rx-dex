# Use Rust official image for building
FROM rust:latest as builder

WORKDIR /usr/src/rx-dex

# Copy the workspace
COPY . .

# Use the custom workspace configuration
COPY Cargo.docker.toml Cargo.toml

# Build the matching-engine
RUN cargo build --release -p matching-engine
RUN rm -rf target/release/deps/matching-engine*

# Runtime stage
FROM debian:bookworm as runtime

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/rx-dex/target/release/matching-engine /usr/local/bin/matching-engine

EXPOSE 8084

CMD ["matching-engine"]