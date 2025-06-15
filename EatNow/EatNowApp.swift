import SwiftUI

@main
struct EatNowApp: App {
    @StateObject private var dataStore = DataStore.shared
    @State private var selectedTab = 2 // 預設選中主頁 (索引為2)

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                OrderView()
                    .tabItem {
                        Label("點餐", systemImage: "cart")
                    }
                    .tag(0)
                ShopListView()
                    .tabItem {
                        Label("店家", systemImage: "bag")
                    }
                    .tag(1)
                HomeView()
                    .tabItem {
                        Label("主頁", systemImage: "house")
                    }
                    .tag(2)
                StatsView()
                    .tabItem {
                        Label("統計", systemImage: "chart.bar")
                    }
                    .tag(3)
                SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape")
                    }
                    .tag(4)
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