import SwiftUI
import Charts

// MARK: - 統計頁面
struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 頂部切換標籤
                Picker("統計類型", selection: $selectedTab) {
                    Text("總覽").tag(0)
                    Text("食物").tag(1)
                    Text("店家").tag(2)
                    Text("食物排名").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TabView(selection: $selectedTab) {
                    OverviewStatsView()
                        .tag(0)
                    
                    PersonalStatsView()
                        .tag(1)
                    
                    GroupStatsView()
                        .tag(2)
                    
                    FoodRankingView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .navigationTitle("統計")
        }
    }
}

// MARK: - 總覽統計
struct OverviewStatsView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 卡片1：總使用統計
                StatsCard(title: "總使用統計") {
                    HStack(spacing: 20) {
                        StatItemView(
                            icon: "dot.circle.and.hand.point.up.left.fill",
                            value: "\(dataStore.personalRandomCount + dataStore.groupRandomCount)",
                            title: "總點擊次數"
                        )
                        
                        StatItemView(
                            icon: "checkmark.circle",
                            value: "\(dataStore.totalDecisionsMade)",
                            title: "解決選擇障礙"
                        )
                    }
                }
                
                // 卡片2：食物 vs 店家使用比例
                StatsCard(title: "食物 vs 店家使用比例") {
                    let personalCount = dataStore.personalRandomCount
                    let groupCount = dataStore.groupRandomCount
                    let total = personalCount + groupCount
                    
                    if total > 0 {
                        if #available(iOS 16.0, *) {
                            Chart {
                                SectorMark(
                                    angle: .value("使用次數", personalCount),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(.blue)
                                .annotation(position: .overlay) {
                                    Text("\(Int(Double(personalCount) / Double(total) * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                }
                                
                                SectorMark(
                                    angle: .value("使用次數", groupCount),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(.purple)
                                .annotation(position: .overlay) {
                                    Text("\(Int(Double(groupCount) / Double(total) * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(height: 200)
                            
                            HStack(spacing: 20) {
                                ChartLegend(color: .blue, text: "食物模式")
                                ChartLegend(color: .purple, text: "店家模式")
                            }
                        } else {
                            // iOS 16以下的替代UI
                            VStack(spacing: 15) {
                                Text("食物模式: \(personalCount)次 (\(Int(Double(personalCount) / Double(total) * 100))%)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading)
                                    .foregroundColor(.blue)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: geometry.size.width, height: 20)
                                            .cornerRadius(10)
                                        
                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(width: CGFloat(personalCount) / CGFloat(total) * geometry.size.width, height: 20)
                                            .cornerRadius(10)
                                    }
                                }
                                .frame(height: 20)
                                
                                Text("店家模式: \(groupCount)次 (\(Int(Double(groupCount) / Double(total) * 100))%)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading)
                                    .foregroundColor(.purple)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: geometry.size.width, height: 20)
                                            .cornerRadius(10)
                                        
                                        Rectangle()
                                            .fill(Color.purple)
                                            .frame(width: CGFloat(groupCount) / CGFloat(total) * geometry.size.width, height: 20)
                                            .cornerRadius(10)
                                    }
                                }
                                .frame(height: 20)
                            }
                            .frame(height: 200)
                        }
                    } else {
                        Text("尚無使用數據")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }
                
                // 卡片3：最常吃的食物
                StatsCard(title: "最常吃的食物") {
                    if let topFood = dataStore.foodSelections.sorted(by: { $0.value > $1.value }).first {
                        VStack(spacing: 10) {
                            Text("🏆 \(topFood.key)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("已選擇 \(topFood.value) 次")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Text("尚無食物選擇記錄")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 個人統計
struct PersonalStatsView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 卡片1：食物模式使用統計
                StatsCard(title: "食物模式使用統計") {
                    VStack {
                        HStack(spacing: 20) {
                            StatItemView(
                                icon: "shuffle",
                                value: "\(dataStore.personalRandomCount)",
                                title: "隨機推薦次數"
                            )
                            
                            StatItemView(
                                icon: "checkmark.circle",
                                value: "\(dataStore.personalDecisionsMade)",
                                title: "決定採納次數"
                            )
                        }
                        
                        if dataStore.personalRandomCount > 0 {
                            // 轉換率
                            let conversionRate = Double(dataStore.personalDecisionsMade) / Double(dataStore.personalRandomCount) * 100
                            
                            HStack {
                                Text("選擇採納率")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f%%", conversionRate))
                                    .fontWeight(.semibold)
                            }
                            .padding(.top)
                            
                            // 進度條
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: geometry.size.width, height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: min(CGFloat(conversionRate) / 100 * geometry.size.width, geometry.size.width), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
                
                // 使用趨勢圖
                StatsCard(title: "決定採納趨勢") {
                    if dataStore.personalRandomCount > 0 {
                        if #available(iOS 16.0, *) {
                            Chart {
                                LineMark(
                                    x: .value("日期", 1),
                                    y: .value("次數", dataStore.personalRandomCount / 2)
                                )
                                LineMark(
                                    x: .value("日期", 2),
                                    y: .value("次數", dataStore.personalRandomCount / 3)
                                )
                                LineMark(
                                    x: .value("日期", 3),
                                    y: .value("次數", dataStore.personalRandomCount / 4)
                                )
                                LineMark(
                                    x: .value("日期", 4),
                                    y: .value("次數", dataStore.personalRandomCount)
                                )
                            }
                            .frame(height: 200)
                        } else {
                            // iOS 16以下的替代UI
                            VStack(spacing: 10) {
                                Text("使用趨勢圖 (需要iOS 16以上版本)")
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 0) {
                                    Text("總計使用次數：\(dataStore.personalRandomCount)次")
                                        .foregroundColor(.primary)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                            .frame(height: 200)
                        }
                    } else {
                        Text("尚無使用數據")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 團體統計
struct GroupStatsView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 店家模式使用統計
                StatsCard(title: "店家模式使用統計") {
                    VStack {
                        HStack(spacing: 20) {
                            StatItemView(
                                icon: "person.3",
                                value: "\(dataStore.groupRandomCount)",
                                title: "隨機店家次數"
                            )
                            
                            StatItemView(
                                icon: "checkmark.circle",
                                value: "\(dataStore.groupDecisionsMade)",
                                title: "決定採納次數"
                            )
                        }
                        
                        if dataStore.groupRandomCount > 0 {
                            // 轉換率
                            let conversionRate = Double(dataStore.groupDecisionsMade) / Double(dataStore.groupRandomCount) * 100
                            
                            HStack {
                                Text("選擇採納率")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f%%", conversionRate))
                                    .fontWeight(.semibold)
                            }
                            .padding(.top)
                            
                            // 進度條
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: geometry.size.width, height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.orange, .red]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: min(CGFloat(conversionRate) / 100 * geometry.size.width, geometry.size.width), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
                
                // 店家選擇分布
                StatsCard(title: "店家選擇分布") {
                    if dataStore.shopSelections.isEmpty {
                        Text("尚無店家選擇記錄")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    } else {
                        let sortedShops = dataStore.shopSelections.sorted(by: { $0.value > $1.value }).prefix(5)
                        
                        if #available(iOS 16.0, *) {
                            Chart {
                                ForEach(Array(sortedShops.enumerated()), id: \.element.key) { index, shop in
                                    BarMark(
                                        x: .value("次數", shop.value),
                                        y: .value("店家", shop.key)
                                    )
                                    .foregroundStyle(
                                        Color(hue: Double(index) / Double(sortedShops.count), saturation: 0.8, brightness: 0.8)
                                    )
                                }
                            }
                            .frame(height: min(CGFloat(sortedShops.count * 40 + 40), 200))
                        } else {
                            // iOS 16以下的替代UI
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(sortedShops.enumerated()), id: \.element.key) { index, shop in
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(shop.key)
                                            .font(.subheadline)
                                        
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                Rectangle()
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: geometry.size.width, height: 20)
                                                    .cornerRadius(5)
                                                
                                                Rectangle()
                                                    .fill(Color(hue: Double(index) / Double(sortedShops.count), saturation: 0.8, brightness: 0.8))
                                                    .frame(width: CGFloat(shop.value) * 30, height: 20)
                                                    .cornerRadius(5)
                                                
                                                Text("\(shop.value)次")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(.leading, 5)
                                            }
                                        }
                                        .frame(height: 20)
                                    }
                                }
                            }
                            .frame(height: min(CGFloat(sortedShops.count * 40 + 40), 200))
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 食物排名
struct FoodRankingView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StatsCard(title: "食物排名") {
                    if dataStore.foodSelections.isEmpty {
                        Text("尚無食物選擇記錄")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    } else {
                        let sortedFood = dataStore.foodSelections.sorted(by: { $0.value > $1.value })
                        
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(Array(sortedFood.enumerated().prefix(5)), id: \.element.key) { index, food in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(food.key)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(food.value) 次")
                                        .foregroundColor(.secondary)
                                }
                                
                                if index < min(4, sortedFood.count - 1) {
                                    Divider()
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // 食物選擇分布圖
                StatsCard(title: "食物選擇分布") {
                    if dataStore.foodSelections.isEmpty {
                        Text("尚無食物選擇記錄")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    } else {
                        let sortedFood = dataStore.foodSelections.sorted(by: { $0.value > $1.value }).prefix(5)
                        let total = sortedFood.reduce(0) { $0 + $1.value }
                        
                        if #available(iOS 16.0, *) {
                            Chart {
                                ForEach(Array(sortedFood.enumerated()), id: \.element.key) { index, food in
                                    SectorMark(
                                        angle: .value("使用次數", food.value),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(
                                        Color(hue: Double(index) / Double(sortedFood.count), saturation: 0.8, brightness: 0.8)
                                    )
                                    .annotation(position: .overlay) {
                                        Text("\(Int(Double(food.value) / Double(total) * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .frame(height: 200)
                            
                            // 圖例
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(sortedFood.enumerated()), id: \.element.key) { index, food in
                                    ChartLegend(
                                        color: Color(hue: Double(index) / Double(sortedFood.count), saturation: 0.8, brightness: 0.8),
                                        text: "\(food.key) (\(food.value)次)"
                                    )
                                }
                            }
                            .padding(.top)
                        } else {
                            // iOS 16以下的替代UI
                            VStack(alignment: .leading, spacing: 10) {
                                Text("食物選擇比例")
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                
                                ForEach(Array(sortedFood.enumerated()), id: \.element.key) { index, food in
                                    HStack {
                                        Rectangle()
                                            .fill(Color(hue: Double(index) / Double(sortedFood.count), saturation: 0.8, brightness: 0.8))
                                            .frame(width: 12, height: 12)
                                            .cornerRadius(3)
                                        
                                        Text("\(food.key): \(food.value)次 (\(Int(Double(food.value) / Double(total) * 100))%)")
                                            .font(.subheadline)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .frame(height: 200)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 輔助組件
struct StatsCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StatItemView: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChartLegend: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(3)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 
