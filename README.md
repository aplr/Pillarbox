<h1>
    <img src="https://raw.githubusercontent.com/aplr/Pillarbox/main/Logo.png?token=AAIAWBDNQRUM6JJJWSYHN43ASPZJS" height="23" />
    Pillarbox
</h1>

![Build](https://github.com/aplr/Pillarbox/workflows/Build/badge.svg?branch=main)
![Documentation](https://github.com/aplr/Pillarbox/workflows/Documentation/badge.svg)

Pillarbox is an easy-to-use, object-based queue with support for iOS, tvOS and macOS, written purely in Swift. Push and pop operations are both in O(1). All writes are synchronous - this means data will be written to the disk before an operation returns. Furthermore, all operations are thread-safe and synchronized using a read-write lock. This allows for synchronized, concurrent access to read-operations while performing writes in serial.

## About Pillarbox

Pillarbox was originally conceived as a simple object queue that allows to persist unsent messages locally in an efficient and simple way which outlasts app crashes and restarts. For its storage layer, Pillarbox makes use of Pinterest's excellent [PINCache](https://github.com/pinterest/PINCache), which is a key/value store designed for persisting temporary objects on the disk. Beyond that, the [Deque](https://swift.org/blog/swift-collections/#deque) data structure from Apple's open source [swift-collections](https://github.com/apple/swift-collections) library is used in the internal realization of the queue.

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

## Usage

As a bare minimum, you have to specify the name of the Pillarbox which determines the queue file name, as well as the directory where the queue file is stored.

```swift
import Pillarbox

let url = URL(fileURLWithPath: "/path/to/your/app", isDirectory: true)

let pillarbox = Pillarbox<String>(name: "messages", url: url)

pillarbox.push("Hello")
pillarbox.push("World")

print(pillarbox.count)   // 2

print(pillarbox.pop())   // "Hello"
print(pillarbox.pop())   // "World"

print(pillarbox.isEmpty) // true
```

### Going LIFO

Pillarbox uses a FIFO queue internally per default. If you want to change that behaviour to LIFO, pass a customized `PillarboxConfiguration` object with the strategy adjusted like below.

```swift
let url = URL(fileURLWithPath: "/path/to/your/app", isDirectory: true)

let configuration = PillarboxConfiguration(strategy: .lifo)

let pillarbox = Pillarbox<String>(
    name: "messages",
    url: url,
    configuration: configuration
)

// ...
```

## Documentation

Documentation is available [here](https://pillarbox.aplr.io) and provides a comprehensive documentation of the library's public interface. Expect usage examples and guides to be added shortly.

## License

Pillarbox is licensed under the [MIT License](https://github.com/aplr/Pillarbox/blob/main/LICENSE).
