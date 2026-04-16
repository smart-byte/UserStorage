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

    public func save<T: Codable>(_ object: T, forKey key: String) {
        service.save(object, forKey: key)
    }

    public func load<T: Codable>(forKey key: String) -> T? {
        return service.load(key: key)
    }
}
