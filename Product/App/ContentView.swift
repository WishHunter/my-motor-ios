import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Главная")
                }
            
            MyMotorsView()
                .tabItem {
                    Image(systemName: "motorcycle")
                    Text("Мои мотоциклы")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
