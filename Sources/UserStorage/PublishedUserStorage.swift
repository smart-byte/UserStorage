import SwiftUI
import Combine

@available(macOS 10.15, *)
public protocol PublishedUserStorageWrapper: class {
    var objectWillChange: ObservableObjectPublisher? { get set }
}

@available(macOS 10.15, *)
@propertyWrapper
public class PublishedUserStorage<T>: PublishedUserStorageWrapper where T: Codable {
    private var value: T
    private let key: String
    private var userStorageService = UserStorageService()
    public weak var objectWillChange: ObservableObjectPublisher?

    public init( wrappedValue defaultValue: T, _ key: String) {
        self.key = key
        self.value = userStorageService.load(key: key) ?? defaultValue
    }

    public var wrappedValue: T {
        get {
            value
        }
        set {
            value = newValue
            userStorageService.save( value, forKey: key)
            objectWillChange?.send()
        }
    }
}
