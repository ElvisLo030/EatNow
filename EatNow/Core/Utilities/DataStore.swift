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
    
    // 成就記錄
    @Published var unlockedAchievements: Set<String> = [] {
        didSet { saveAchievementData() }
    }
    
    private let achievementDataSaveKey = "eatnow.achievementData"
    private var achievementDataURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(achievementDataSaveKey).json")
    }
    
    private func loadAchievementData() {
        guard FileManager.default.fileExists(atPath: achievementDataURL.path) else { return }
        do {
            let data = try Data(contentsOf: achievementDataURL)
            let decoder = JSONDecoder()
            let achievementData = try decoder.decode(Set<String>.self, from: data)
            self.unlockedAchievements = achievementData
        } catch {
            print("無法加載成就數據: \(error.localizedDescription)")
        }
    }
    
    private func saveAchievementData() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(unlockedAchievements)
            try data.write(to: achievementDataURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("無法保存成就數據: \(error.localizedDescription)")
        }
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
        // 不重置成就數據 unlockedAchievements
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
    
    // 控制是否啟用特效
    @Published var effectsEnabled: Bool = false {
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
        var effectsEnabled: Bool = false
    }
    
    private func loadUserProfile() {
        guard FileManager.default.fileExists(atPath: userProfileURL.path) else { return }
        if let data = try? Data(contentsOf: userProfileURL),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userName = decoded.name
            userAvatarName = decoded.avatarName
            effectsEnabled = decoded.effectsEnabled
        }
    }
    
    private func saveUserProfile() {
        let profile = UserProfile(name: userName, avatarName: userAvatarName, effectsEnabled: effectsEnabled)
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
        loadAchievementData() // 加載成就數據
        // 如果沒有數據，初始化示範數據
        if shops.isEmpty {
            initializeDefaultData()
        }
    }
    
    // 從私有方法改為公開方法，以便從設定頁面導入示範資料
    func initializeDefaultData() {
        // 嘗試從範例CSV檔案導入資料
        if let shops = loadShopsFromExampleCSV() {
            self.shops = shops
        } else {
            // 如果CSV導入失敗，使用預設資料作為後備
            createDefaultShops()
        }
        saveData()
    }
    
    // 從樣本CSV檔案中讀取店家資料
    private func loadShopsFromExampleCSV() -> [Shop]? {
        guard let csvURL = Bundle.main.url(forResource: "ExampleCSV", withExtension: "txt"),
              let csvContent = try? String(contentsOf: csvURL, encoding: .utf8) else {
            print("無法找到或讀取範例CSV檔案")
            return nil
        }
        
        var shops: [Shop] = []
        var currentShopName: String = ""
        var currentShopItems: [MenuItem] = []
        
        // 解析CSV檔案
        let lines = csvContent.components(separatedBy: .newlines)
        
        // 跳過標題行
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let columns = line.components(separatedBy: ",")
            guard columns.count >= 3 else { continue }
            
            let shopName = columns[0]
            let itemName = columns[1]
            
            // 確保價格是有效數字
            guard let price = Int(columns[2]) else { continue }
            
            // 如果是新店家，儲存之前的店家並開始新的
            if shopName != currentShopName {
                if !currentShopName.isEmpty && !currentShopItems.isEmpty {
                    shops.append(Shop(name: currentShopName, menuItems: currentShopItems))
                }
                currentShopName = shopName
                currentShopItems = []
            }
            
            // 添加菜單項目
            currentShopItems.append(MenuItem(name: itemName, price: price))
        }
        
        // 添加最後一個店家
        if !currentShopName.isEmpty && !currentShopItems.isEmpty {
            shops.append(Shop(name: currentShopName, menuItems: currentShopItems))
        }
        
        return shops.isEmpty ? nil : shops
    }
    
    // 創建默認店家數據（作為後備選項）
    private func createDefaultShops() {
        shops = [
            Shop(
                name: "測試資料，請刪除此資料後重新匯入",
                menuItems: [
                    MenuItem(name: "炒麵", price: 80),
                    MenuItem(name: "水餃", price: 60),
                    MenuItem(name: "鍋貼", price: 70),
                    MenuItem(name: "滷肉飯", price: 50),
                    MenuItem(name: "雞腿便當", price: 110),
                    MenuItem(name: "排骨便當", price: 100),
                    MenuItem(name: "鱈魚便當", price: 120),
                    MenuItem(name: "素食便當", price: 90)
                ]
            ),
        ]
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

    // 只清除店家資料的方法
    func clearShopsData() {
        shops = [] // 清空店家陣列
        
        // 刪除本地保存的店家檔案
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let shopFile = documentDirectory.appendingPathComponent("\(saveKey).json")
        
        if fileManager.fileExists(atPath: shopFile.path) {
            try? fileManager.removeItem(at: shopFile)
        }
        
        // 重新初始化預設資料
        initializeDefaultData()
        
        // 通知用戶界面更新
        objectWillChange.send()
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

    // 添加成就
    func unlockAchievement(id: String) {
        unlockedAchievements.insert(id)
    }
    
    // 檢查成就是否解鎖
    func isAchievementUnlocked(id: String) -> Bool {
        return unlockedAchievements.contains(id)
    }
} 