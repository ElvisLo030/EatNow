import SwiftUI
import Foundation

// 基本數據模型
struct Shop: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var menuItems: [MenuItem]
    var cloudStatus: CloudSyncStatus = .notSynced
    var shopCode: String? // 6位數店家編號，用於雲端識別
    var lastModifiedDate: Date? // 改為可選值，避免每次初始化都設為當前時間
    var uploadDate: Date?
    var contentHash: String? // 新增：菜單內容雜湊值，用於快速比對
    
    // 自定義初始化方法
    init(name: String, menuItems: [MenuItem]) {
        self.name = name
        self.menuItems = menuItems
        self.lastModifiedDate = nil // 初始時不設定修改時間
        self.contentHash = nil // 初始時無雜湊值
    }
}

struct MenuItem: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var price: Int
}

// 雲端同步狀態
enum CloudSyncStatus: String, Codable, CaseIterable {
    case notSynced = "not_synced"      // 未上傳
    case synced = "synced"             // 已同步
    case modified = "modified"         // 已修改，需要重新上傳
    case uploading = "uploading"       // 上傳中
    case failed = "failed"             // 上傳失敗
}

// 自定義食物項目
struct CustomFood: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    
    static func defaultItems() -> [CustomFood] {
        return ["便當", "麵食", "漢堡", "沙拉", "壽司"].map { CustomFood(name: $0) }
    }
}

// MARK: - OrderRecord Data Model
struct OrderRecord: Identifiable, Codable {
    var id = UUID()
    var personName: String
    var itemName: String
    var note: String
    var price: Int
}

// 統計區段
struct StatsSession: Identifiable, Codable {
    var id = UUID()
    var shopName: String
    var records: [OrderRecord]
    var date: Date
}

// 導航項目，用於 NavigationPath
enum NavigationItem: Hashable {
    case shop(index: Int)
    case menu(shopIndex: Int, itemIndex: Int)
    case customFoods
} 