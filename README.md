Swift Package for the
[Bitwarden SDK](https://github.com/bitwarden/sdk-internal).

This fork adds macOS 26 support to the official Bitwarden Swift SDK package.
Its XCFramework contains:

- iOS arm64
- iOS Simulator arm64 and x86_64
- macOS arm64 and x86_64

The Swift bindings and native libraries are generated from
`bitwarden/sdk-internal` revision
`b57d1bbbb4a4a8a740ca26930eb188a7e14ae09a`.

## Building the Apple XCFramework

Requirements:

- Xcode 26
- Rustup
- macOS

Run:

```bash
./build-apple-xcframework.sh
```

The script builds all supported Apple targets, refreshes the generated Swift
bindings, and creates:

```text
.build/apple-xcframework/dist/BitwardenFFI.xcframework.zip
```

After uploading the zip to the `macos-b57d1bb` GitHub release, ensure the
checksum printed by the script matches the checksum in `Package.swift`.
