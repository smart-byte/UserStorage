import CoreData

public class UserStorageService {
    private let coreDataStack: CoreDataStack

    public init( coreDataStack: CoreDataStack? = nil ) {
        self.coreDataStack = coreDataStack ?? CoreDataStack.shared
    }

    public func load<T: Codable>( key: String) -> T? {
        guard let data = loadValue(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: Data(data.utf8)) else {
            return nil
        }
        return value
    }

    public func save<T: Codable>(_ object: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(object) {
            saveValue(String(data: data, encoding: .utf8)!, forKey: key)
        }
    }

    private func saveValue(_ value: String, forKey key: String) {
        let context = coreDataStack.newBackgroundContext()
        context.performAndWait {
            let fetchRequest: NSFetchRequest<UserStorage> = NSFetchRequest<UserStorage>(entityName: "UserStorage")
            fetchRequest.predicate = NSPredicate(format: "key == %@", key)

            do {
                let results = try context.fetch(fetchRequest)
                let storageValue: UserStorage

                if let result = results.first {
                    storageValue = result
                } else {
                    storageValue = UserStorage(context: context)
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
        let context = coreDataStack.newBackgroundContext()
        var resultValue: String?

        context.performAndWait {
            let fetchRequest: NSFetchRequest<UserStorage> = NSFetchRequest<UserStorage>(entityName: "UserStorage")
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
