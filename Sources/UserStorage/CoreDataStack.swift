import CoreData

public class CoreDataStack {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    public init(databaseURL: URL? = nil, inMemory: Bool = false) {
        let entity = NSEntityDescription()
        entity.name = "UserStorage"
        entity.managedObjectClassName = NSStringFromClass(UserStorage.self)

        // Attribute definieren
        let keyAttribute = NSAttributeDescription()
        keyAttribute.name = "key"
        keyAttribute.attributeType = .stringAttributeType
        keyAttribute.isOptional = false

        let valueAttribute = NSAttributeDescription()
        valueAttribute.name = "value"
        valueAttribute.attributeType = .stringAttributeType
        valueAttribute.isOptional = false

        entity.properties = [keyAttribute, valueAttribute]

        if #available(iOS 11.0, macOS 10.13, *) {
            let indexDescription = NSFetchIndexDescription(name: "\(entity.name!)_key_index", elements: [
                NSFetchIndexElementDescription(property: keyAttribute, collationType: .binary)
            ])
            entity.indexes = [indexDescription]
        } else {
            keyAttribute.isIndexed = true
        }

        let model = NSManagedObjectModel()
        model.entities = [entity]

        let containerName = "UserStorage"
        persistentContainer = NSPersistentContainer(name: containerName, managedObjectModel: model )

        if let url = databaseURL {
            let storeDescription = NSPersistentStoreDescription(url: url)
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        } else if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            persistentContainer.persistentStoreDescriptions = [description]
        } else {
            let defaultDirectory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            
            let defaultURL = defaultDirectory.appendingPathComponent("\(containerName).sqlite")
            let storeDescription = NSPersistentStoreDescription(url: defaultURL)
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        }

        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
    }

    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}
