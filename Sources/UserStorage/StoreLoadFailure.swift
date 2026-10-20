import Foundation

/// Why the persistent store could not be opened.
///
/// Reported through `loadFailure` instead of terminating the process, so the caller can decide
/// whether to continue without persistence, ask the user, or quit. The file at `storeURL` is
/// never modified, moved or deleted by the package.
public struct StoreLoadFailure: Sendable {
    /// The on-disk location Core Data tried to open (nil if it reported none).
    public let storeURL: URL?

    /// The error Core Data reported, unmodified.
    public let underlying: Error
}
