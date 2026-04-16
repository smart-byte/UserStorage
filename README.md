![Swift Version](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20iOS%20%7C%20iPadOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey)
![License](https://img.shields.io/badge/License-MIT-blue)

# UserStorage

A lightweight Swift package for persistent key-value storage — powered by CoreData. Unlike `UserDefaults`, which is limited to property list types (`String`, `Int`, `Bool`, `Data`, `Date`, `Array`, `Dictionary`), UserStorage can persist **any `Codable` type**, including custom structs and enums, in a thread-safe SQLite-backed store.

It also ships with `@PublishedUserStorage`, a property wrapper that works like `@AppStorage` — but isn't limited to SwiftUI views and supports any `Codable` type.

## Why not just UserDefaults?

| | UserDefaults | UserStorage |
|---|---|---|
| Supported types | Property list types only | Any `Codable` type |
| Storage backend | plist file | SQLite (CoreData) |
| Thread safety | Not guaranteed | `performAndWait` on background contexts |
| SwiftUI integration | `@AppStorage` (views only) | `@PublishedUserStorage` (anywhere) |
| Custom structs/enums | Manual serialization needed | Works out of the box |

## Installation

Add UserStorage to your `Package.swift`:

```swift
.package(url: "https://github.com/smart-byte/UserStorage.git", from: "0.2.0")
```

Then import it:

```swift
import UserStorage
```

## Usage

### Storing and Retrieving Data

```swift
import UserStorage

// Store a value
UserStorage.shared.save("Hello, UserStorage!", forKey: "greeting")

// Retrieve the value
if let greeting: String = UserStorage.shared.load(forKey: "greeting") {
    print(greeting) // Output: Hello, UserStorage!
}

// Works with any Codable type
struct UserProfile: Codable {
    var name: String
    var age: Int
    var tags: [String]
}

let profile = UserProfile(name: "Mario", age: 30, tags: ["swift", "ios"])
UserStorage.shared.save(profile, forKey: "profile")

let loaded: UserProfile? = UserStorage.shared.load(forKey: "profile")
```

### Using @PublishedUserStorage

`@PublishedUserStorage` is a property wrapper that combines the persistence of `@AppStorage` with the reactivity of `@Published`. It can be used in any `ObservableObject` — not just SwiftUI views.

```swift
import SwiftUI
import UserStorage

class UserSettingsModel: ObservableObject {
    @PublishedUserStorage("username")
    var username = "none"

    @PublishedUserStorage("appTheme")
    var appTheme = AppTheme.light

    @PublishedUserStorage("isFirstLaunch")
    var isFirstLaunch = true

    enum AppTheme: String, Codable {
        case light
        case dark
    }
    
    init() {
        // Required: connect property wrapper publishers to ObservableObject
        let mirror = Mirror(reflecting: self)
        mirror.children.forEach { child in
            if let observedProperty = child.value as? PublishedUserStorageWrapper {
                observedProperty.objectWillChange = self.objectWillChange
            }
        }
    }
}
```

Then use it in your app like any other `ObservableObject`:

```swift
@main
struct ExampleApp: App {
    @StateObject var userSettings = UserSettingsModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
        }
    }
}
```

```swift
struct ContentView: View {
    @EnvironmentObject var userSettings: UserSettingsModel

    var body: some View {
        VStack {
            Text("Hello, \(userSettings.username)!")
            Button(action: {
                userSettings.username = "User"
            }) {
                Text("Change Username")
            }
        }
    }
}
```

## License

MIT — see [LICENSE](LICENSE) for details.
