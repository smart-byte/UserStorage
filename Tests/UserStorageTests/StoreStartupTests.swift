import XCTest
@testable import UserStorage

/// Opening the store can fail (corrupt file, no permission, unusable location). These tests pin down
/// that this is reported instead of terminating the process, that the file on disk is never touched
/// while the store is unavailable, and that a retry recovers once the cause is gone.
///
/// Every test works in its own directory below the temporary directory and never touches the default
/// store (`CoreDataStack.shared` / `UserStorage.shared` in Application Support).
final class StoreStartupTests: XCTestCase {
    private var directory: URL!
    private var storeURL: URL { directory.appendingPathComponent("store.sqlite") }

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("UserStorageStartupTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        // A test that failed halfway may have left unreadable files behind.
        try? setPermissions(0o644)
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        try super.tearDownWithError()
    }

    // MARK: - Healthy

    func testHealthyStoreOpensAndPersistsAcrossStacks() {
        let stack = CoreDataStack(databaseURL: storeURL)
        UserStorageService(coreDataStack: stack).save("value", forKey: "key")

        XCTAssertNil(stack.loadFailure)
        close(stack)
        let reopened = CoreDataStack(databaseURL: storeURL)
        XCTAssertNil(reopened.loadFailure)
        XCTAssertEqual(UserStorageService(coreDataStack: reopened).load(key: "key") as String?, "value")
    }

    // MARK: - Failed initialization

    func testCorruptStoreFailsWithoutCrashingAndLeavesTheFileUntouched() throws {
        let corrupt = try writeCorruptStore()

        let stack = CoreDataStack(databaseURL: storeURL)

        let failure = try XCTUnwrap(stack.loadFailure)
        XCTAssertEqual(failure.storeURL?.path, storeURL.path)
        XCTAssertEqual(try Data(contentsOf: storeURL), corrupt)
        XCTAssertEqual(foreignFiles(), [], "no fallback store may appear next to the real one")
    }

    func testStoreBelowARegularFileFailsWithoutCreatingAnything() throws {
        let blocker = directory.appendingPathComponent("blocker")
        try Data("not a directory".utf8).write(to: blocker)

        let stack = CoreDataStack(databaseURL: blocker.appendingPathComponent("store.sqlite"))

        XCTAssertNotNil(stack.loadFailure)
        XCTAssertEqual(try Data(contentsOf: blocker), Data("not a directory".utf8))
        XCTAssertEqual(contents(), ["blocker"])
    }

    // MARK: - Unavailable means no writes

    func testUnavailableStoreDropsSavesAndNeverReadsThemBack() throws {
        let corrupt = try writeCorruptStore()
        let stack = CoreDataStack(databaseURL: storeURL)
        let service = UserStorageService(coreDataStack: stack)
        let storage = UserStorage(service: service)
        let filesBefore = contents()

        service.save("refused", forKey: "service")
        storage.save(42, forKey: "facade")

        // nil is also what "nothing stored" returns; a value coming back would expose a hidden
        // fallback store that pretends to persist.
        XCTAssertNil(service.load(key: "service") as String?)
        XCTAssertNil(storage.load(forKey: "facade") as Int?)
        XCTAssertNotNil(storage.loadFailure)
        XCTAssertEqual(try Data(contentsOf: storeURL), corrupt)
        XCTAssertEqual(contents(), filesBefore)
    }

    /// The container below is healthy and holds data; only the stack claims to be unavailable. The
    /// service has to trust the stack's state rather than whatever Core Data would still accept.
    func testServiceNeverTouchesAnOpenStoreWhileTheStackReportsFailure() throws {
        let seed = CoreDataStack(databaseURL: storeURL)
        UserStorageService(coreDataStack: seed).save("original", forKey: "key")
        close(seed)

        let stack = UnavailableStack(databaseURL: storeURL)
        let service = UserStorageService(coreDataStack: stack)
        service.save("overwrite", forKey: "key")
        XCTAssertNil(service.load(key: "key") as String?, "unavailable must read as nothing stored")
        close(stack)

        let reopened = UserStorageService(coreDataStack: CoreDataStack(databaseURL: storeURL))
        XCTAssertEqual(reopened.load(key: "key") as String?, "original")
    }

    func testPublishedUserStorageKeepsItsInMemoryValueWhileUnavailable() throws {
        let corrupt = try writeCorruptStore()
        let service = UserStorageService(coreDataStack: CoreDataStack(databaseURL: storeURL))

        @PublishedUserStorage("key", service: service) var value: String = "default"
        XCTAssertEqual(value, "default")
        value = "changed"

        XCTAssertEqual(value, "changed")
        XCTAssertEqual(try Data(contentsOf: storeURL), corrupt)
    }

    // MARK: - Recovery

    func testReloadSucceedsOnceTheCauseIsGoneAndDoesNotReplayDroppedSaves() throws {
        try writeCorruptStore()
        let stack = CoreDataStack(databaseURL: storeURL)
        let service = UserStorageService(coreDataStack: stack)
        XCTAssertNotNil(stack.loadFailure)
        service.save("dropped", forKey: "key")

        try FileManager.default.removeItem(at: storeURL)
        XCTAssertNil(stack.reload())

        XCTAssertNil(stack.loadFailure)
        XCTAssertNil(service.load(key: "key") as String?, "a save refused while unavailable must stay refused")
        service.save("kept", forKey: "key")
        close(stack)
        let reopened = UserStorageService(coreDataStack: CoreDataStack(databaseURL: storeURL))
        XCTAssertEqual(reopened.load(key: "key") as String?, "kept")
    }

    func testReloadWhileTheCauseRemainsKeepsTheStoreUnavailableAndUntouched() throws {
        let corrupt = try writeCorruptStore()
        let stack = CoreDataStack(databaseURL: storeURL)

        XCTAssertNotNil(stack.reload())

        XCTAssertNotNil(stack.loadFailure)
        XCTAssertEqual(try Data(contentsOf: storeURL), corrupt)
        XCTAssertEqual(foreignFiles(), [])
    }

    func testReloadOnAnOpenStoreIsANoOp() {
        let stack = CoreDataStack(databaseURL: storeURL)
        let service = UserStorageService(coreDataStack: stack)
        service.save("value", forKey: "key")

        // Core Data would reject adding the open store again ("Can't add the same store twice").
        XCTAssertNil(stack.reload())

        XCTAssertNil(stack.loadFailure)
        XCTAssertEqual(service.load(key: "key") as String?, "value")
    }

    func testConcurrentReloadsOpenTheStoreOnce() throws {
        try writeCorruptStore()
        let stack = CoreDataStack(databaseURL: storeURL)
        try FileManager.default.removeItem(at: storeURL)

        let lock = NSLock()
        var failedReloads = 0
        DispatchQueue.concurrentPerform(iterations: 8) { _ in
            if stack.reload() != nil {
                lock.lock()
                failedReloads += 1
                lock.unlock()
            }
        }

        XCTAssertEqual(failedReloads, 0)
        XCTAssertNil(stack.loadFailure)
    }

    /// A transient failure (here: the file is momentarily unreadable) must neither lose nor
    /// overwrite the healthy data behind it.
    func testTransientFailureLeavesHealthyDataIntactAndRecovers() throws {
        try XCTSkipIf(getuid() == 0, "root ignores file permissions, so the failure cannot be provoked")
        let seed = CoreDataStack(databaseURL: storeURL)
        UserStorageService(coreDataStack: seed).save("original", forKey: "key")
        close(seed)
        let snapshot = try snapshotOfAllFiles()

        try setPermissions(0o000)
        let stack = CoreDataStack(databaseURL: storeURL)
        let service = UserStorageService(coreDataStack: stack)
        XCTAssertNotNil(stack.loadFailure)
        service.save("overwrite", forKey: "key")
        try setPermissions(0o644)

        XCTAssertEqual(try snapshotOfAllFiles(), snapshot)
        XCTAssertNil(stack.reload())
        XCTAssertEqual(service.load(key: "key") as String?, "original")
    }

    func testServiceAndFacadeForwardFailureAndReload() throws {
        try writeCorruptStore()
        let service = UserStorageService(coreDataStack: CoreDataStack(databaseURL: storeURL))
        let storage = UserStorage(service: service)
        XCTAssertNotNil(service.loadFailure)
        XCTAssertNotNil(storage.loadFailure)

        try FileManager.default.removeItem(at: storeURL)
        XCTAssertNil(storage.reload())

        XCTAssertNil(service.loadFailure)
        XCTAssertNil(storage.loadFailure)
        storage.save("value", forKey: "key")
        XCTAssertEqual(storage.load(forKey: "key") as String?, "value")
    }

    // MARK: - Helpers

    private final class UnavailableStack: CoreDataStack {
        override var loadFailure: StoreLoadFailure? {
            StoreLoadFailure(storeURL: nil, underlying: CocoaError(.fileReadUnknown))
        }
    }

    /// Bytes that are not an SQLite database, so opening the file fails.
    @discardableResult
    private func writeCorruptStore() throws -> Data {
        let garbage = Data((0 ..< 8192).map { UInt8(truncatingIfNeeded: $0 &* 31 &+ 7) })
        try garbage.write(to: storeURL)
        return garbage
    }

    /// Closes the SQLite connection, like quitting the app would, so the next stack opens the file
    /// from scratch.
    private func close(_ stack: CoreDataStack) {
        let coordinator = stack.persistentContainer.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try? coordinator.remove(store)
        }
    }

    private func contents() -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []).sorted()
    }

    /// Anything besides the store and the `-wal` / `-shm` files SQLite keeps next to it.
    private func foreignFiles() -> [String] {
        let known: Set<String> = ["store.sqlite", "store.sqlite-wal", "store.sqlite-shm"]
        return contents().filter { !known.contains($0) }
    }

    private func snapshotOfAllFiles() throws -> [String: Data] {
        try Dictionary(uniqueKeysWithValues: contents().map {
            ($0, try Data(contentsOf: directory.appendingPathComponent($0)))
        })
    }

    private func setPermissions(_ mode: Int) throws {
        for name in contents() {
            try FileManager.default.setAttributes(
                [.posixPermissions: mode],
                ofItemAtPath: directory.appendingPathComponent(name).path
            )
        }
    }
}
