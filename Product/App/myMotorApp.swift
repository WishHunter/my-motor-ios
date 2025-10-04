import SwiftUI

@main
struct myMotorApp: App {
    var body: some Scene {
        WindowGroup {
          Authorization {
            ContentView()
          } nonAuthenticated: {
            AddMotorView()
          }
        }
    }
}
