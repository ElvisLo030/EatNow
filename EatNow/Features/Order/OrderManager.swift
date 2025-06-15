import Foundation
import Combine
import SwiftUI

@MainActor
class OrderManager: ObservableObject {
    static let shared = OrderManager()
    
    @Published var orderHistory: [OrderHistory] = []
    @Published var availableStores: [Store] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "OrderHistory"
    private let dataStore = DataStore.shared
    
    private init() {
        loadOrderHistory()
        loadStoresFromDataStore()
        
        // 監聽 DataStore 的店家資料變化
        setupDataStoreObserver()
    }
    
    // MARK: - 歷史點餐管理
    func loadOrderHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([OrderHistory].self, from: data) {
            orderHistory = history.sorted { $0.orderDate > $1.orderDate }
        }
    }
    
    func saveOrderHistory() {
        if let data = try? JSONEncoder().encode(orderHistory) {
            userDefaults.set(data, forKey: historyKey)
        }
    }
    
    func addOrder(_ order: OrderHistory) {
        orderHistory.insert(order, at: 0)
        saveOrderHistory()
    }
    
    func deleteOrder(_ orderId: UUID) {
        orderHistory.removeAll { $0.id == orderId }
        saveOrderHistory()
    }
    
    // MARK: - 店家資料管理
    private func loadStoresFromDataStore() {
        Task {
            await convertDataStoreShopsToStores()
        }
    }
    
    private func setupDataStoreObserver() {
        // 監聽 DataStore 的店家資料變化
        Task {
            for await _ in dataStore.$shops.values {
                await convertDataStoreShopsToStores()
            }
        }
    }
    
    private func convertDataStoreShopsToStores() async {
        availableStores = dataStore.shops.map { shop in
            let foods = shop.menuItems.map { menuItem in
                Food(
                    name: menuItem.name,
                    price: Double(menuItem.price),
                    description: nil
                )
            }
            return Store(name: shop.name, foods: foods)
        }
    }
    
    func getStore(by name: String) -> Store? {
        return availableStores.first { $0.name == name }
    }
} 