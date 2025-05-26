import SwiftUI
import UIKit

// MARK: - 主頁視圖
struct HomeView: View {
    // MARK: - 環境與狀態對象
    @EnvironmentObject private var dataStore: DataStore // 資料存儲對象
    @StateObject private var effectsController = EffectsController() // 特效控制器
    @StateObject private var viewModel: HomeViewModel
    
    // 初始化 ViewModel
    init() {
        // 注意：這裡使用臨時值初始化，真正的依賴注入會在 onAppear 中處理
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            dataStore: DataStore.shared,
            effectsController: EffectsController()
        ))
    }

    // MARK: - 視圖主體
    var body: some View {
        ZStack {
            // 主界面層
            NavigationView {
                ZStack {
                    // 背景設置
                    Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all) // 設置全螢幕背景色
                    Color.clear.onTapGesture { UIApplication.shared.endEditing() } // 點擊空白處關閉鍵盤
                    
                    VStack {
                        // MARK: - 標題區塊
                        VStack(alignment: .center, spacing: 8) {
                            // 用戶名稱顯示
                            Text("嗨 \(dataStore.userName.isEmpty ? "新朋友" : dataStore.userName)")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            // 根據當前模式顯示不同標題
                            Text(viewModel.getTitleText())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                                .shadow(color: .gray.opacity(0.3), radius: 2, x: 1, y: 1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.top, 30)
                        .padding(.bottom, 20)
                        
                        // MARK: - 功能區塊
                        VStack(spacing: 30) {
                            // 模式切換選擇器
                            Picker("", selection: $viewModel.uiState.selectedMode) {
                                Text("食物").tag(0) // 食物模式
                                Text("店家").tag(1) // 店家模式
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            // MARK: - 推薦結果顯示區域
                            ZStack {
                                // 背景卡片樣式
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                    .frame(height: 150)
                                
                                // 推薦內容顯示
                                VStack(spacing: 8) {
                                    if viewModel.uiState.selectedMode == 0 { // 食物模式
                                        if dataStore.shops.isEmpty { // 無資料情況
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
                                        } else if viewModel.recommendationState.foodItem.name == RecommendationState.InitialMessages.food { // 初始狀態
                                            Text(viewModel.recommendationState.foodItem.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.center)
                                        } else { // 已推薦食物
                                            // 顯示店家名稱
                                            Text(viewModel.recommendationState.foodShopName)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.center)
                                                .padding(.bottom, 4)
                                            
                                            // 顯示食物名稱與價格
                                            Text("\(viewModel.recommendationState.foodItem.name) - \(viewModel.recommendationState.foodItem.price) 元")
                                                .font(.title3)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.center)
                                        }
                                    } else { // 店家模式
                                        if dataStore.shops.isEmpty { // 無資料情況
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
                                        } else { // 顯示推薦店家
                                            Text(viewModel.recommendationState.shopName)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.horizontal)
                            
                            // 操作按鈕區域
                            VStack(spacing: 30) {
                                // MARK: - 隨機推薦按鈕
                                Button {
                                    viewModel.handleRandomRecommendation()
                                } label: {
                                    // 按鈕外觀設計
                                    HStack {
                                        Image(systemName: "dot.circle.and.hand.point.up.left.fill")
                                            .font(.title2)
                                        Text(viewModel.getRecommendationButtonText())
                                            .font(.title)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 150)
                                    .background(viewModel.getButtonColor())
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                                }
                                .buttonStyle(PressableButtonStyle()) // 自定義按壓效果
                                .disabled(dataStore.shops.isEmpty) // 無資料時禁用
                                .padding(.horizontal)
                                .overlay( // 無資料時顯示導航提示
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
                                
                                // MARK: - 確認選擇按鈕
                                Button {
                                    viewModel.handleConfirmSelection()
                                } label: {
                                    // 吃按鈕外觀設計
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
                                        ? Color.gray // 無資料時灰色
                                        : Color.green // 確認按鈕使用綠色
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                                }
                                .buttonStyle(PressableButtonStyle()) // 自定義按壓效果
                                .padding(.horizontal)
                                .disabled(!viewModel.canConfirmSelection())
                            }
                            
                            Spacer() // 佔用剩餘空間
                        }
                        .padding(.bottom, 30)
                    }
                    // MARK: - 導航欄設置
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HStack {
                                // 應用標題
                                Text("Eat Now !")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                // 幫助按鈕
                                Button(action: {
                                    viewModel.uiState.showingHelp = true // 顯示說明頁面
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
                // MARK: - 彈出提示與頁面
                .alert(isPresented: $viewModel.uiState.showEatingAlert) { // 確認選擇的提示框
                    Alert(
                        title: Text(viewModel.getAlertTitle()),
                        message: Text(viewModel.getAlertMessage()),
                        dismissButton: .default(Text("好欸！"))
                    )
                }
                .sheet(isPresented: $viewModel.uiState.showingHelp) { // 說明頁面
                    HelpView()
                }
                .onAppear {
                    // 視圖出現時同步 effectsController 的引用
                    viewModel.syncEffectsController(effectsController)
                }
            }
            
            // MARK: - 特效層
            // 特效疊加層 - 保持在最上層，顯示各種視覺特效
            if dataStore.effectsEnabled {
                // 特效背景層 - 總是保持存在但隱藏，以便提前加載資源
                ZStack {
                    // 警告消息視圖 - 當多次點擊時顯示
                    if effectsController.showWarningMessage {
                        WarningMessageView(message: effectsController.warningMessage)
                            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                    
                    // 煙花特效 - 確認選擇時顯示
                    if effectsController.showFireworks {
                        FireworksView()
                            .transition(.opacity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .environmentObject(effectsController)
                    } else {
                        // 隱藏的煙花視圖，用於提前加載資源
                        FireworksView()
                            .opacity(0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .disabled(true)
                            .environmentObject(effectsController)
                    }
                    
                    // 爆炸特效 - 極端情況下顯示
                    if effectsController.showExplosion {
                        ExplosionView()
                            .transition(.opacity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .environmentObject(effectsController)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false) // 允許透過特效層點擊下面的元素
                .animation(.easeInOut(duration: 0.3), value: effectsController.showWarningMessage) // 添加狀態變化動畫
                .animation(.easeIn(duration: 0.2), value: effectsController.showFireworks)
                .animation(.easeIn(duration: 0.1), value: effectsController.showExplosion)
            }
        }
    }
}

// MARK: - 輔助組件

// 自定義按鈕樣式，提供實時的按下效果
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1) // 按下時縮小
            .offset(y: configuration.isPressed ? 4 : 0) // 按下時下移
            .opacity(configuration.isPressed ? 0.9 : 1) // 按下時透明度變化
            .blur(radius: configuration.isPressed ? 0.5 : 0) // 輕微模糊增強按下效果
            .animation(.spring(duration: 0.2, bounce: 0.5, blendDuration: 0.1), value: configuration.isPressed) // 現代彈簧動畫
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.1 : 0.2), 
                   radius: configuration.isPressed ? 2 : 5, 
                   x: 0, 
                   y: configuration.isPressed ? 1 : 3) // 動態陰影變化
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

// MARK: - 菜單視圖
struct MenuView: View {
    @EnvironmentObject private var dataStore: DataStore
    let shop: String // 當前店家名稱
    
    // 計算屬性獲取當前店家的菜單項目
    private var menuItems: [MenuItem] {
        if let shop = dataStore.shops.first(where: { $0.name == shop }) {
            return shop.menuItems
        }
        return []
    }

    var body: some View {
        if menuItems.isEmpty { // 無菜單項目時的顯示
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
        } else { // 顯示菜單列表
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

// MARK: - 使用說明視圖
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss // 關閉視圖控制器
    
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

// MARK: - 使用說明組件
// 幫助部分組件 - 用於顯示分類說明內容
struct HelpSection: View {
    var title: String // 說明標題
    var content: [HelpContent]? = nil // 包含子標題的內容
    var items: [String]? = nil // 直接列表項目
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 說明區段標題
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            // 處理帶子標題的內容
            if let content = content {
                ForEach(content) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.subtitle)
                            .font(.headline)
                        
                        // 顯示子內容項目
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
            
            // 處理直接列表項目
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

// MARK: - 數據模型
// 幫助內容模型 - 用於結構化說明內容
struct HelpContent: Identifiable {
    let id = UUID() // 唯一識別符
    let subtitle: String // 子標題
    let items: [String] // 說明項目列表
}

// MARK: - 預覽
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(DataStore.shared)
    }
}
