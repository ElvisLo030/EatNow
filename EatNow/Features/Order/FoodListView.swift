import SwiftUI

struct FoodListView: View {
    @ObservedObject var currentOrder: CurrentOrder
    @Environment(\.dismiss) private var dismiss
    @State private var showingOrderPreview = false
    let onOrderCompleted: (() -> Void)?
    
    init(currentOrder: CurrentOrder, onOrderCompleted: (() -> Void)? = nil) {
        self.currentOrder = currentOrder
        self.onOrderCompleted = onOrderCompleted
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 食物列表
                List {
                    if let store = currentOrder.selectedStore {
                        ForEach(store.foods) { food in
                            FoodRow(food: food, currentOrder: currentOrder)
                        }
                    }
                }
                
                // 底部結算按鈕
                if !currentOrder.items.isEmpty {
                    orderSummaryButton
                }
            }
            .navigationTitle(currentOrder.selectedStore?.name ?? "選擇餐點")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingOrderPreview) {
                OrderPreviewView(currentOrder: currentOrder, onOrderCompleted: onOrderCompleted)
            }
        }
    }
    
    private var orderSummaryButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: {
                showingOrderPreview = true
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("共 \(currentOrder.items.count) 項")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("$\(currentOrder.totalAmount, specifier: "%.0f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("結算")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct FoodRow: View {
    let food: Food
    @ObservedObject var currentOrder: CurrentOrder
    @State private var isUpdating = false
    
    private var currentQuantity: Int {
        currentOrder.items.first { $0.food.id == food.id }?.quantity ?? 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 食物資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = food.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("$\(food.price, specifier: "%.0f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // 數量選擇器
            if currentQuantity > 0 {
                HStack(spacing: 16) {
                    Button {
                        decreaseQuantity()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isUpdating)
                    
                    Text("\(currentQuantity)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(minWidth: 30)
                    
                    Button {
                        increaseQuantity()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isUpdating)
                }
            } else {
                Button {
                    addToOrder()
                } label: {
                    Text("加入")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isUpdating)
            }
        }
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
    
    private func addToOrder() {
        guard !isUpdating else { return }
        isUpdating = true
        
        DispatchQueue.main.async {
            currentOrder.addItem(food, quantity: 1)
            isUpdating = false
        }
    }
    
    private func increaseQuantity() {
        guard !isUpdating else { return }
        isUpdating = true
        
        DispatchQueue.main.async {
            if let existingItem = currentOrder.items.first(where: { $0.food.id == food.id }) {
                currentOrder.updateItemQuantity(existingItem.id, quantity: existingItem.quantity + 1)
            }
            isUpdating = false
        }
    }
    
    private func decreaseQuantity() {
        guard !isUpdating else { return }
        isUpdating = true
        
        DispatchQueue.main.async {
            if let existingItem = currentOrder.items.first(where: { $0.food.id == food.id }) {
                let newQuantity = existingItem.quantity - 1
                if newQuantity <= 0 {
                    currentOrder.removeItem(existingItem.id)
                } else {
                    currentOrder.updateItemQuantity(existingItem.id, quantity: newQuantity)
                }
            }
            isUpdating = false
        }
    }
}

#Preview {
    FoodListView(currentOrder: {
        let order = CurrentOrder()
        order.selectedStore = Store(name: "測試店家", foods: [
            Food(name: "測試餐點", price: 100.0, description: "美味的測試餐點")
        ])
        return order
    }())
} 