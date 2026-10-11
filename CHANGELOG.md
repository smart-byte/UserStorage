# Changelog

## Unreleased

### Fixed

- `CoreDataStack` no longer terminates the process (`fatalError`) when the persistent store cannot be opened, for example because the file is corrupt, unreadable or in an unusable location. The failure is recorded and the file on disk is left untouched.
- The lookup of the default store location no longer force-unwraps.

### Added

- `loadFailure` on `UserStorage`, `UserStorageService` and `CoreDataStack` returns a `StoreLoadFailure?` (`storeURL`, `underlying`), so an unavailable store can be told apart from an empty one.
- `reload()` on the same types opens the store again once the cause is gone. It does nothing on a store that is already open.

### Changed

- While the store is unavailable, `load` returns `nil` and `save` is dropped. Nothing is written to a fallback location, and no Core Data context is handed out, because Core Data terminates the process when a context without an open store saves.
