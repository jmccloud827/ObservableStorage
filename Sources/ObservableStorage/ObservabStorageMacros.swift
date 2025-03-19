import Foundation
import KeychainManager

/// A macro that creates a property wrapper for storing and observing values in `UserDefaults`.
///
/// This macro generates a property wrapper that allows for automatic observation of changes
/// to the specified `UserDefaults` key. It provides getter and setter methods for the value
/// associated with that key.
///
/// - Parameters:
///   - key: The key under which the value is stored in `UserDefaults`.
///   - store: The `UserDefaults` instance to use for storage. Defaults to `.standard`.
@attached(accessor, names: named(get), named(set))
public macro ObservableAppStorage(key: String, store: UserDefaults = .standard) = #externalMacro(module: "ObservableStorageMacros",
                                                                                                  type: "ObservableAppStorageMacro")

/// A macro that creates a property wrapper for storing and observing values in the keychain.
///
/// This macro generates a property wrapper that allows for automatic observation of changes
/// to the specified key in the keychain. It provides getter and setter methods for the value
/// associated with that key.
///
/// - Parameters:
///   - key: The key under which the value is stored in the keychain.
///   - manager: An optional `KeychainManager` instance to use for storage. Defaults to `.shared`.
@attached(accessor, names: named(get), named(set))
public macro ObservableKeychain(key: String, manager: KeychainManager? = nil) = #externalMacro(module: "ObservableStorageMacros",
                                                                                                  type: "ObservableKeychainMacro")
