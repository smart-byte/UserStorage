import XCTest
@testable import UserStorage

class PublishedUserStorageTests: XCTestCase {
    func testSaveAndLoadValue() {
        @PublishedUserStorage( "testKey") var testValue: String = "testValue"

        testValue = "newValue"

        let loadedValue = testValue

        XCTAssertEqual(loadedValue, "newValue", "The loaded value should match the stored value.")
    }

    func testSaveAndLoadComplexVariable() {
        struct ComplexStruct: Codable, Equatable {
            var boolValue: Bool
            var floatValue: Float
            var stringValue: String
            var arrayValue: [String]
        }

        @PublishedUserStorage( "testKey") var testValue: ComplexStruct = ComplexStruct(
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

        let loadedValue = testValue

        XCTAssertEqual(loadedValue, ComplexStruct(
            boolValue: false,
            floatValue: 4.321,
            stringValue: "newTestStringValue",
            arrayValue: ["newTestArrayValue1", "newTestArrayValue2"]
        ), "The loaded value should match the stored value.")
    }
}
