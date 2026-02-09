import SwiftUI

struct ContentView: View {
  // Выбираем вкладку по умолчанию — Dashboard
  @State private var selectedTab: Tab = .dashboard

  enum Tab: Hashable {
    case history
    case dashboard
    case myMotors
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      ServiceListView()
        .tabItem {
          Image(systemName: "wrench.and.screwdriver")
          Text("История")
        }
        .tag(Tab.history)

      DashboardView()
        .tabItem {
          Image(systemName: "house.fill")
          Text("Главная")
        }
        .tag(Tab.dashboard)

      MyMotorsView()
        .tabItem {
          Image(systemName: "motorcycle")
          Text("Мои мотоциклы")
        }
        .tag(Tab.myMotors)
    }
    .accentColor(.blue)
  }
}

#Preview {
  ContentView()
}
