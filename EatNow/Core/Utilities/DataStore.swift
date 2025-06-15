import SwiftUI
import Foundation
import CryptoKit

// 數據儲存管理器
@MainActor
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
        didSet { 
            // 當使用者名稱有值且還沒有使用者編號時，生成編號
            if !userName.isEmpty && userID.isEmpty {
                generateUserID()
            } else if !userName.isEmpty && !userID.isEmpty && userName != oldValue {
                // 如果使用者名稱改變且已有編號，調用API更新名稱
                updateUserNameToAPI(oldName: oldValue, newName: userName)
            }
            saveUserProfile() 
        }
    }
    @Published var userAvatarName: String = "" {
        didSet { saveUserProfile() }
    }
    
    // 控制是否啟用特效
    @Published var effectsEnabled: Bool = false {
        didSet { saveUserProfile() }
    }
    
    // 使用者編號相關屬性
    @Published var userID: String = "" {
        didSet { saveUserProfile() }
    }
    @Published var userCreatedDate: Date? = nil {
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
        var userID: String = ""
        var userCreatedDate: Date? = nil
    }
    
    private func loadUserProfile() {
        guard FileManager.default.fileExists(atPath: userProfileURL.path) else { 
            return 
        }
        if let data = try? Data(contentsOf: userProfileURL),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userName = decoded.name
            userAvatarName = decoded.avatarName
            effectsEnabled = decoded.effectsEnabled
            userID = decoded.userID
            userCreatedDate = decoded.userCreatedDate
        }
    }
    
    private func saveUserProfile() {
        let profile = UserProfile(
            name: userName, 
            avatarName: userAvatarName, 
            effectsEnabled: effectsEnabled, 
            userID: userID,
            userCreatedDate: userCreatedDate
        )
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
        
        // 不再自動確保使用者編號，只有在輸入使用者名稱後才會生成
        // 如果沒有數據，初始化示範數據
        if shops.isEmpty {
            initializeDefaultData()
        }
        
        // 在初始化後檢查雲端狀態
        Task { @MainActor in
            await checkCloudMenuStatus()
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
                markShopAsModified(shopIndex: shopIndex)
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
                markShopAsModified(shopIndex: shopIndex)
            }
        }
    }
    
    // 公開方法：標記店家為已修改
    func markShopAsModified(shopIndex: Int) {
        guard shopIndex < shops.count else { return }
        
        // 只有在已同步狀態下才標記為修改
        if shops[shopIndex].cloudStatus == .synced {
            shops[shopIndex].cloudStatus = .modified
        }
        // 設定修改時間
        shops[shopIndex].lastModifiedDate = Date()
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
    
    // 生成使用者編號的方法
    @discardableResult
    func generateUserID() -> String {
        if userID.isEmpty {
            userCreatedDate = Date()
            
            // 嘗試從API生成編號
            Task { @MainActor in
                if let apiGeneratedID = await generateNewUserID() {
                    self.userID = apiGeneratedID
                    self.saveUserProfile()
                    
                    // 立即註冊用戶到API
                    Task {
                        let result = await APIService.shared.createUser(
                            name: self.userName,
                            userID: self.userID,
                            createdDate: self.userCreatedDate!
                        )
                        
                        if let response = result, response.success {
                            print("✅ 用戶註冊成功: \(self.userID)")
                        } else {
                            print("❌ 用戶註冊失敗: \(result?.message ?? "未知錯誤")")
                        }
                    }
                } else {
                    // API失敗時使用本地生成
                    self.generateLocalUserID()
                }
            }
            
            // 立即返回本地生成的ID（防止UI等待）
            generateLocalUserID()
        }
        return userID
    }
    
    // 本地生成用戶ID的備用方法
    private func generateLocalUserID() {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let newUserID = String((0..<8).map { _ in characters.randomElement()! })
        userID = newUserID
        userCreatedDate = Date()
        saveUserProfile()
        
        // 嘗試同步到API
        syncUserToAPI()
    }
    
    // 公開方法：重新獲取使用者編號（當API記錄失敗時使用）
    func retryUserIDRegistration() {
        guard !userName.isEmpty, !userID.isEmpty, let createdDate = userCreatedDate else { return }
        
        Task {
            let result = await APIService.shared.createUser(name: userName, userID: userID, createdDate: createdDate)
            
            if let response = result, response.success {
                print("✅ 用戶重新註冊成功: \(userID)")
            } else {
                print("❌ 用戶重新註冊失敗: \(result?.message ?? "未知錯誤")")
            }
        }
    }
    
    // MARK: - 雲端菜單管理方法
    
    /// 生成6位數店家編號
    private func generateShopCode() -> String {
        return String(format: "%06d", Int.random(in: 100000...999999))
    }
    
    /// 上傳單個店家菜單到雲端
    func uploadMenuToCloud(shopIndex: Int) async -> Bool {
        guard shopIndex < shops.count, !userID.isEmpty else { return false }
        
        var shop = shops[shopIndex]
        
        // 如果沒有店家編號，生成一個
        if shop.shopCode == nil {
            shop.shopCode = generateShopCode()
        }
        
        // 更新狀態為上傳中
        shops[shopIndex].cloudStatus = .uploading
        
        let result = await APIService.shared.uploadMenu(
            userID: userID,
            shopName: shop.name,
            shopCode: shop.shopCode!,
            menuItems: shop.menuItems
        )
        
        if let response = result, response.success {
            shops[shopIndex].cloudStatus = .synced
            shops[shopIndex].shopCode = shop.shopCode
            shops[shopIndex].uploadDate = Date()
            // 清除修改时间，因為已經同步
            shops[shopIndex].lastModifiedDate = nil
            // 保存雲端返回的內容雜湊
            if let contentHash = response.data?.contentHash {
                shops[shopIndex].contentHash = contentHash
            }
            print("✅ 店家菜單上傳成功: \(shop.name)")
        } else {
            shops[shopIndex].cloudStatus = .failed
            print("❌ 店家菜單上傳失敗: \(shop.name)")
        }
        
        return result?.success ?? false
    }
    
    /// 批量上傳選中的店家菜單
    func batchUploadMenusToCloud(shopIndices: [Int]) async -> (successCount: Int, totalCount: Int) {
        guard !userID.isEmpty else { return (0, shopIndices.count) }
        
        var successCount = 0
        
        // 更新所有選中店家的狀態為上傳中
        for index in shopIndices {
            if index < shops.count {
                shops[index].cloudStatus = .uploading
                if shops[index].shopCode == nil {
                    shops[index].shopCode = generateShopCode()
                }
            }
        }
        
        let selectedShops = shopIndices.compactMap { index in
            index < shops.count ? shops[index] : nil
        }
        
        let result = await APIService.shared.batchUploadMenus(userID: userID, shops: selectedShops)
        
        if let response = result, response.success, let data = response.data {
            successCount = data.successCount
            
            // 更新成功上傳的店家狀態
            for (i, index) in shopIndices.enumerated() {
                if index < shops.count {
                    if i < data.uploadedShops.count {
                        shops[index].cloudStatus = .synced
                        shops[index].uploadDate = Date()
                        // 清除修改時間，因為已經同步
                        shops[index].lastModifiedDate = nil
                        shops[index].shopCode = data.uploadedShops[i].shopCode
                        // 保存雲端返回的內容雜湊
                        if let contentHash = data.uploadedShops[i].contentHash {
                            shops[index].contentHash = contentHash
                        }
                    } else {
                        shops[index].cloudStatus = .failed
                    }
                }
            }
            
            print("✅ 批量上傳完成: \(successCount)/\(shopIndices.count)")
        } else {
            // 上傳失敗，重置狀態
            for index in shopIndices {
                if index < shops.count {
                    shops[index].cloudStatus = .failed
                }
            }
            print("❌ 批量上傳失敗")
        }
        
        return (successCount, shopIndices.count)
    }
    
    /// 檢查並更新所有店家的雲端狀態
    func checkCloudMenuStatus() async {
        guard !userID.isEmpty else { return }
        
        // 使用新的詳細狀態查詢 API
        let result = await APIService.shared.getDetailedMenuStatus(userID: userID)
        
        if let response = result, response.success, let data = response.data {
            // 根據雲端狀態更新本地店家狀態
            for cloudShop in data.shops {
                if let localShopIndex = shops.firstIndex(where: { $0.shopCode == cloudShop.shopCode }) {
                    // 直接使用雲端返回的同步狀態
                    switch cloudShop.syncStatus {
                    case "synced":
                        shops[localShopIndex].cloudStatus = .synced
                    case "modified":
                        shops[localShopIndex].cloudStatus = .modified
                    case "not_synced":
                        shops[localShopIndex].cloudStatus = .notSynced
                    default:
                        shops[localShopIndex].cloudStatus = .notSynced
                    }
                    
                    // 更新上傳日期
                    if cloudShop.isUploaded {
                        if let uploadDate = ISO8601DateFormatter().date(from: cloudShop.uploadDate) {
                            shops[localShopIndex].uploadDate = uploadDate
                        }
                    }
                }
            }
        }
    }
    
    /// 重新上傳已修改的店家菜單
    func reuploadModifiedMenu(shopIndex: Int) async -> Bool {
        guard shopIndex < shops.count, 
              shops[shopIndex].cloudStatus == .modified,
              let shopCode = shops[shopIndex].shopCode,
              !userID.isEmpty else { return false }
        
        let shop = shops[shopIndex]
        
        // 更新狀態為上傳中
        shops[shopIndex].cloudStatus = .uploading
        
        let result = await APIService.shared.updateMenu(
            userID: userID,
            shopCode: shopCode,
            shopName: shop.name,
            menuItems: shop.menuItems
        )
        
        switch result {
        case .success(let response):
            if response.success {
                shops[shopIndex].cloudStatus = .synced
                shops[shopIndex].uploadDate = Date()
                // 清除修改時間，因為已經同步
                shops[shopIndex].lastModifiedDate = nil
                // 保存雲端返回的內容雜湊
                if let contentHash = response.data?.contentHash {
                    shops[shopIndex].contentHash = contentHash
                }
                print("✅ 店家菜單重新上傳成功: \(shop.name)")
                return true
            } else {
                shops[shopIndex].cloudStatus = .failed
                print("❌ 店家菜單重新上傳失敗: \(shop.name)")
                return false
            }
        case .failure(let error):
            shops[shopIndex].cloudStatus = .failed
            print("❌ 店家菜單重新上傳失敗: \(shop.name) - \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 菜單內容雜湊生成方法
    
    /// 生成菜單內容的雜湊值，用於比對菜單是否有變更
    func generateMenuContentHash(for menuItems: [MenuItem]) -> String {
        // 標準化排序：按名稱排序以確保一致性
        let sortedItems = menuItems
            .sorted { $0.name < $1.name }
            .map { "\($0.name):\($0.price)" }
            .joined(separator: "|")
        
        let data = sortedItems.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// 比對本地菜單與雲端菜單內容是否一致
    func verifyMenuContent(shopIndex: Int) async -> Bool {
        guard shopIndex < shops.count,
              let shopCode = shops[shopIndex].shopCode else { return false }
        
        let shop = shops[shopIndex]
        let localHash = generateMenuContentHash(for: shop.menuItems)
        
        // 調用新的菜單驗證 API
        let verificationShop = MenuVerificationShop(
            shopCode: shopCode,
            contentHash: localHash,
            menuItems: shop.menuItems.map { CloudMenuItem(name: $0.name, price: $0.price) }
        )
        
        let result = await APIService.shared.verifyMenuContent(
            userID: userID,
            shops: [verificationShop]
        )
        
        if let response = result, response.success, let data = response.data {
            return data.verificationResults.first?.isContentMatched ?? false
        }
        
        return false
    }
    
    // MARK: - 雲端菜單刪除方法
    
    /// 刪除雲端菜單
    func deleteCloudMenu(shopCode: String) async -> (success: Bool, message: String) {
        guard !userID.isEmpty else { 
            return (false, "用戶編號不存在，請先在設定中創建用戶編號")
        }
        
        let result = await APIService.shared.deleteMenu(shopCode: shopCode, userID: userID)
        
        switch result {
        case .success(let response):
            if response.success {
                // 更新本地店家的雲端狀態
                if let index = shops.firstIndex(where: { $0.shopCode == shopCode }) {
                    shops[index].cloudStatus = .notSynced
                    shops[index].shopCode = nil
                    shops[index].uploadDate = nil
                    shops[index].contentHash = nil
                }
                
                return (true, response.data?.message ?? "菜單刪除成功")
            } else {
                return (false, response.detail ?? "刪除失敗")
            }
        case .failure(let error):
            let errorMessage = APIService.shared.handleAPIError(error)
            return (false, errorMessage)
        }
    }
    
    /// 更新雲端菜單
    func updateCloudMenu(shopCode: String) async -> (success: Bool, message: String) {
        guard !userID.isEmpty else { 
            return (false, "用戶編號不存在，請先在設定中創建用戶編號")
        }
        
        guard let shop = shops.first(where: { $0.shopCode == shopCode }) else {
            return (false, "找不到對應的本地店家資料")
        }
        
        let result = await APIService.shared.updateMenu(
            userID: userID,
            shopCode: shopCode,
            shopName: shop.name,
            menuItems: shop.menuItems
        )
        
        switch result {
        case .success(let response):
            if response.success {
                // 更新本地店家狀態
                if let index = shops.firstIndex(where: { $0.shopCode == shopCode }) {
                    shops[index].cloudStatus = .synced
                    shops[index].uploadDate = Date()
                    shops[index].lastModifiedDate = nil
                    
                    // 更新內容雜湊
                    if let contentHash = response.data?.contentHash {
                        shops[index].contentHash = contentHash
                    }
                }
                
                return (true, "菜單更新成功")
            } else {
                return (false, response.message ?? "更新失敗")
            }
        case .failure(let error):
            let errorMessage = APIService.shared.handleAPIError(error)
            return (false, errorMessage)
        }
    }
}