# Use Rust official image for building
FROM rust:1.82 as builder

WORKDIR /usr/src/rx-dex

# Copy the workspace
COPY . .

# Use the custom workspace configuration
COPY Cargo.docker.toml Cargo.toml

# Build the trading-service
RUN cargo build --release -p trading-service
RUN rm -rf target/release/deps/trading-service*

# Runtime stage
FROM debian:bookworm as runtime

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/rx-dex/target/release/trading-service /usr/local/bin/trading-service

EXPOSE 8089

CMD ["trading-service"]