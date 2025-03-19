import ObservableStorage
import SwiftUI
import KeychainManager

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, macCatalyst 17.0, visionOS 1.0, *)
@Observable
final class Person {
    nonisolated(unsafe) static let store = UserDefaults(suiteName: "NewStore")!
    
    @ObservableAppStorage(key: "String")
    @ObservationIgnored
    var string: String = "Test"
    
    @ObservableAppStorage(key: "Int", store: Self.store)
    @ObservationIgnored
    var int: Int = 0
    
    @ObservableAppStorage(key: "OptionalDate")
    @ObservationIgnored
    var date: Date?
    
    @ObservableAppStorage(key: "Array", store: Self.store)
    @ObservationIgnored
    var array: [String] = ["Test", "Test 2"]
    
    @ObservableAppStorage(key: "OptionalArray")
    @ObservationIgnored
    var dates: [Date]?
    
    @ObservableAppStorage(key: "Dictionary", store: Self.store)
    @ObservationIgnored
    var dict: [String: String] = ["Test": "Value"]
    
    @ObservableKeychain(key: "StringKeychain")
    @MainActor
    @ObservationIgnored
    var stringKeychain: String = "Test"
    
    @ObservableKeychain(key: "StringWithManager", manager: .init(accessGroup: "test"))
    @MainActor
    @ObservationIgnored
    var stringKeychainWithManager: String = "Test"
}
