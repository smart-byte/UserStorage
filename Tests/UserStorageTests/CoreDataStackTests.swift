import XCTest
@testable import UserStorage

class CoreDataStackTests: XCTestCase {
    func testCoreDataStackInitialization() {
        let coreDataStack = CoreDataStack( inMemory: true )

        XCTAssertNotNil(coreDataStack.persistentContainer, "NSPersistentContainer not initialized")

        let storeType = coreDataStack.persistentContainer.persistentStoreDescriptions.first?.type
        XCTAssertEqual(storeType, NSInMemoryStoreType, "Store type not set correctly")
    }
}
