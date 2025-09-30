# Use Rust official image for building
FROM rust:1.82 as builder

WORKDIR /usr/src/rx-dex

# Copy the workspace
COPY . .

# Use the custom workspace configuration
COPY Cargo.docker.toml Cargo.toml

# Build the indexer
RUN cargo build --release -p indexer
RUN rm -rf target/release/deps/indexer*

# Runtime stage
FROM debian:bookworm as runtime

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/rx-dex/target/release/indexer /usr/local/bin/indexer

EXPOSE 8087

CMD ["indexer"]