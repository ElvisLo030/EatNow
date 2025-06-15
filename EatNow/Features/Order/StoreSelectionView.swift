import SwiftUI

struct StoreSelectionView: View {
    @ObservedObject private var orderManager = OrderManager.shared
    @ObservedObject var currentOrder: CurrentOrder
    @Environment(\.dismiss) private var dismiss
    @State private var showingFoodList = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(orderManager.availableStores) { store in
                    StoreCard(store: store) {
                        selectStore(store)
                    }
                }
            }
            .navigationTitle("選擇店家")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showingFoodList) {
            FoodListView(currentOrder: currentOrder) {
                // 當訂單完成後，關閉所有視圖
                showingFoodList = false
                dismiss()
            }
        }
    }
    
    private func selectStore(_ store: Store) {
        currentOrder.selectedStore = store
        currentOrder.items.removeAll() // 清空之前的點餐項目
        showingFoodList = true
    }
}

struct StoreCard: View {
    let store: Store
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(store.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                Text("共 \(store.foods.count) 樣餐點")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // 顯示部分餐點預覽
                HStack {
                    ForEach(Array(store.foods.prefix(3)), id: \.id) { food in
                        Text(food.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    
                    if store.foods.count > 3 {
                        Text("...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
    }
}

#Preview {
    StoreSelectionView(currentOrder: CurrentOrder())
} 