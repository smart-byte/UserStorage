import XCTest
@testable import UserStorage

class CoreDataStackTests: XCTestCase {
    func testCoreDataStackInitialization() {
        let coreDataStack = CoreDataStack( inMemory: true )

        XCTAssertNotNil(coreDataStack.persistentContainer, "NSPersistentContainer not initialized")

        let storeType = coreDataStack.persistentContainer.persistentStoreDescriptions.first?.type
        XCTAssertEqual(storeType, NSInMemoryStoreType, "Store type not set correctly")
    }

    /// Every stack shares one model: a second model describing `UserStorageEntity` would make
    /// `+entity` ambiguous for the whole process (smart-byte/voila#264).
    func testStacksShareOneManagedObjectModel() {
        let first = CoreDataStack(inMemory: true)
        let second = CoreDataStack(inMemory: true)

        XCTAssertTrue(first.persistentContainer.managedObjectModel === second.persistentContainer.managedObjectModel)
    }
}
