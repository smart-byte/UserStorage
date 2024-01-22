import XCTest
@testable import UserStorage

class UserStorageServiceTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var userStorageService: UserStorageService!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack( databaseURL: temporaryURL(), inMemory: false )
        userStorageService = UserStorageService(coreDataStack: coreDataStack )
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSaveAndLoadValue() {
        let testKey = "testKey"
        let testValue = "testValue"

        userStorageService.save(testValue, forKey: testKey)

        if let loadedValue: String = userStorageService.load(key: testKey ) {
            XCTAssertEqual(loadedValue, testValue, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }
    }

    func testSaveAndLoadValueWithDifferentKey() {
        let testKey = "testKey"
        let testValue = "testValue"
        let testKey2 = "testKey2"
        let testValue2 = "testValue2"

        userStorageService.save(testValue, forKey: testKey)
        userStorageService.save(testValue2, forKey: testKey2)

        if let loadedValue: String = userStorageService.load(key: testKey) {
            XCTAssertEqual(loadedValue, testValue, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }

        if let loadedValue: String = userStorageService.load(key: testKey2) {
            XCTAssertEqual(loadedValue, testValue2, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }
    }

    func testSaveAndLoadValueWithSameKey() {
        let testKey = "testKey"
        let testValue = "testValue"
        let testValue2 = "testValue2"

        userStorageService.save(testValue, forKey: testKey)
        userStorageService.save(testValue2, forKey: testKey)

        if let loadedValue: String = userStorageService.load(key: testKey) {
            XCTAssertEqual(loadedValue, testValue2, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }
    }

    func testSaveAndLoadBoolFloatSringArrayTypes() {
        let testBoolKey = "testKey"
        let testBoolValue = true

        let testFloatKey = "testFloatKey"
        let testFloatValue: Float = 1.234

        let testStringKey = "testStringKey"
        let testStringValue = "testStringValue"

        let testArrayKey = "testArrayKey"
        let testArrayValue = ["testArrayValue1", "testArrayValue2"]

        userStorageService.save(testBoolValue, forKey: testBoolKey)
        userStorageService.save(testFloatValue, forKey: testFloatKey)
        userStorageService.save(testStringValue, forKey: testStringKey)
        userStorageService.save(testArrayValue, forKey: testArrayKey)

        if let loadedValue: Bool = userStorageService.load(key: testBoolKey) {
            XCTAssertEqual(loadedValue, testBoolValue, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }

        if let loadedValue: Float = userStorageService.load(key: testFloatKey) {
            XCTAssertEqual(loadedValue, testFloatValue, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }

        if let loadedValue: String = userStorageService.load(key: testStringKey) {
            XCTAssertEqual(loadedValue, testStringValue, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }

        if let loadedValue: [String] = userStorageService.load(key: testArrayKey) {
            XCTAssertEqual(loadedValue, testArrayValue, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }
    }

    func testSaveAndLoadComplexStruct() {
        struct ComplexStruct: Codable, Equatable {
            var boolValue: Bool
            var floatValue: Float
            var stringValue: String
            var arrayValue: [String]
        }
        
        let testKey = "testKey"
        let testValue = ComplexStruct( boolValue: true, floatValue: 1.234, stringValue: "testStringValue", arrayValue: ["testArrayValue1", "testArrayValue2"])

        userStorageService.save(testValue, forKey: testKey)

        if let loadedValue: ComplexStruct = userStorageService.load(key: testKey) {
            XCTAssertEqual(loadedValue, testValue, "The loaded value should match the stored value.")
        } else {
            XCTFail("The value could not be loaded or is nil.")
        }
    }

    func temporaryURL() -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFilename = "UserStorageTest.sqlite"
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
        return temporaryFileURL
    }
}
