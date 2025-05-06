import SwiftUI

// 店家列表視圖
struct ShopListView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var path: [NavigationItem] = []
    @State private var isPresentingNewShop = false
    @State private var newShopName = ""
    @State private var isPresentingEditShop = false
    @State private var editingShopIndex: Int? = nil
    @State private var editingShopName = ""
    @State private var isSelecting = false
    @State private var selectedShops: Set<Int> = []
    
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
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
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(selectedShops.isEmpty)
            }
            
            // 新增按鈕，只在非選取模式中顯示
            if !isSelecting {
                Button {
                    isPresentingNewShop = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .padding(8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(BorderlessButtonStyle()) // 防止按鈕事件傳遞
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8) // 增加整個控制列的水平內邊距
    }
    
    // 選擇模式的店家行視圖
    private func selectingShopRow(index: Int) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                if selectedShops.contains(index) {
                    selectedShops.remove(index)
                } else {
                    selectedShops.insert(index)
                }
            }) {
                Image(systemName: selectedShops.contains(index) ? "checkmark.circle.fill" : "circle")
            }
            Text(dataStore.shops[index].name)
                .font(.title3)
            Spacer()
            Text("\(dataStore.shops[index].menuItems.count) 項商品")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .listRowSeparator(.hidden)
    }
    
    // 正常模式的店家行視圖
    private func normalShopRow(index: Int) -> some View {
        NavigationLink(value: NavigationItem.shop(index: index)) {
            HStack(spacing: 16) {
                Text(dataStore.shops[index].name)
                    .font(.title3)
                Spacer()
                Text("\(dataStore.shops[index].menuItems.count) 項商品")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
        }
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation {
                    dataStore.deleteShop(at: IndexSet(integer: index))
                }
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    // 控制列
                    controlRow
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                    
                    // 店家列表
                    List {
                        ForEach(dataStore.shops.indices, id: \.self) { index in
                            if isSelecting {
                                selectingShopRow(index: index)
                            } else {
                                normalShopRow(index: index)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("店家列表")
                .sheet(isPresented: $isPresentingNewShop) {
                    addNewShopSheet
                }
                .sheet(isPresented: $isPresentingEditShop) {
                    editShopNameSheet
                }
                .navigationDestination(for: NavigationItem.self) { item in
                    switch item {
                    case .shop(let idx):
                        ShopDetailView(shopIndex: idx, path: $path)
                            .environmentObject(dataStore)
                    case .menu(let sIdx, let iIdx):
                        MenuItemEditView(shopIndex: sIdx, itemIndex: iIdx)
                            .environmentObject(dataStore)
                    case .customFoods:
                        EmptyView() // 不再使用自定義食物視圖
                    }
                }
            }
        }
    }
    
    // 新增店家的表單視圖
    private var addNewShopSheet: some View {
        NavigationStack {
            Form {
                TextField("店家名稱", text: $newShopName)
                Button("新增店家") {
                    dataStore.addShop()
                    isPresentingNewShop = false
                    if let idx = dataStore.shops.firstIndex(where: { $0.name == "新店家" }) {
                        dataStore.shops[idx].name = newShopName
                        path.append(.shop(index: idx))
                    }
                    newShopName = ""
                }
                .disabled(newShopName.isEmpty)
            }
            .navigationTitle("新增店家")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Button("取消") {
                            newShopName = ""
                            UIApplication.shared.endEditing()
                        }
                        Spacer()
                        Button("確定") {
                            dataStore.addShop()
                            isPresentingNewShop = false
                            if let idx = dataStore.shops.firstIndex(where: { $0.name == "新店家" }) {
                                dataStore.shops[idx].name = newShopName
                                path.append(.shop(index: idx))
                            }
                            newShopName = ""
                            UIApplication.shared.endEditing()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // 編輯店家名稱的表單視圖
    private var editShopNameSheet: some View {
        Group {
            if let idx = editingShopIndex {
                NavigationStack {
                    Form {
                        TextField("新名稱", text: $editingShopName)
                        Button("儲存") {
                            dataStore.shops[idx].name = editingShopName
                            isPresentingEditShop = false
                        }
                        .disabled(editingShopName.isEmpty)
                    }
                    .navigationTitle("重命名店家")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            HStack {
                                Button("取消") {
                                    editingShopName = ""
                                    isPresentingEditShop = false
                                    UIApplication.shared.endEditing()
                                }
                                Spacer()
                                Button("確定") {
                                    if let idx = editingShopIndex {
                                        dataStore.shops[idx].name = editingShopName
                                    }
                                    isPresentingEditShop = false
                                    UIApplication.shared.endEditing()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

// 店家詳細資訊視圖
struct ShopDetailView: View {
    @EnvironmentObject private var dataStore: DataStore
    let shopIndex: Int
    @Binding var path: [NavigationItem]
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
                                Button("編輯") {
                                    isEditingName = true
                                    shopNameFieldIsFocused = true
                                }
                            }
                        }
                    }

                    // 菜單清單
                    Section(header: Text("菜單列表")) {
                        ForEach(shop.menuItems.indices, id: \.self) { idx in
                            NavigationLink(value: NavigationItem.menu(shopIndex: shopIndex, itemIndex: idx)) {
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

                    // 新增菜單項目
                    Section {
                        Button("新增菜單項目") {
                            dataStore.addMenuItem(to: shopIndex)
                            let newIndex = dataStore.shops[shopIndex].menuItems.count - 1
                            path.append(.menu(shopIndex: shopIndex, itemIndex: newIndex))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationTitle("菜單管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
