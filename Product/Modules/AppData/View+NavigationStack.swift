import SwiftUI

private struct InNavigationStack: ViewModifier {

  func body(content: Content) -> some View {
    NavigationStack {
      content
    }
  }
}

public extension View {
  func inNavigationStack() -> some View {
    modifier(InNavigationStack())
  }
}
