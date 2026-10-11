import CoreData

public class UserStorageService {
    private let coreDataStack: CoreDataStack

    public init( coreDataStack: CoreDataStack? = nil ) {
        self.coreDataStack = coreDataStack ?? CoreDataStack.shared
    }

    /// Why the store is not open; `nil` while it is. Check this to tell "unavailable" apart from
    /// "nothing stored": while it is non-nil, `load` returns `nil` for every key and `save` does nothing.
    public var loadFailure: StoreLoadFailure? { coreDataStack.loadFailure }

    /// Tries to open the store again; see `CoreDataStack.reload()` for what to do with the result.
    @discardableResult
    public func reload() -> StoreLoadFailure? { coreDataStack.reload() }

    public func load<T: Codable>( key: String) -> T? {
        guard let data = loadValue(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: Data(data.utf8)) else {
            return nil
        }
        return value
    }

    public func save<T: Codable>(_ object: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(object),
              let value = String(data: data, encoding: .utf8) else { return }
        saveValue(value, forKey: key)
    }

    /// The only place that hands out a context. Core Data terminates the process when a context
    /// without an open store saves, and a fallback location could later overwrite the real file,
    /// so an unavailable store gets no context at all.
    private func makeContext() -> NSManagedObjectContext? {
        coreDataStack.loadFailure == nil ? coreDataStack.newBackgroundContext() : nil
    }

    private func saveValue(_ value: String, forKey key: String) {
        guard let context = makeContext() else { return }
        context.performAndWait {
            let fetchRequest: NSFetchRequest<UserStorageEntity> = NSFetchRequest<UserStorageEntity>(entityName: "UserStorageEntity")
            fetchRequest.predicate = NSPredicate(format: "key == %@", key)

            do {
                let results = try context.fetch(fetchRequest)
                let storageValue: UserStorageEntity

                if let result = results.first {
                    storageValue = result
                } else {
                    storageValue = UserStorageEntity(context: context)
                    storageValue.key = key
                }

                storageValue.value = value
                try context.save()
            } catch {
                print("Error saving: \(error)")
            }
        }
    }

    private func loadValue(forKey key: String) -> String? {
        guard let context = makeContext() else { return nil }
        var resultValue: String?

        context.performAndWait {
            let fetchRequest: NSFetchRequest<UserStorageEntity> = NSFetchRequest<UserStorageEntity>(entityName: "UserStorageEntity")
            fetchRequest.predicate = NSPredicate(format: "key == %@", key)

            do {
                let results = try context.fetch(fetchRequest)
                if let storageValue = results.first {
                    resultValue = storageValue.value
                }
            } catch {
                print("Error loading: \(error)")
            }
        }

        return resultValue
    }
}
