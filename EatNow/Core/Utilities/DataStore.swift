import SwiftUI
import Foundation

// 數據儲存管理器
class DataStore: ObservableObject {
    static let shared = DataStore()
    
    // 統計相關數據
    @Published var personalRandomCount: Int = 0 {
        didSet { saveStatsData() }
    }
    @Published var groupRandomCount: Int = 0 {
        didSet { saveStatsData() }
    }
    @Published var personalDecisionsMade: Int = 0 {
        didSet { saveStatsData() }
    }
    @Published var groupDecisionsMade: Int = 0 {
        didSet { saveStatsData() }
    }
    @Published var totalDecisionsMade: Int = 0 {
        didSet { saveStatsData() }
    }
    @Published var foodSelections: [String: Int] = [:] {
        didSet { saveStatsData() }
    }
    @Published var shopSelections: [String: Int] = [:] {
        didSet { saveStatsData() }
    }
    
    private let statsDataSaveKey = "eatnow.statsData"
    private var statsDataURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(statsDataSaveKey).json")
    }
    
    private struct StatsData: Codable {
        var personalRandomCount: Int = 0
        var groupRandomCount: Int = 0
        var personalDecisionsMade: Int = 0
        var groupDecisionsMade: Int = 0
        var totalDecisionsMade: Int = 0
        var foodSelections: [String: Int] = [:]
        var shopSelections: [String: Int] = [:]
    }
    
    private func loadStatsData() {
        guard FileManager.default.fileExists(atPath: statsDataURL.path) else { return }
        do {
            let data = try Data(contentsOf: statsDataURL)
            let decoder = JSONDecoder()
            let statsData = try decoder.decode(StatsData.self, from: data)
            
            self.personalRandomCount = statsData.personalRandomCount
            self.groupRandomCount = statsData.groupRandomCount
            self.personalDecisionsMade = statsData.personalDecisionsMade
            self.groupDecisionsMade = statsData.groupDecisionsMade
            self.totalDecisionsMade = statsData.totalDecisionsMade
            self.foodSelections = statsData.foodSelections
            self.shopSelections = statsData.shopSelections
        } catch {
            print("無法加載統計數據: \(error.localizedDescription)")
        }
    }
    
    private func saveStatsData() {
        do {
            let statsData = StatsData(
                personalRandomCount: personalRandomCount,
                groupRandomCount: groupRandomCount,
                personalDecisionsMade: personalDecisionsMade,
                groupDecisionsMade: groupDecisionsMade,
                totalDecisionsMade: totalDecisionsMade,
                foodSelections: foodSelections,
                shopSelections: shopSelections
            )
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(statsData)
            try data.write(to: statsDataURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("無法保存統計數據: \(error.localizedDescription)")
        }
    }
    
    // 重置統計資料
    func resetStats() {
        personalRandomCount = 0
        groupRandomCount = 0
        personalDecisionsMade = 0
        groupDecisionsMade = 0
        totalDecisionsMade = 0
        foodSelections = [:]
        shopSelections = [:]
    }
    
    @Published var shops: [Shop] {
        didSet {
            saveData()
        }
    }

    // 自定義食物清單
    @Published var customFoods: [CustomFood] = [] {
        didSet { saveCustomFoods() }
    }
    private let customFoodsSaveKey = "eatnow.customFoods"
    private var customFoodsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(customFoodsSaveKey).json")
    }
    private func loadCustomFoods() {
        guard FileManager.default.fileExists(atPath: customFoodsURL.path) else { 
            customFoods = CustomFood.defaultItems()
            return 
        }
        if let data = try? Data(contentsOf: customFoodsURL),
           let decoded = try? JSONDecoder().decode([CustomFood].self, from: data) {
            customFoods = decoded
        } else {
            customFoods = CustomFood.defaultItems()
        }
    }
    private func saveCustomFoods() {
        if let data = try? JSONEncoder().encode(customFoods) {
            try? data.write(to: customFoodsURL, options: [.atomicWrite, .completeFileProtection])
        }
    }

    // 歷史統計儲存
    @Published var statsHistory: [StatsSession] = [] {
        didSet { saveStatsHistory() }
    }
    private let statsHistorySaveKey = "eatnow.statsHistory"
    private var statsHistoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(statsHistorySaveKey).json")
    }
    private func loadStatsHistory() {
        guard FileManager.default.fileExists(atPath: statsHistoryURL.path) else { return }
        if let data = try? Data(contentsOf: statsHistoryURL),
           let decoded = try? JSONDecoder().decode([StatsSession].self, from: data) {
            statsHistory = decoded
        }
    }
    private func saveStatsHistory() {
        if let data = try? JSONEncoder().encode(statsHistory) {
            try? data.write(to: statsHistoryURL, options: [.atomicWrite, .completeFileProtection])
        }
    }

    // 常用姓名儲存
    @Published var commonNames: [String] = [] {
        didSet { saveCommonNames() }
    }
    private let commonNamesSaveKey = "eatnow.commonNames"
    private var commonNamesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(commonNamesSaveKey).json")
    }
    private func loadCommonNames() {
        guard FileManager.default.fileExists(atPath: commonNamesURL.path) else { return }
        if let data = try? Data(contentsOf: commonNamesURL),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            commonNames = decoded
        }
    }
    private func saveCommonNames() {
        if let data = try? JSONEncoder().encode(commonNames) {
            try? data.write(to: commonNamesURL, options: [.atomicWrite, .completeFileProtection])
        }
    }

    // 使用者檔案儲存
    @Published var userName: String = "" {
        didSet { saveUserProfile() }
    }
    @Published var userAvatarName: String = "" {
        didSet { saveUserProfile() }
    }
    private let userProfileSaveKey = "eatnow.userProfile"
    private var userProfileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(userProfileSaveKey).json")
    }
    private struct UserProfile: Codable {
        var name: String
        var avatarName: String
    }
    private func loadUserProfile() {
        guard FileManager.default.fileExists(atPath: userProfileURL.path) else { return }
        if let data = try? Data(contentsOf: userProfileURL),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userName = decoded.name
            userAvatarName = decoded.avatarName
        }
    }
    private func saveUserProfile() {
        let profile = UserProfile(name: userName, avatarName: userAvatarName)
        if let data = try? JSONEncoder().encode(profile) {
            try? data.write(to: userProfileURL, options: [.atomicWrite, .completeFileProtection])
        }
    }

    private let saveKey = "eatnow.shops"
    
    private var saveURL: URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent("\(saveKey).json")
    }
    
    private init() {
        shops = []
        loadData()
        loadStatsHistory()
        loadCommonNames()
        loadUserProfile()
        loadCustomFoods() // 加載自定義食物數據
        loadStatsData() // 加載統計數據
        // 如果沒有數據，初始化示範數據
        if shops.isEmpty {
            initializeDefaultData()
        }
    }
    
    // 從私有方法改為公開方法，以便從設定頁面導入示範資料
    func initializeDefaultData() {
        shops = [
            Shop(
                name: "好好小吃店",
                menuItems: [
                    MenuItem(name: "炒麵", price: 80),
                    MenuItem(name: "水餃", price: 60),
                    MenuItem(name: "鍋貼", price: 70),
                    MenuItem(name: "滷肉飯", price: 50)
                ]
            ),
            Shop(
                name: "美味餐廳",
                menuItems: [
                    MenuItem(name: "漢堡", price: 120),
                    MenuItem(name: "炸雞排", price: 150),
                    MenuItem(name: "薯條", price: 60),
                    MenuItem(name: "沙拉", price: 90)
                ]
            ),
            Shop(
                name: "樂園麵店",
                menuItems: [
                    MenuItem(name: "牛肉麵", price: 160),
                    MenuItem(name: "陽春麵", price: 70),
                    MenuItem(name: "餛飩湯", price: 80),
                    MenuItem(name: "滷蛋", price: 20)
                ]
            ),
            Shop(
                name: "快樂便當",
                menuItems: [
                    MenuItem(name: "雞腿便當", price: 110),
                    MenuItem(name: "排骨便當", price: 100),
                    MenuItem(name: "鱈魚便當", price: 120),
                    MenuItem(name: "素食便當", price: 90)
                ]
            )
        ]
        saveData()
    }
    
    // 保存數據到本地 JSON 文件
    private func saveData() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(shops)
            try data.write(to: saveURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("無法保存數據: \(error.localizedDescription)")
        }
    }
    
    // 從本地 JSON 文件加載數據
    private func loadData() {
        do {
            guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
            let data = try Data(contentsOf: saveURL)
            let decoder = JSONDecoder()
            shops = try decoder.decode([Shop].self, from: data)
        } catch {
            print("無法加載數據: \(error.localizedDescription)")
        }
    }
    
    // 新增自定義食物
    func addCustomFood(name: String) {
        withAnimation {
            let newFood = CustomFood(name: name)
            customFoods.append(newFood)
        }
    }
    
    // 刪除自定義食物
    func deleteCustomFood(at indexSet: IndexSet) {
        withAnimation {
            customFoods.remove(atOffsets: indexSet)
        }
    }
    
    // 獲取隨機食物
    func getRandomFood() -> String {
        if customFoods.isEmpty {
            return "尚無食物選項"
        }
        return customFoods.randomElement()?.name ?? "未知食品"
    }
    
    // 隨機食品名稱生成
    func getRandomFoodName() -> String {
        let foods = [
            "炒麵", "炸雞排", "沙拉", "漢堡", "水餃", "炸薯條","烤鴨", "握壽司", "鍋貼", "炒飯", "薯條", "三明治","炸豬", "蛋餅", "魚麵線", "咖哩飯", "湯麵", "拉麵"
        ]
        
        return foods.randomElement() ?? "未知食品"
    }
    
    // 為特定店家添加新的菜單項目
    func addMenuItem(to shopIndex: Int, name: String = "新菜單項目", price: Int = 100) {
        if shopIndex >= 0 && shopIndex < shops.count {
            withAnimation(.easeInOut) {
                let newItem = MenuItem(name: name, price: price)
                shops[shopIndex].menuItems.append(newItem)
            }
        }
    }
    
    // 根據索引刪除店家
    func deleteShop(at indexSet: IndexSet) {
        withAnimation(.easeInOut) {
            shops.remove(atOffsets: indexSet)
        }
    }
    
    // 新增店家
    func addShop() {
        withAnimation(.easeInOut) {
            let newShop = Shop(name: "新店家", menuItems: [])
            shops.append(newShop)
        }
    }
    
    // 刪除店家中的菜單項目
    func deleteMenuItem(shopIndex: Int, at indexSet: IndexSet) {
        if shopIndex >= 0 && shopIndex < shops.count {
            withAnimation(.easeInOut) {
                shops[shopIndex].menuItems.remove(atOffsets: indexSet)
            }
        }
    }

    // 清除所有資料
    func clearAllData() {
        shops = []
        customFoods = []
        statsHistory = []
        commonNames = []
        userName = ""
        userAvatarName = ""
        
        // 重置統計數據
        resetStats()
        
        // 刪除所有本地保存的檔案
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let files = try? fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        files?.forEach { file in
            if file.lastPathComponent.contains(saveKey) ||
               file.lastPathComponent.contains(customFoodsSaveKey) ||
               file.lastPathComponent.contains(statsHistorySaveKey) ||
               file.lastPathComponent.contains(commonNamesSaveKey) ||
               file.lastPathComponent.contains(userProfileSaveKey) ||
               file.lastPathComponent.contains(statsDataSaveKey) {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    // 從隨機店家獲取隨機菜單項目
    func getRandomMenuItem() -> (name: String, price: Int, shopName: String) {
        if shops.isEmpty {
            return (name: "尚無店家", price: 0, shopName: "")
        }
        
        let randomShop = shops.randomElement()!
        if randomShop.menuItems.isEmpty {
            return (name: "此店家尚無菜單項目", price: 0, shopName: randomShop.name)
        }
        
        let randomItem = randomShop.menuItems.randomElement()!
        return (name: randomItem.name, price: randomItem.price, shopName: randomShop.name)
    }
} 