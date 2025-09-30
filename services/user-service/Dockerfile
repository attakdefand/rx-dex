# Use Rust official image for building
FROM rust:1.82 as builder

WORKDIR /usr/src/rx-dex

# Copy the workspace
COPY . .

# Use the custom workspace configuration
COPY Cargo.docker.toml Cargo.toml

# Build the user-service
RUN cargo build --release -p user-service
RUN rm -rf target/release/deps/user-service*

# Runtime stage
FROM debian:bookworm as runtime

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/rx-dex/target/release/user-service /usr/local/bin/user-service

EXPOSE 8083

CMD ["user-service"]