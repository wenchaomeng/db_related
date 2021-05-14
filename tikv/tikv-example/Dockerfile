FROM ubuntu:latest
# Systemwide setup
RUN apt update
RUN apt install --yes build-essential protobuf-compiler curl cmake golang

# Create the non-root user.
RUN useradd builder -m -b /
USER builder
RUN mkdir -p ~/build/src

# Install Rust
COPY rust-toolchain /builder/build/
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain `cat /builder/build/rust-toolchain` -y
ENV PATH="/builder/.cargo/bin:${PATH}"

# Fetch, then prebuild all deps
COPY Cargo.toml rust-toolchain /builder/build/
RUN echo "fn main() {}" > /builder/build/src/main.rs
WORKDIR /builder/build
RUN cargo fetch
RUN cargo build --release
COPY src /builder/build/src
RUN rm -rf ./target/release/.fingerprint/tikv-example*

# Actually build the binary
RUN cargo build --release
ENTRYPOINT /builder/build/target/release/tikv-example
