#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_REVISION="${SDK_REVISION:-b57d1bbbb4a4a8a740ca26930eb188a7e14ae09a}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/.build/apple-xcframework}"
SDK_DIR="$BUILD_DIR/sdk-internal"
BINDINGS_DIR="$BUILD_DIR/bindings"
DIST_DIR="$BUILD_DIR/dist"
PROFILE=release

if [[ ! -d "$SDK_DIR/.git" ]]; then
    git clone https://github.com/bitwarden/sdk-internal.git "$SDK_DIR"
fi

git -C "$SDK_DIR" fetch origin "$SDK_REVISION"
git -C "$SDK_DIR" checkout --detach "$SDK_REVISION"

RUST_TOOLCHAIN="$(awk -F'"' '/channel =/ { print $2; exit }' "$SDK_DIR/rust-toolchain.toml")"
rustup target add \
    --toolchain "$RUST_TOOLCHAIN" \
    aarch64-apple-darwin \
    x86_64-apple-darwin \
    aarch64-apple-ios \
    aarch64-apple-ios-sim \
    x86_64-apple-ios

pushd "$SDK_DIR" >/dev/null

export IPHONEOS_DEPLOYMENT_TARGET=13.0
export RUSTFLAGS="-C link-arg=-Wl,-application_extension"
cargo build --package bitwarden-uniffi --target aarch64-apple-ios --release
cargo build --package bitwarden-uniffi --target aarch64-apple-ios-sim --release
cargo build --package bitwarden-uniffi --target x86_64-apple-ios --release
unset IPHONEOS_DEPLOYMENT_TARGET
unset RUSTFLAGS

export MACOSX_DEPLOYMENT_TARGET=26.0
cargo build --package bitwarden-uniffi --target aarch64-apple-darwin --release
cargo build --package bitwarden-uniffi --target x86_64-apple-darwin --release
unset MACOSX_DEPLOYMENT_TARGET

rm -rf "$BINDINGS_DIR"
mkdir -p "$BINDINGS_DIR"
cargo run -p uniffi-bindgen generate \
    "target/aarch64-apple-darwin/$PROFILE/libbitwarden_uniffi.dylib" \
    --language swift \
    --no-format \
    --out-dir "$BINDINGS_DIR"

popd >/dev/null

cp "$BINDINGS_DIR"/*.swift "$ROOT_DIR/Sources/BitwardenSdk/"
find "$ROOT_DIR/Sources/BitwardenSdk" \
    -type f \
    -name '*.swift' \
    -exec perl -pi -e 's/[ \t]+$//' {} +
cp \
    "$SDK_DIR/crates/bitwarden-uniffi/swift/Sources/BitwardenSdkSupport/NaiveDateFormatter.swift" \
    "$ROOT_DIR/Sources/BitwardenSdkSupport/NaiveDateFormatter.swift"

rm -rf "$DIST_DIR"
mkdir -p \
    "$DIST_DIR/headers" \
    "$DIST_DIR/ios-simulator" \
    "$DIST_DIR/macos"

cp "$BINDINGS_DIR"/*.h "$DIST_DIR/headers/"
cat "$BINDINGS_DIR"/*.modulemap > "$DIST_DIR/headers/module.modulemap"

lipo -create \
    "$SDK_DIR/target/aarch64-apple-ios-sim/$PROFILE/libbitwarden_uniffi.a" \
    "$SDK_DIR/target/x86_64-apple-ios/$PROFILE/libbitwarden_uniffi.a" \
    -output "$DIST_DIR/ios-simulator/libbitwarden_uniffi.a"

lipo -create \
    "$SDK_DIR/target/aarch64-apple-darwin/$PROFILE/libbitwarden_uniffi.a" \
    "$SDK_DIR/target/x86_64-apple-darwin/$PROFILE/libbitwarden_uniffi.a" \
    -output "$DIST_DIR/macos/libbitwarden_uniffi.a"

xcodebuild -create-xcframework \
    -library "$SDK_DIR/target/aarch64-apple-ios/$PROFILE/libbitwarden_uniffi.a" \
    -headers "$DIST_DIR/headers" \
    -library "$DIST_DIR/ios-simulator/libbitwarden_uniffi.a" \
    -headers "$DIST_DIR/headers" \
    -library "$DIST_DIR/macos/libbitwarden_uniffi.a" \
    -headers "$DIST_DIR/headers" \
    -output "$DIST_DIR/BitwardenFFI.xcframework"

ditto \
    -c \
    -k \
    --sequesterRsrc \
    --keepParent \
    "$DIST_DIR/BitwardenFFI.xcframework" \
    "$DIST_DIR/BitwardenFFI.xcframework.zip"

echo "Artifact: $DIST_DIR/BitwardenFFI.xcframework.zip"
echo "Checksum: $(swift package compute-checksum "$DIST_DIR/BitwardenFFI.xcframework.zip")"
