import SwiftUI
import Factory

struct Authorization<Authorized: View, NonAuthenticated: View>: View {
  @InjectedObject(\.motorsSession) private var motorSession: MotorsSession

  @ViewBuilder var authorized: () -> Authorized
  @ViewBuilder var nonAuthenticated: () -> NonAuthenticated

  var body: some View {
    if motorSession.mainMotor != nil {
      authorized()
    } else {
      nonAuthenticated()
    }
  }
}

#Preview {
  Authorization(authorized: { Text("Authorized") }, nonAuthenticated: { Text("UnAuthorized") })
}
