import SwiftUI

@main
struct EatNowApp: App {
    @StateObject private var dataStore = DataStore.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("主頁", systemImage: "house")
                    }
                ShopListView()
                    .tabItem {
                        Label("店家", systemImage: "bag")
                    }
                StatsView()
                    .tabItem {
                        Label("統計", systemImage: "chart.bar")
                    }
                SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape")
                    }
            }
            .environmentObject(dataStore)
        }
    }
}

// Preview for ShopListView
struct ShopListView_Previews: PreviewProvider {
    static var previews: some View {
        ShopListView()
            .environmentObject(DataStore.shared)
    }
} 