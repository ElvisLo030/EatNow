import SwiftUI
import UIKit

// MARK: - 狀態管理模型

/// 推薦結果狀態
struct RecommendationState {
    var foodItem: (name: String, price: Int) = ("按下按鈕解決選擇障礙！", 0)
    var shopName: String = "別再問要吃什麼了 戳下去吧！"
    var foodShopName: String = ""
    
    // 常數定義，避免字串不一致
    struct InitialMessages {
        static let food = "按下按鈕解決選擇障礙！"
        static let shop = "別再問要吃什麼了 戳下去吧！"
    }
    
    mutating func resetToInitial() {
        foodItem = (InitialMessages.food, 0)
        shopName = InitialMessages.shop
        foodShopName = ""
    }
    
    func hasValidFoodRecommendation() -> Bool {
        return foodItem.name != InitialMessages.food
    }
    
    func hasValidShopRecommendation() -> Bool {
        return shopName != InitialMessages.shop && shopName != "尚無店家"
    }
}

/// 點擊計數狀態
struct ClickCountState {
    var personalClickCount: Int = 0
    var groupClickCount: Int = 0
    var currentClickCount: Int = 0
    
    mutating func incrementPersonal() {
        personalClickCount += 1
    }
    
    mutating func incrementGroup() {
        groupClickCount += 1
    }
    
    mutating func resetPersonal() {
        personalClickCount = 0
    }
    
    mutating func resetGroup() {
        groupClickCount = 0
    }
    
    mutating func updateCurrentCount(for mode: Int) {
        currentClickCount = mode == 0 ? personalClickCount : groupClickCount
    }
}

/// 選擇記錄狀態
struct SelectionState {
    var selectedFoodName: String = ""
    var selectedShopName: String = ""
    
    mutating func setSelectedFood(_ name: String) {
        selectedFoodName = name
    }
    
    mutating func setSelectedShop(_ name: String) {
        selectedShopName = name
    }
    
    mutating func reset() {
        selectedFoodName = ""
        selectedShopName = ""
    }
}

/// UI 狀態
struct UIState {
    var selectedMode: Int = 0 // 0: 食物, 1: 店家
    var showEatingAlert: Bool = false
    var showingHelp: Bool = false
    
    var isPersonalMode: Bool {
        return selectedMode == 0
    }
    
    var isGroupMode: Bool {
        return selectedMode == 1
    }
}

// MARK: - HomeViewModel

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - 狀態屬性
    @Published var recommendationState = RecommendationState()
    @Published var clickCountState = ClickCountState()
    @Published var selectionState = SelectionState()
    @Published var uiState = UIState()
    
    // MARK: - 依賴注入
    private let dataStore: DataStore
    private var effectsController: EffectsController
    
    // 震動回饋生成器
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    init(dataStore: DataStore, effectsController: EffectsController) {
        self.dataStore = dataStore
        self.effectsController = effectsController
        
        // 預熱震動生成器
        impactFeedbackGenerator.prepare()
    }
    
    /// 同步 effectsController 引用（用於 View 依賴注入）
    func syncEffectsController(_ controller: EffectsController) {
        self.effectsController = controller
    }
    
    // MARK: - 業務邏輯方法
    
    /// 處理隨機推薦邏輯
    func handleRandomRecommendation() {
        // 觸發震動反饋
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
        
        if uiState.isPersonalMode {
            handleFoodModeRecommendation()
        } else {
            handleShopModeRecommendation()
        }
    }
    
    /// 處理食物模式推薦
    private func handleFoodModeRecommendation() {
        // 從資料庫獲取隨機菜單項目
        let result = dataStore.getRandomMenuItem()
        recommendationState.foodItem = (name: result.name, price: result.price)
        recommendationState.foodShopName = result.shopName
        
        // 更新統計數據
        dataStore.personalRandomCount += 1
        clickCountState.incrementPersonal()
        
        // 根據設定啟用特效
        if dataStore.effectsEnabled {
            effectsController.handleButtonClick(count: clickCountState.personalClickCount, mode: uiState.selectedMode)
        }
    }
    
    /// 處理店家模式推薦
    private func handleShopModeRecommendation() {
        // 獲取所有店家並隨機選擇一家
        let shopNames = dataStore.shops.map { $0.name }
        recommendationState.shopName = shopNames.isEmpty ? "尚無店家" : (shopNames.randomElement() ?? "尚無店家")
        
        // 更新統計數據
        dataStore.groupRandomCount += 1
        clickCountState.incrementGroup()
        
        // 根據設定啟用特效
        if dataStore.effectsEnabled {
            effectsController.handleButtonClick(count: clickCountState.groupClickCount, mode: uiState.selectedMode)
        }
    }
    
    /// 處理確認選擇邏輯
    func handleConfirmSelection() {
        // 成功震動反饋
        let successFeedbackGenerator = UINotificationFeedbackGenerator()
        successFeedbackGenerator.prepare()
        successFeedbackGenerator.notificationOccurred(.success)
        
        // 檢查是否有有效推薦結果
        guard hasValidRecommendation() else { return }
        
        // 更新當前點擊次數
        clickCountState.updateCurrentCount(for: uiState.selectedMode)
        
        // 更新全域統計
        dataStore.totalDecisionsMade += 1
        
        if uiState.isPersonalMode {
            handleFoodModeConfirmation()
        } else {
            handleShopModeConfirmation()
        }
        
        // 觸發特效
        if dataStore.effectsEnabled {
            effectsController.triggerFireworks()
        }
        
        // 顯示確認提示框
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            uiState.showEatingAlert = true
        }
    }
    
    /// 處理食物模式確認
    private func handleFoodModeConfirmation() {
        dataStore.personalDecisionsMade += 1
        
        let foodName = recommendationState.foodItem.name
        dataStore.foodSelections[foodName, default: 0] += 1
        selectionState.setSelectedFood(foodName)
        
        // 重置狀態
        clickCountState.resetPersonal()
        effectsController.resetEffects()
        recommendationState.foodItem = (RecommendationState.InitialMessages.food, 0)
        recommendationState.foodShopName = ""
    }
    
    /// 處理店家模式確認
    private func handleShopModeConfirmation() {
        dataStore.groupDecisionsMade += 1
        
        dataStore.shopSelections[recommendationState.shopName, default: 0] += 1
        selectionState.setSelectedShop(recommendationState.shopName)
        
        // 重置狀態
        clickCountState.resetGroup()
        effectsController.resetEffects()
        recommendationState.shopName = RecommendationState.InitialMessages.shop
    }
    
    /// 檢查是否有有效推薦結果
    private func hasValidRecommendation() -> Bool {
        if uiState.isPersonalMode {
            return recommendationState.hasValidFoodRecommendation()
        } else {
            return recommendationState.hasValidShopRecommendation()
        }
    }
    
    /// 檢查是否可以確認選擇
    func canConfirmSelection() -> Bool {
        if dataStore.shops.isEmpty {
            return false
        }
        
        return hasValidRecommendation()
    }
    
    /// 獲取按鈕顏色
    func getButtonColor() -> Color {
        if dataStore.shops.isEmpty {
            return Color.gray
        }
        
        let count = uiState.isPersonalMode ? clickCountState.personalClickCount : clickCountState.groupClickCount
        return effectsController.getButtonColor(count: count)
    }
    
    /// 獲取推薦按鈕文字
    func getRecommendationButtonText() -> String {
        return uiState.isPersonalMode ? "戳下去 推薦食物給你！" : "戳下去！"
    }
    
    /// 獲取標題文字
    func getTitleText() -> String {
        return uiState.isPersonalMode ? "今天要吃什麼？" : "要去哪裡吃？"
    }
    
    /// 獲取確認提示標題
    func getAlertTitle() -> String {
        if uiState.isPersonalMode {
            return "去吃\(selectionState.selectedFoodName)吧！"
        } else {
            return "和大家去\(selectionState.selectedShopName)吧！"
        }
    }
    
    /// 獲取確認提示訊息
    func getAlertMessage() -> String {
        let modeText = uiState.isPersonalMode ? "解決了選擇障礙！" : "幫大家決定吃什麼！"
        return "你戳了\(clickCountState.currentClickCount)次按鈕，\(modeText)"
    }
}
