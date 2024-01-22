import CoreData

@objc(UserStorage)
public class UserStorage: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged public var value: String
}
