# ObservableAppStorageMacro

`ObservableStorage` is a Swift package that provides 2 macros
1. A macro for automatically generating accessors for properties that are stored in `UserDefaults`.
2. A macro for automatically generating accessors for properties that are stored in the keychain using my other package [`Keychain Manager`](https://github.com/jmccloud827/KeychainManager)

## Features

- Automatically generates getter and setter methods for properties stored in `UserDefaults` and `Keychain`.
- Supports optional and non-optional property types for `UserDefaults`.
- Integrates seamlessly with Swift's property observer system.
- Requires attributes to ensure proper usage and behavior.

## Requirements

- Swift 5.0+
- Xcode 12.0+

## Installation

You can add this package to your Xcode project using Swift Package Manager. Follow these steps:

1. Open your Xcode project.
2. Select `File` > `Swift Packages` > `Add Package Dependency`.
3. Enter the repository URL: `https://github.com/yourusername/ObservableStorage.git`.
4. Choose the version or branch you would like to use.
5. Click `Finish`.

## Usage

To use the `@ObservableAppStorage` or `@ObservableKeychain` macro, simply annotate your variable with the macro and provide the necessary parameters.

### Example
```swift
import ObservableStorage

@ObservationIgnored
@ObservableAppStorage(key: "username")
var username: String = "Guest"

@MainActor
@ObservationIgnored
@ObservableKeychain(key: "password")
var password: String = "Some Secure Passowrd"
```

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
