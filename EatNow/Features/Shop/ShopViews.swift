import SwiftUI

// 店家列表視圖
struct ShopListView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var path: [ShopNavigationItem] = []
    @State private var isSelecting = false
    @State private var selectedShops: Set<Int> = []
    @State private var showCSVImport = false
    
    // 將按鈕提取為單獨的視圖以減少複雜性
    private var controlRow: some View {
        HStack {
            Button(action: {
                if isSelecting {
                    // 取消選取模式
                    selectedShops.removeAll()
                    isSelecting = false
                } else {
                    // 進入選取模式
                    isSelecting = true
                }
            }) {
                Text(isSelecting ? "取消" : "選取")
                    .font(.system(.body).weight(.regular))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            .buttonStyle(BorderlessButtonStyle()) // 防止按鈕事件傳遞

            Spacer()
            
            // 批量刪除按鈕，只在選取模式中顯示
            if isSelecting {
                Button(action: {
                    dataStore.deleteShop(at: IndexSet(selectedShops))
                    selectedShops.removeAll()
                    isSelecting = false
                }) {
                    Text("批量刪除")
                        .font(.system(.body).weight(.regular))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(selectedShops.isEmpty)
                .opacity(selectedShops.isEmpty ? 0.5 : 1)
            }
            
            // 在非選取模式下只顯示匯入按鈕
            if !isSelecting {
                // 匯入按鈕
                Button {
                    showCSVImport = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
    
    // 選擇模式的店家行視圖
    private func selectingShopRow(index: Int) -> some View {
        HStack(spacing: 14) {
            Button(action: {
                if selectedShops.contains(index) {
                    selectedShops.remove(index)
                } else {
                    selectedShops.insert(index)
                }
            }) {
                Image(systemName: selectedShops.contains(index) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selectedShops.contains(index) ? .blue : .gray.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Text(dataStore.shops[index].name)
                .font(.body)
                .fontWeight(.regular)
            
            Spacer()
            
            Text("\(dataStore.shops[index].menuItems.count) 項商品")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
    
    // 正常模式的店家行視圖
    private func normalShopRow(index: Int) -> some View {
        NavigationLink(value: ShopNavigationItem.shop(index: index)) {
            HStack {
                Text(dataStore.shops[index].name)
                    .font(.body)
                    .fontWeight(.regular)
                
                Spacer()
                
                Text("\(dataStore.shops[index].menuItems.count) 項商品")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    controlRow
                        .background(Color(.systemGroupedBackground))
                    
                    List {
                        ForEach(dataStore.shops.indices, id: \.self) { index in
                            if isSelecting {
                                selectingShopRow(index: index)
                                    .listRowBackground(Color(.systemBackground))
                            } else {
                                normalShopRow(index: index)
                                    .listRowBackground(Color(.systemBackground))
                            }
                        }
                        .onDelete { indexSet in
                            dataStore.deleteShop(at: indexSet)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("店家列表")
            .sheet(isPresented: $showCSVImport) {
                CSVImportView(importOnly: true)
                    .environmentObject(dataStore)
            }
            .navigationDestination(for: ShopNavigationItem.self) { item in
                switch item {
                case .shop(let idx):
                    ShopDetailView(shopIndex: idx, path: $path)
                        .environmentObject(dataStore)
                case .menu(let sIdx, let iIdx):
                    MenuItemEditView(shopIndex: sIdx, itemIndex: iIdx)
                        .environmentObject(dataStore)
                case .newMenuItem(let sIdx):
                    NewMenuItemView(shopIndex: sIdx)
                        .environmentObject(dataStore)
                case .customFoods:
                    EmptyView() // 不再使用自定義食物視圖
                }
            }
        }
    }
}

// 修改 ShopDetailView 結構體
struct ShopDetailView: View {
    @EnvironmentObject private var dataStore: DataStore
    let shopIndex: Int
    @Binding var path: [ShopNavigationItem]
    @State private var isEditingName = false
    @FocusState private var shopNameFieldIsFocused: Bool

    var body: some View {
        if shopIndex >= dataStore.shops.count {
            Text("店家已刪除或不存在")
                .foregroundColor(.secondary)
                .navigationTitle("店家不存在")
        } else {
            let shopBinding = $dataStore.shops[shopIndex]
            let shop = shopBinding.wrappedValue

            ZStack {
                Color.clear.onTapGesture { UIApplication.shared.endEditing() }
                Form {
                    // 店家名稱
                    Section {
                        if isEditingName {
                            TextField("店家名稱", text: shopBinding.name)
                                .font(.title3.bold())
                                .focused($shopNameFieldIsFocused)
                        } else {
                            HStack {
                                Text(shop.name)
                                    .font(.title3.bold())
                                Spacer()
                                Button("") {
                                    isEditingName = true
                                    shopNameFieldIsFocused = true
                                }
                            }
                        }
                    }

                    // 移除原本的新增菜單項目 Section

                    // 菜單清單
                    Section(header: Text("菜單列表")) {
                        ForEach(shop.menuItems.indices, id: \.self) { idx in
                            NavigationLink(value: ShopNavigationItem.menu(shopIndex: shopIndex, itemIndex: idx)) {
                                HStack {
                                    Text(shop.menuItems[idx].name)
                                    Spacer()
                                    Text("\(shop.menuItems[idx].price) 元")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            dataStore.deleteMenuItem(shopIndex: shopIndex, at: indexSet)
                        }
                        .animation(.easeInOut, value: shop.menuItems)
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationTitle("菜單管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 修改 ShopDetailView 的工具列按鈕
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 不再直接新增資料，只是導航到新建項目頁面
                        path.append(.newMenuItem(shopIndex: shopIndex))
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                        }
                    }
                }
                
                // 保留原有的鍵盤工具列
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Button("取消") {
                            isEditingName = false
                            UIApplication.shared.endEditing()
                        }
                        Spacer()
                        Button("確定") {
                            isEditingName = false
                            UIApplication.shared.endEditing()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// 菜單項目編輯視圖
struct MenuItemEditView: View {
    @EnvironmentObject private var dataStore: DataStore
    let shopIndex: Int
    let itemIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var itemName: String = ""
    @State private var itemPrice: String = ""
    @FocusState private var itemNameFieldIsFocused: Bool

    var body: some View {
        guard shopIndex < dataStore.shops.count,
              itemIndex < dataStore.shops[shopIndex].menuItems.count else {
            return AnyView(Text("資料不存在").foregroundColor(.secondary))
        }
        return AnyView(
            ZStack {
                Color.clear.onTapGesture { UIApplication.shared.endEditing() }
                Form {
                    Section(header: Text("商品資訊")) {
                        TextField("商品名稱", text: $itemName)
                            .focused($itemNameFieldIsFocused)
                        TextField("商品價格", text: $itemPrice)
                            .keyboardType(.numberPad)
                    }

                    Section {
                        Button("儲存") {
                            if let price = Int(itemPrice) {
                                dataStore.shops[shopIndex].menuItems[itemIndex].name = itemName
                                dataStore.shops[shopIndex].menuItems[itemIndex].price = price
                            }
                            dismiss()
                        }
                        .disabled(itemName.isEmpty || itemPrice.isEmpty)
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationTitle("編輯商品")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let item = dataStore.shops[shopIndex].menuItems[itemIndex]
                itemName = item.name
                itemPrice = "\(item.price)"
                itemNameFieldIsFocused = true
            }
            .animation(.easeInOut, value: dataStore.shops[shopIndex].menuItems)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Button("取消") {
                            dismiss()
                            UIApplication.shared.endEditing()
                        }
                        Spacer()
                        Button("確定") {
                            if let price = Int(itemPrice) {
                                dataStore.shops[shopIndex].menuItems[itemIndex].name = itemName
                                dataStore.shops[shopIndex].menuItems[itemIndex].price = price
                            }
                            dismiss()
                            UIApplication.shared.endEditing()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        )
    }
}

// 將 NavigationItem 改名為 ShopNavigationItem
enum ShopNavigationItem: Hashable {
    case shop(index: Int)
    case menu(shopIndex: Int, itemIndex: Int)
    case newMenuItem(shopIndex: Int)
    case customFoods
}

// 添加新的 NewMenuItemView 結構體
struct NewMenuItemView: View {
    @EnvironmentObject private var dataStore: DataStore
    let shopIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var itemName: String = ""
    @State private var itemPrice: String = ""
    @FocusState private var itemNameFieldIsFocused: Bool
    
    var body: some View {
        ZStack {
            Color.clear.onTapGesture { UIApplication.shared.endEditing() }
            Form {
                Section(header: Text("商品資訊")) {
                    TextField("商品名稱", text: $itemName)
                        .focused($itemNameFieldIsFocused)
                    TextField("商品價格", text: $itemPrice)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button("新增商品") {
                        if let price = Int(itemPrice), !itemName.isEmpty {
                            // 只有當用戶點擊「新增商品」按鈕時才實際添加數據
                            dataStore.addMenuItem(to: shopIndex, name: itemName, price: price)
                        }
                        dismiss()
                    }
                    .disabled(itemName.isEmpty || itemPrice.isEmpty)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(itemName.isEmpty || itemPrice.isEmpty ? .gray : .blue)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationTitle("新增商品")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 預設聚焦在商品名稱欄位
            itemNameFieldIsFocused = true
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button("取消") {
                        dismiss()
                        UIApplication.shared.endEditing()
                    }
                    Spacer()
                    Button("確定") {
                        if let price = Int(itemPrice), !itemName.isEmpty {
                            // 只有當用戶點擊「確定」按鈕且輸入有效時才添加數據
                            dataStore.addMenuItem(to: shopIndex, name: itemName, price: price)
                            dismiss()
                        }
                        UIApplication.shared.endEditing()
                    }
                    .disabled(itemName.isEmpty || itemPrice.isEmpty)
                }
                .padding(.horizontal)
            }
        }
    }
}
