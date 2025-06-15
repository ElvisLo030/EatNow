import Foundation

// MARK: - 店家模型
struct Store: Identifiable, Codable, Equatable {
    var id: UUID
    let name: String
    let foods: [Food]
    
    init(name: String, foods: [Food]) {
        self.id = UUID()
        self.name = name
        self.foods = foods
    }
    
    // Equatable 實作
    static func == (lhs: Store, rhs: Store) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 食物模型
struct Food: Identifiable, Codable, Equatable {
    var id: UUID
    let name: String
    let price: Double
    let description: String?
    
    init(name: String, price: Double, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.description = description
    }
    
    // Equatable 實作
    static func == (lhs: Food, rhs: Food) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 點餐項目模型
struct OrderItem: Identifiable, Codable, Equatable {
    var id: UUID
    let food: Food
    var quantity: Int
    
    var totalPrice: Double {
        return food.price * Double(quantity)
    }
    
    init(food: Food, quantity: Int) {
        self.id = UUID()
        self.food = food
        self.quantity = quantity
    }
    
    // Equatable 實作
    static func == (lhs: OrderItem, rhs: OrderItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 歷史點餐模型
struct OrderHistory: Identifiable, Codable, Equatable {
    var id: UUID
    let storeName: String
    let items: [OrderItem]
    let orderDate: Date
    
    var totalAmount: Double {
        return items.reduce(0) { $0 + $1.totalPrice }
    }
    
    init(storeName: String, items: [OrderItem], orderDate: Date) {
        self.id = UUID()
        self.storeName = storeName
        self.items = items
        self.orderDate = orderDate
    }
    
    // Equatable 實作
    static func == (lhs: OrderHistory, rhs: OrderHistory) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 當前點餐模型
@MainActor
class CurrentOrder: ObservableObject {
    @Published var selectedStore: Store?
    @Published var items: [OrderItem] = []
    
    var totalAmount: Double {
        return items.reduce(0) { $0 + $1.totalPrice }
    }
    
    func addItem(_ food: Food, quantity: Int = 1) {
        if let existingIndex = items.firstIndex(where: { $0.food.id == food.id }) {
            items[existingIndex].quantity += quantity
        } else {
            items.append(OrderItem(food: food, quantity: quantity))
        }
    }
    
    func updateItemQuantity(_ itemId: UUID, quantity: Int) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            if quantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = quantity
            }
        }
    }
    
    func removeItem(_ itemId: UUID) {
        items.removeAll { $0.id == itemId }
    }
    
    func clearOrder() {
        selectedStore = nil
        items.removeAll()
    }
} 