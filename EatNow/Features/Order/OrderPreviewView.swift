import SwiftUI

struct OrderPreviewView: View {
    @ObservedObject var currentOrder: CurrentOrder
    @ObservedObject private var orderManager = OrderManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    let onOrderCompleted: (() -> Void)?
    
    init(currentOrder: CurrentOrder, onOrderCompleted: (() -> Void)? = nil) {
        self.currentOrder = currentOrder
        self.onOrderCompleted = onOrderCompleted
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 店家資訊
                if let store = currentOrder.selectedStore {
                    storeInfoHeader(store: store)
                }
                
                // 點餐列表
                List {
                    ForEach(currentOrder.items) { item in
                        OrderItemRow(item: item, currentOrder: currentOrder)
                    }
                    .onDelete(perform: deleteItems)
                }
                
                // 總計和確認按鈕
                orderTotalSection
            }
            .navigationTitle("確認點餐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .alert("確認點餐", isPresented: $showingConfirmation) {
                Button("取消", role: .cancel) { }
                Button("確認") {
                    confirmOrder()
                }
            } message: {
                Text("確認要下單嗎？")
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
    
    private func storeInfoHeader(store: Store) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "storefront.fill")
                    .foregroundColor(.blue)
                
                Text(store.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            Divider()
        }
        .padding(.vertical, 8)
    }
    
    private var orderTotalSection: some View {
        VStack(spacing: 16) {
            Divider()
            
            // 總計資訊
            HStack {
                Text("總計")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("$\(currentOrder.totalAmount, specifier: "%.0f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            // 確認按鈕
            Button(action: {
                showingConfirmation = true
            }) {
                Text("確認點餐")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(currentOrder.items.isEmpty)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = currentOrder.items[index]
            currentOrder.removeItem(item.id)
        }
    }
    
    private func confirmOrder() {
        guard let store = currentOrder.selectedStore else { return }
        
        let orderHistory = OrderHistory(
            storeName: store.name,
            items: currentOrder.items,
            orderDate: Date()
        )
        
        orderManager.addOrder(orderHistory)
        currentOrder.clearOrder()
        
        // 先關閉當前視圖，然後調用完成回調
        dismiss()
        
        // 延遲調用完成回調，確保視圖已經關閉
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onOrderCompleted?()
        }
    }
}

struct OrderItemRow: View {
    let item: OrderItem
    @ObservedObject var currentOrder: CurrentOrder
    @State private var isUpdating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 餐點資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(item.food.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("$\(item.food.price, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 數量調整器
            HStack(spacing: 16) {
                Button {
                    decreaseQuantity()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(item.quantity <= 1 || isUpdating)
                
                Text("\(item.quantity)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(minWidth: 30)
                
                Button {
                    increaseQuantity()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isUpdating)
            }
            
            // 小計
            Text("$\(item.totalPrice, specifier: "%.0f")")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                currentOrder.removeItem(item.id)
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }
    
    private func increaseQuantity() {
        guard !isUpdating else { return }
        isUpdating = true
        
        DispatchQueue.main.async {
            currentOrder.updateItemQuantity(item.id, quantity: item.quantity + 1)
            isUpdating = false
        }
    }
    
    private func decreaseQuantity() {
        guard !isUpdating else { return }
        isUpdating = true
        
        DispatchQueue.main.async {
            let newQuantity = item.quantity - 1
            if newQuantity <= 0 {
                currentOrder.removeItem(item.id)
            } else {
                currentOrder.updateItemQuantity(item.id, quantity: newQuantity)
            }
            isUpdating = false
        }
    }
}

#Preview {
    OrderPreviewView(currentOrder: {
        let order = CurrentOrder()
        order.selectedStore = Store(name: "測試店家", foods: [])
        order.items = [
            OrderItem(food: Food(name: "測試餐點", price: 100.0, description: "美味測試"), quantity: 2)
        ]
        return order
    }())
} 