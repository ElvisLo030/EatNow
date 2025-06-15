import SwiftUI

struct OrderHistoryView: View {
    @ObservedObject private var orderManager = OrderManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var sortedOrders: [OrderHistory] = []
    @State private var searchAmount: String = ""
    @State private var searchResults: [OrderHistory] = []
    @State private var showingSearchResults = false
    @State private var isSearching = false
    @State private var sortOrder: SortOrder = .dateDescending
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "時間 (新到舊)"
        case dateAscending = "時間 (舊到新)"
        case amountDescending = "金額 (高到低)"
        case amountAscending = "金額 (低到高)"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜尋和排序控制區
                controlSection
                
                // 歷史列表
                List {
                    if displayOrders.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(displayOrders) { order in
                            OrderHistoryCard(order: order, isHighlighted: showingSearchResults)
                        }
                        .onDelete(perform: deleteOrder)
                    }
                }
            }
            .navigationTitle("歷史點餐")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            loadAndSortOrders()
        }
        .onReceive(orderManager.$orderHistory) { _ in
            loadAndSortOrders()
        }
        .onChange(of: sortOrder) { _ in
            applySorting()
        }
    }
    
    // MARK: - Computed Properties
    private var displayOrders: [OrderHistory] {
        return showingSearchResults ? searchResults : sortedOrders
    }
    
    // MARK: - UI Components
    private var controlSection: some View {
        VStack(spacing: 12) {
            // 排序選擇器
            HStack {
                Text("排序方式:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("排序", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            
            // 搜尋區域
            HStack {
                TextField("輸入金額搜尋", text: $searchAmount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Button("搜尋") {
                    performSequentialSearch()
                }
                .disabled(searchAmount.isEmpty)
                .buttonStyle(.borderedProminent)
                
                if showingSearchResults {
                    Button("清除") {
                        clearSearch()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // 搜尋結果提示
            if showingSearchResults {
                HStack {
                    Text("搜尋結果: 找到 \(searchResults.count) 筆金額為 $\(searchAmount) 的記錄")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: showingSearchResults ? "magnifyingglass" : "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(showingSearchResults ? "找不到符合條件的記錄" : "暫無點餐記錄")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(showingSearchResults ? "請嘗試其他金額搜尋" : "開始您的第一次點餐吧！")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
    
    // MARK: - Data Management
    private func loadAndSortOrders() {
        sortedOrders = orderManager.orderHistory
        applySorting()
    }
    
    private func applySorting() {
        switch sortOrder {
        case .dateDescending:
            sortedOrders.sort { $0.orderDate > $1.orderDate }
        case .dateAscending:
            sortedOrders.sort { $0.orderDate < $1.orderDate }
        case .amountDescending:
            bubbleSortByAmount(ascending: false)
        case .amountAscending:
            bubbleSortByAmount(ascending: true)
        }
    }
    
    // MARK: - 氣泡排序演算法 (Bubble Sort)
    private func bubbleSortByAmount(ascending: Bool) {
        let n = sortedOrders.count
        
        for i in 0..<n {
            var swapped = false
            
            for j in 0..<(n - i - 1) {
                let shouldSwap = ascending ? 
                    sortedOrders[j].totalAmount > sortedOrders[j + 1].totalAmount :
                    sortedOrders[j].totalAmount < sortedOrders[j + 1].totalAmount
                
                if shouldSwap {
                    sortedOrders.swapAt(j, j + 1)
                    swapped = true
                }
            }
            
            // 如果這一輪沒有交換，表示已經排序完成
            if !swapped {
                break
            }
        }
    }
    
    // MARK: - 循序搜尋演算法 (Sequential Search)
    private func performSequentialSearch() {
        guard let targetAmount = Double(searchAmount) else {
            searchResults = []
            showingSearchResults = true
            return
        }
        
        searchResults = []
        
        // 循序搜尋實作
        for i in 0..<sortedOrders.count {
            if Int(sortedOrders[i].totalAmount) == Int(targetAmount) {
                searchResults.append(sortedOrders[i])
            }
        }
        
        showingSearchResults = true
    }
    
    private func clearSearch() {
        searchAmount = ""
        searchResults = []
        showingSearchResults = false
    }
    
    private func deleteOrder(at offsets: IndexSet) {
        for index in offsets {
            let order = displayOrders[index]
            orderManager.deleteOrder(order.id)
        }
        
        // 重新整理資料
        loadAndSortOrders()
        if showingSearchResults {
            performSequentialSearch()
        }
    }
}

struct OrderHistoryCard: View {
    let order: OrderHistory
    let isHighlighted: Bool
    
    init(order: OrderHistory, isHighlighted: Bool = false) {
        self.order = order
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 店家名稱和時間
            HStack {
                Text(order.storeName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatDate(order.orderDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 點餐項目
            VStack(alignment: .leading, spacing: 8) {
                ForEach(order.items) { item in
                    HStack {
                        Text(item.food.name)
                            .font(.body)
                        
                        Spacer()
                        
                        Text("×\(item.quantity)")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("$\(item.totalPrice, specifier: "%.0f")")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Divider()
            
            // 總金額
            HStack {
                Text("總計")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("$\(order.totalAmount, specifier: "%.0f")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isHighlighted ? .blue : .primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.blue : Color.clear, lineWidth: 2)
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    OrderHistoryView()
} 