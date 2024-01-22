import Foundation
import Combine

@propertyWrapper
public struct PublishedUserStorage<T> where T: Codable {
    private var value: T
    private let key: String
    private var userStorageService = UserStorageService()

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
        }
    }
}
