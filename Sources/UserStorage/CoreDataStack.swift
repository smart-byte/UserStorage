import CoreData

public class CoreDataStack {
    public static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    private let stateLock = NSLock()
    private var failure: StoreLoadFailure?

    /// Why the persistent store is not open; `nil` while it is.
    ///
    /// While this is non-nil the stack is unavailable: `UserStorageService` returns `nil` for every
    /// load and drops every save, so nothing is ever written to a fallback location or over the
    /// stored data. Do not use `viewContext` / `newBackgroundContext()` in that state: Core Data
    /// terminates the process when a context without an open store saves.
    public var loadFailure: StoreLoadFailure? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return failure
    }

    /// One model for every stack in the process. Each loaded model that describes
    /// `UserStorageEntity` claims its class, so a second model (say an in-memory stack in tests next
    /// to `shared`) makes `+entity` ambiguous and Core Data warns about it.
    private static let model: NSManagedObjectModel = {
        let entity = NSEntityDescription()
        entity.name = "UserStorageEntity"
        entity.managedObjectClassName = NSStringFromClass(UserStorageEntity.self)

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
        return model
    }()

    public init(databaseURL: URL? = nil, inMemory: Bool = false) {
        let containerName = "UserStorage"
        persistentContainer = NSPersistentContainer(name: containerName, managedObjectModel: Self.model)

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
            ).first ?? NSPersistentContainer.defaultDirectoryURL()

            let defaultURL = defaultDirectory.appendingPathComponent("\(containerName).sqlite")
            let storeDescription = NSPersistentStoreDescription(url: defaultURL)
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        }

        failure = openStores()
    }

    /// Tries to open the store again, for example after the user freed disk space, fixed the
    /// permissions or moved a corrupt file away. Returns the remaining failure, or `nil` once the
    /// store is open. Calling it on an open stack does nothing.
    ///
    /// Everything read while the stack was unavailable was `nil`. A caller that kept defaults in
    /// memory for that reason must re-read its state after a successful reload; otherwise its next
    /// `save` replaces the stored data with those defaults.
    @discardableResult
    public func reload() -> StoreLoadFailure? {
        stateLock.lock()
        defer { stateLock.unlock() }
        // Core Data rejects adding an open store a second time ("Can't add the same store twice").
        guard failure != nil else { return nil }
        failure = openStores()
        return failure
    }

    /// Relies on the default synchronous store loading: the handler has run before this returns.
    private func openStores() -> StoreLoadFailure? {
        var result: StoreLoadFailure?
        persistentContainer.loadPersistentStores { description, error in
            if let error = error, result == nil {
                result = StoreLoadFailure(storeURL: description.url, underlying: error)
            }
        }
        return result
    }

    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}
