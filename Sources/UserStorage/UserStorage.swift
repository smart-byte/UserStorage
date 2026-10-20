import CoreData

@objc(UserStorageEntity)
public class UserStorageEntity: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged public var value: String
}

public class UserStorage {
    public static let shared = UserStorage()

    private let service: UserStorageService

    public init(service: UserStorageService = UserStorageService()) {
        self.service = service
    }

    /// Why the store is not open; `nil` while it is. Check this to tell "unavailable" apart from
    /// "nothing stored": while it is non-nil, `load` returns `nil` for every key and `save` does nothing.
    public var loadFailure: StoreLoadFailure? { service.loadFailure }

    /// Tries to open the store again; see `CoreDataStack.reload()` for what to do with the result.
    @discardableResult
    public func reload() -> StoreLoadFailure? { service.reload() }

    public func save<T: Codable>(_ object: T, forKey key: String) {
        service.save(object, forKey: key)
    }

    public func load<T: Codable>(forKey key: String) -> T? {
        return service.load(key: key)
    }
}
