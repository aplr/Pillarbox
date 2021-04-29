<h1>
    <img src="https://raw.githubusercontent.com/aplr/Pillarbox/main/Logo.png?token=AAIAWBDNQRUM6JJJWSYHN43ASPZJS" height="23" />
    Pillarbox
</h1>

![Build](https://github.com/aplr/Pillarbox/workflows/Build/badge.svg?branch=main)
![Documentation](https://github.com/aplr/Pillarbox/workflows/Documentation/badge.svg)

Pillarbox is an easy-to-use, object-based FIFO queue with support for iOS, tvOS and macOS. Addition and removal is an O(1) operation. Writes are synchronous; data will be written to the disk before an operation returns.

## Installation

Pillarbox is available via the [Swift Package Manager](https://swift.org/package-manager/) which is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system and automates the process of downloading, compiling, and linking dependencies.

Once you have your Swift package set up, adding Pillarbox as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```swift
dependencies: [
    .package(
        url: "https://github.com/aplr/Pillarbox.git",
        .upToNextMajor(from: "1.0.0")
    )
]
```

## Documentation

Documentation is available [here](https://pillarbox.aplr.io) and provides a comprehensive documentation of the library's public interface. Expect usage examples and guides to be added shortly.

## License
Pillarbox is licensed under the [MIT License](https://github.com/aplr/Pillarbox/blob/main/LICENSE).
