import SwiftUI
import Foundation

// 基本數據模型
struct Shop: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var menuItems: [MenuItem]
}

struct MenuItem: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var price: Int
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