import SwiftUI

/// The entry point of the Listler app.
///
/// `@main` marks this type as the application's starting point. It conforms to
/// the `App` protocol, which defines the app's scenes (windows) and overall
/// lifecycle using SwiftUI.
///
/// The `body` returns a `Scene` that describes the app's UI structure. Here we
/// use `WindowGroup`, which creates the main app window(s) and hosts our root
/// view, `ContentView()`. From there, the rest of the UI is built.
@main
struct ListlerApp: App {
  /// Describes the scenes (windows) that make up the app's UI.
  var body: some Scene {
    // `WindowGroup` manages one or more windows for the app (for example,
    // multiple windows on iPad or macOS). Each window starts with `ContentView`
    // as its root SwiftUI view.
    WindowGroup {
      ContentView()
    }
  }
}
