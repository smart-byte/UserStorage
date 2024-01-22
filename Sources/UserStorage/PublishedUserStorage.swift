import Foundation
import Combine

@propertyWrapper
struct PublishedUserStorage<T> where T: Codable {
    private var value: T
    private let key: String
    private var userStorageService = UserStorageService()

    init( wrappedValue defaultValue: T, _ key: String) {
        self.key = key
        self.value = userStorageService.load(key: key) ?? defaultValue
    }

    var wrappedValue: T {
        get {
            value
        }
        set {
            value = newValue
            userStorageService.save( value, forKey: key)
        }
    }
}
