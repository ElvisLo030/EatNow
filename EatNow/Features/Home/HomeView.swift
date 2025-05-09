import SwiftUI
import UIKit

struct HomeView: View {
    @State private var recommendedItem: (name: String, price: Int) = ("按下按鈕解決選擇障礙！", 0)
    @State private var recommendedShop: String = "別再問要吃什麼了 戳下去吧！"
    @State private var recommendedItemShopName: String = ""
    @State private var selectedMode: Int = 0 // 0: 個人, 1: 團體
    @State private var showEatingAlert = false // 顯示吃的提示框
    @State private var tempPersonalClickCount: Int = 0 // 臨時記錄個人模式點擊次數
    @State private var tempGroupClickCount: Int = 0 // 臨時記錄團體模式點擊次數
    @State private var currentClickCount: Int = 0 // 用於顯示在警告中的點擊次數
    @State private var selectedFoodName: String = "" // 用戶選擇的食物名稱
    @State private var selectedShopName: String = "" // 用戶選擇的店家名稱
    @State private var showingHelp = false // 控制是否顯示使用說明
    
    // 震動回饋生成器
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    @EnvironmentObject private var dataStore: DataStore

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                Color.clear.onTapGesture { UIApplication.shared.endEditing() }
                VStack {
                    // 標題區塊 - 頂部
                    VStack(alignment: .center, spacing: 8) {
                        Text("嗨 \(dataStore.userName.isEmpty ? "新朋友" : dataStore.userName)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text(selectedMode == 0 ? "今天要吃什麼？" : "要去哪裡吃？")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                            .shadow(color: .gray.opacity(0.3), radius: 2, x: 1, y: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                    
                    // 功能區塊 - 畫面中央
                    VStack(spacing: 30) {
                        // 切換個人/團體模式
                        Picker("", selection: $selectedMode) {
                            Text("食物").tag(0)
                            Text("店家").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // 隨機選擇顯示
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                .frame(height: 150)
                            
                            VStack(spacing: 8) {
                                if selectedMode == 0 {
                                    if dataStore.shops.isEmpty {
                                        VStack(spacing: 10) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.largeTitle)
                                                .foregroundColor(.orange)
                                            
                                            Text("目前沒有店家資料")
                                                .font(.headline)
                                                .multilineTextAlignment(.center)
                                            
                                            Text("請先新增店家和菜單")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                    } else if recommendedItem.name == "按下按鈕解決選擇障礙！" {
                                        Text(recommendedItem.name)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.center)
                                    } else {
                                        Text(recommendedItemShopName)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                            .padding(.bottom, 4)
                                        
                                        Text("\(recommendedItem.name) - \(recommendedItem.price) 元")
                                            .font(.title3)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                    }
                                } else {
                                    if dataStore.shops.isEmpty {
                                        VStack(spacing: 10) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.largeTitle)
                                                .foregroundColor(.orange)
                                            
                                            Text("目前沒有店家資料")
                                                .font(.headline)
                                                .multilineTextAlignment(.center)
                                            
                                            Text("請先新增店家")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                    } else {
                                        Text(recommendedShop)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                        
                        // 按鈕容器 - 確保所有按鈕寬度一致
                        VStack(spacing: 30) {
                            // 隨機按鈕 - 使用ButtonStyle實現更自然的按下效果
                            Button {
                                // 觸發震動反饋
                                impactFeedbackGenerator.prepare()
                                impactFeedbackGenerator.impactOccurred()
                                
                                // 處理業務邏輯
                                if selectedMode == 0 {
                                    // 從隨機店家取得隨機菜單項目
                                    let result = dataStore.getRandomMenuItem()
                                    recommendedItem = (name: result.name, price: result.price)
                                    recommendedItemShopName = result.shopName
                                    
                                    // 記錄點擊個人隨機按鈕次數
                                    dataStore.personalRandomCount += 1
                                    tempPersonalClickCount += 1 // 臨時計數器也+1
                                } else {
                                    let shopNames = dataStore.shops.map { $0.name }
                                    recommendedShop = shopNames.isEmpty ? "尚無店家" : (shopNames.randomElement() ?? "尚無店家")
                                    
                                    // 記錄點擊團體隨機按鈕次數
                                    dataStore.groupRandomCount += 1
                                    tempGroupClickCount += 1 // 臨時計數器也+1
                                }
                            } label: {
                                HStack {
                                    Image(systemName: selectedMode == 0 ? "dot.circle.and.hand.point.up.left.fill" : "dot.circle.and.hand.point.up.left.fill")
                                        .font(.title2)
                                    Text(selectedMode == 0 ? "戳下去 推薦食物給你！" : "戳下去！")
                                        .font(.title)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, minHeight: 150)
                                .background(dataStore.shops.isEmpty ? Color.gray : Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                            }
                            .buttonStyle(PressableButtonStyle()) // 使用自定義按鈕樣式
                            .disabled(dataStore.shops.isEmpty)
                            .padding(.horizontal)
                            .overlay(
                                Group {
                                    if dataStore.shops.isEmpty {
                                        NavigationLink(destination: ShopListView().environmentObject(dataStore)) {
                                            Text("請新增資料")
                                                .font(.caption)
                                                .padding(6)
                                                .background(Color.white)
                                                .foregroundColor(.orange)
                                                .cornerRadius(4)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color.orange, lineWidth: 1)
                                                )
                                        }
                                        .offset(y: -35)
                                    }
                                }
                            )
                            
                            // 吃！按鈕
                            Button {
                                // 觸發震動反饋 - 使用不同的震動模式
                                let successFeedbackGenerator = UINotificationFeedbackGenerator()
                                successFeedbackGenerator.prepare()
                                successFeedbackGenerator.notificationOccurred(.success)
                                
                                // 先判斷是否有已推薦的項目
                                if (selectedMode == 0 && recommendedItem.name != "按下按鈕解決選擇障礙！") ||
                                   (selectedMode == 1 && recommendedShop != "別再問要吃什麼了 戳下去吧！" && recommendedShop != "尚無店家") {
                                    
                                    // 保存當前點擊次數用於顯示
                                    currentClickCount = selectedMode == 0 ? tempPersonalClickCount : tempGroupClickCount
                                    
                                    // 記錄解決選擇障礙次數
                                    dataStore.totalDecisionsMade += 1
                                    
                                    if selectedMode == 0 {
                                        // 記錄個人決定次數
                                        dataStore.personalDecisionsMade += 1
                                        
                                        // 記錄選擇的食物
                                        let foodName = recommendedItem.name
                                        dataStore.foodSelections[foodName, default: 0] += 1
                                        
                                        // 保存選擇的食物名稱
                                        selectedFoodName = foodName
                                        
                                        // 重置臨時點擊計數器
                                        tempPersonalClickCount = 0
                                        
                                        // 重置顯示資料
                                        recommendedItem = ("按下按鈕解決選擇障礙！", 0)
                                        recommendedItemShopName = ""
                                    } else {
                                        // 記錄團體決定次數
                                        dataStore.groupDecisionsMade += 1
                                        
                                        // 記錄選擇的店家
                                        dataStore.shopSelections[recommendedShop, default: 0] += 1
                                        
                                        // 保存選擇的店家名稱
                                        selectedShopName = recommendedShop
                                        
                                        // 重置臨時點擊計數器
                                        tempGroupClickCount = 0
                                        
                                        // 重置顯示資料
                                        recommendedShop = "按下按鈕決定！"
                                    }
                                    
                                    // 顯示提示框
                                    showEatingAlert = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "fork.knife")
                                        .font(.title2)
                                    Text("吃！")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(
                                    dataStore.shops.isEmpty 
                                    ? Color.gray 
                                    : Color.green
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                            }
                            .buttonStyle(PressableButtonStyle()) // 使用自定義按鈕樣式
                            .padding(.horizontal)
                            .disabled(
                                dataStore.shops.isEmpty || 
                                (selectedMode == 0 && recommendedItem.name == "按下按鈕解決選擇障礙！") ||
                                (selectedMode == 1 && (recommendedShop == "按下按鈕決定！" || recommendedShop == "尚無店家"))
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Text("Eat Now !")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                showingHelp = true
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .font(.title3)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                    }
                }
            }
            .alert(isPresented: $showEatingAlert) {
                Alert(
                    title: Text(selectedMode == 0 ? "去吃\(selectedFoodName)吧！" : "和大家去\(selectedShopName)吧！"),
                    message: Text("你戳了\(currentClickCount)次按鈕，\(selectedMode == 0 ? "解決了選擇障礙！" : "幫大家決定吃什麼！")"),
                    dismissButton: .default(Text("好欸！"))
                )
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .onAppear {
                // 預熱震動生成器以減少延遲
                impactFeedbackGenerator.prepare()
            }
        }
    }
}

// 自定義按鈕樣式，提供實時的按下效果
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .offset(y: configuration.isPressed ? 4 : 0)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// 跳轉到店家列表頁面的連接視圖
struct CustomFoodsLinkView: View {
    @EnvironmentObject private var dataStore: DataStore
    
    var body: some View {
        ShopListView()
            .environmentObject(dataStore)
    }
}

struct MenuView: View {
    @EnvironmentObject private var dataStore: DataStore
    let shop: String
    
    // 計算屬性獲取當前店家的菜單項目
    private var menuItems: [MenuItem] {
        if let shop = dataStore.shops.first(where: { $0.name == shop }) {
            return shop.menuItems
        }
        return []
    }

    var body: some View {
        if menuItems.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "fork.knife")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("此店家沒有菜單項目")
                    .font(.headline)
                
                Button("新增菜單項目") {
                    if let index = dataStore.shops.firstIndex(where: { $0.name == shop }) {
                        dataStore.addMenuItem(to: index)
                    }
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitle(shop, displayMode: .inline)
        } else {
            List {
                ForEach(menuItems) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("\(item.price) 元")
                    }
                }
            }
            .navigationBarTitle(shop, displayMode: .inline)
        }
    }
}

// 使用說明視圖
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 首頁使用說明
                    HelpSection(
                        title: "🍔 解決選擇障礙 (首頁)",
                        content: [
                            HelpContent(
                                subtitle: "食物模式",
                                items: [
                                    "在首頁選擇「食物」模式",
                                    "點擊「戳下去 推薦食物給你！」按鈕",
                                    "查看隨機推薦的食物和價格",
                                    "滿意選擇後點擊「吃！」按鈕記錄決策"
                                ]
                            ),
                            HelpContent(
                                subtitle: "店家模式",
                                items: [
                                    "在首頁切換至「店家」模式",
                                    "點擊「戳下去！」隨機選擇一家店",
                                    "確認推薦店家後點「吃！」完成決策",
                                    "系統會記錄您的選擇用於統計分析"
                                ]
                            )
                        ]
                    )
                    
                    Divider()
                    
                    // 店家管理說明
                    HelpSection(
                        title: "🏪 店家與菜單管理",
                        content: [
                            HelpContent(
                                subtitle: "管理店家",
                                items: [
                                    "切換到「店家」標籤頁瀏覽所有店家",
                                    "點擊右上角「+」按鈕手動添加店家",
                                    "點擊「匯入」按鈕批量導入店家資料",
                                    "向左滑動店家項目可刪除或編輯"
                                ]
                            ),
                            HelpContent(
                                subtitle: "管理菜單",
                                items: [
                                    "點擊任一店家進入該店菜單管理頁面",
                                    "點擊「+」添加新菜品及價格",
                                    "向左滑動菜單項目可刪除或修改",
                                    "菜單內容會自動保存並用於隨機推薦"
                                ]
                            )
                        ]
                    )
                    
                    Divider()
                    
                    // 統計分析說明
                    HelpSection(
                        title: "📊 查看使用統計",
                        items: [
                            "切換到「統計」標籤頁查看數據分析",
                            "「總覽」部分顯示使用頻率和決策數據",
                            "「排行榜」查看您最常選擇的店家和食物",
                            "統計數據會隨著使用自動更新"
                        ]
                    )
                    
                    Divider()
                    
                    // 設定說明
                    HelpSection(
                        title: "⚙️ 設定與資料管理",
                        items: [
                            "在「設定」頁可修改個人化偏好",
                            "點擊「匯出店家資料」分享給朋友",
                            "支援CSV格式匯入/匯出店家與菜單",
                            "使用「重設資料」可清除現有資料並重新開始"
                        ]
                    )
                    
                    // 小技巧提示
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("小技巧：首次使用時，建議從設定頁匯入範例資料，快速體驗所有功能！")
                            .font(.footnote)
                            .italic()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("使用說明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 幫助部分組件
struct HelpSection: View {
    var title: String
    var content: [HelpContent]? = nil
    var items: [String]? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            if let content = content {
                ForEach(content) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.subtitle)
                            .font(.headline)
                        
                        ForEach(section.items.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .fontWeight(.medium)
                                Text(section.items[index])
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
            }
            
            if let items = items {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .top) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .padding(.top, 6)
                        Text(items[index])
                    }
                }
                .padding(.leading, 4)
            }
        }
    }
}

// 幫助內容模型
struct HelpContent: Identifiable {
    let id = UUID()
    let subtitle: String
    let items: [String]
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(DataStore.shared)
    }
}
