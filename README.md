![Swift Version](https://img.shields.io/badge/Swift-5.0%2B-orange)
![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20iOS%20%7C%20iPadOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey)

# UserStorage

UserStorage is a Swift package that provides a thread-safe and versatile alternative to UserDefaults. While UserDefaults is limited to basic types, UserStorage allows you to store variables of any type, including complex structures, in a thread-safe manner. Additionally, it includes a property wrapper for creating UserSettings, which can be used both inside and outside of views, similar to Swift's AppStorage.

## Features

- **Thread Safety:** UserStorage is designed to be thread-safe, ensuring that your data remains consistent even when accessed from multiple threads.

- **Versatile:** Unlike UserDefaults, UserStorage can store variables of any type, including custom structures.

- **UserSettings Property Wrapper:** UserStorage includes a property wrapper called `@PublishedUserStorage` that makes it easy to create UserSettings. These settings can be used like Swift's built-in `@AppStorage` but are not limited to views and can be accessed from anywhere in your code.

## Installation

To use UserStorage in your project, follow these steps:

1. Add the UserStorage package to your project's dependencies in your `Package.swift` file:

   ```swift
   .package(url: "https://github.com/smart-byte/UserStorage.git", from: "0.1.0")
   ```

2. In your project, import the UserStorage module:

  ```swift
  import UserStorage
  ```

## Usage
### Storing and Retrieving Data
To store and retrieve data using UserStorage, follow these steps:

```swift
import UserStorage

// Store a value
UserStorage.shared.save("Hello, UserStorage!", forKey: "greeting")

// Retrieve the value
if let greeting: String = UserStorage.shared.load(forKey: "greeting" ) {
    print(greeting) // Output: Hello, UserStorage!
}
```

### Using UserSettings
UserSettings are a convenient way to manage application settings. Here's how you can use the `@PublishedUserStorage` property wrapper to create UserSettings:

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
}
```

```swift
import SwiftUI

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
import SwiftUI

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

The example above demonstrates how to create a UserSettingsModel that stores the a username, the app's theme, and whether or not the app has been launched before. The `@PublishedUserStorage` property wrapper is used to create the UserSettings. The `@PublishedUserStorage` property wrapper is a combination of Swift's built-in `@AppStorage` property wrapper and `@Published` property wrappers.
