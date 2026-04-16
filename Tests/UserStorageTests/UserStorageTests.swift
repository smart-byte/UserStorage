import XCTest
@testable import UserStorage

class PublishedUserStorageTests: XCTestCase {
    var service: UserStorageService!

    override func setUp() {
        super.setUp()
        let stack = CoreDataStack(inMemory: true)
        service = UserStorageService(coreDataStack: stack)
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testSaveAndLoadString() {
        @PublishedUserStorage("stringKey", service: service) var testValue: String = "default"

        testValue = "newValue"

        XCTAssertEqual(testValue, "newValue")
    }

    func testSaveAndLoadBool() {
        @PublishedUserStorage("boolKey", service: service) var testValue: Bool = false

        testValue = true

        XCTAssertEqual(testValue, true)
    }

    func testSaveAndLoadInt() {
        @PublishedUserStorage("intKey", service: service) var testValue: Int = 0

        testValue = 42

        XCTAssertEqual(testValue, 42)
    }

    func testSaveAndLoadDouble() {
        @PublishedUserStorage("doubleKey", service: service) var testValue: Double = 0.0

        testValue = 3.14159

        XCTAssertEqual(testValue, 3.14159)
    }

    func testSaveAndLoadFloat() {
        @PublishedUserStorage("floatKey", service: service) var testValue: Float = 0.0

        testValue = 1.234

        XCTAssertEqual(testValue, 1.234)
    }

    func testSaveAndLoadArray() {
        @PublishedUserStorage("arrayKey", service: service) var testValue: [String] = []

        testValue = ["one", "two", "three"]

        XCTAssertEqual(testValue, ["one", "two", "three"])
    }

    func testSaveAndLoadDictionary() {
        @PublishedUserStorage("dictKey", service: service) var testValue: [String: Int] = [:]

        testValue = ["a": 1, "b": 2]

        XCTAssertEqual(testValue, ["a": 1, "b": 2])
    }

    func testSaveAndLoadEnum() {
        enum AppTheme: String, Codable {
            case light
            case dark
        }

        @PublishedUserStorage("enumKey", service: service) var testValue: AppTheme = .light

        testValue = .dark

        XCTAssertEqual(testValue, .dark)
    }

    func testSaveAndLoadComplexStruct() {
        struct ComplexStruct: Codable, Equatable {
            var boolValue: Bool
            var floatValue: Float
            var stringValue: String
            var arrayValue: [String]
        }

        @PublishedUserStorage("complexKey", service: service) var testValue: ComplexStruct = ComplexStruct(
            boolValue: true,
            floatValue: 1.234,
            stringValue: "testStringValue",
            arrayValue: ["testArrayValue1", "testArrayValue2"]
        )

        testValue = ComplexStruct(
            boolValue: false,
            floatValue: 4.321,
            stringValue: "newTestStringValue",
            arrayValue: ["newTestArrayValue1", "newTestArrayValue2"]
        )

        XCTAssertEqual(testValue, ComplexStruct(
            boolValue: false,
            floatValue: 4.321,
            stringValue: "newTestStringValue",
            arrayValue: ["newTestArrayValue1", "newTestArrayValue2"]
        ))
    }

    func testDefaultValueUsedWhenNoStoredValue() {
        @PublishedUserStorage("missingKey", service: service) var testValue: String = "defaultValue"

        XCTAssertEqual(testValue, "defaultValue")
    }
}

class UserStorageFacadeTests: XCTestCase {
    var storage: UserStorage!

    override func setUp() {
        super.setUp()
        let stack = CoreDataStack(inMemory: true)
        let service = UserStorageService(coreDataStack: stack)
        storage = UserStorage(service: service)
    }

    override func tearDown() {
        storage = nil
        super.tearDown()
    }

    func testSaveAndLoadString() {
        storage.save("Hello, UserStorage!", forKey: "greeting")

        let loaded: String? = storage.load(forKey: "greeting")

        XCTAssertEqual(loaded, "Hello, UserStorage!")
    }

    func testSaveAndLoadBool() {
        storage.save(true, forKey: "flag")

        let loaded: Bool? = storage.load(forKey: "flag")

        XCTAssertEqual(loaded, true)
    }

    func testSaveAndLoadInt() {
        storage.save(42, forKey: "count")

        let loaded: Int? = storage.load(forKey: "count")

        XCTAssertEqual(loaded, 42)
    }

    func testSaveAndLoadDouble() {
        storage.save(3.14159, forKey: "pi")

        let loaded: Double? = storage.load(forKey: "pi")

        XCTAssertEqual(loaded, 3.14159)
    }

    func testSaveAndLoadFloat() {
        storage.save(Float(1.234), forKey: "floatVal")

        let loaded: Float? = storage.load(forKey: "floatVal")

        XCTAssertEqual(loaded, 1.234)
    }

    func testSaveAndLoadArray() {
        storage.save(["a", "b", "c"], forKey: "list")

        let loaded: [String]? = storage.load(forKey: "list")

        XCTAssertEqual(loaded, ["a", "b", "c"])
    }

    func testSaveAndLoadDictionary() {
        storage.save(["key1": 1, "key2": 2], forKey: "dict")

        let loaded: [String: Int]? = storage.load(forKey: "dict")

        XCTAssertEqual(loaded, ["key1": 1, "key2": 2])
    }

    func testSaveAndLoadEnum() {
        enum AppTheme: String, Codable {
            case light
            case dark
        }

        storage.save(AppTheme.dark, forKey: "theme")

        let loaded: AppTheme? = storage.load(forKey: "theme")

        XCTAssertEqual(loaded, .dark)
    }

    func testSaveAndLoadComplexStruct() {
        struct Settings: Codable, Equatable {
            var name: String
            var enabled: Bool
            var tags: [String]
        }

        let settings = Settings(name: "test", enabled: true, tags: ["a", "b"])
        storage.save(settings, forKey: "settings")

        let loaded: Settings? = storage.load(forKey: "settings")

        XCTAssertEqual(loaded, settings)
    }

    func testOverwriteExistingValue() {
        storage.save("first", forKey: "key")
        storage.save("second", forKey: "key")

        let loaded: String? = storage.load(forKey: "key")

        XCTAssertEqual(loaded, "second")
    }

    func testLoadNonExistentKeyReturnsNil() {
        let loaded: String? = storage.load(forKey: "nonexistent")

        XCTAssertNil(loaded)
    }
}
