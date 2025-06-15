import SwiftUI

// 雲端菜單上傳視圖
struct CloudMenuUploadView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedShops: Set<Int> = []
    @State private var isUploading = false
    @State private var uploadResult: (successCount: Int, totalCount: Int)? = nil
    @State private var showResult = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 說明區塊
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cloud.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("雲端菜單上傳")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("選擇要上傳到雲端伺服器的店家菜單。上傳的資料包含：")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            BulletText("使用者編號")
                            BulletText("店家名稱")
                            BulletText("品項名稱與價格")
                            BulletText("上傳日期")
                            BulletText("店家資料編號（6位數，系統自動產生）")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        if dataStore.userID.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("請先在設定頁面輸入使用者名稱以獲得專屬編號")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding()
                    
                    // 店家選擇列表
                    List {
                        ForEach(dataStore.shops.indices, id: \.self) { index in
                            ShopUploadRow(
                                shop: dataStore.shops[index],
                                isSelected: selectedShops.contains(index),
                                onToggle: {
                                    if selectedShops.contains(index) {
                                        selectedShops.remove(index)
                                    } else {
                                        selectedShops.insert(index)
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("雲端上傳")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        uploadSelectedMenus()
                    }) {
                        HStack(spacing: 4) {
                            if isUploading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "cloud.fill")
                            }
                            Text("上傳")
                        }
                    }
                    .disabled(selectedShops.isEmpty || isUploading || dataStore.userID.isEmpty)
                }
            }
            .alert("上傳完成", isPresented: $showResult) {
                Button("確定") {
                    dismiss()
                }
            } message: {
                if let result = uploadResult {
                    Text("成功上傳 \(result.successCount) / \(result.totalCount) 個店家菜單")
                }
            }
        }
    }
    
    // 上傳選中的菜單
    private func uploadSelectedMenus() {
        guard !selectedShops.isEmpty, !dataStore.userID.isEmpty else { return }
        
        isUploading = true
        let shopIndices = Array(selectedShops)
        
        Task { @MainActor in
            let result = await dataStore.batchUploadMenusToCloud(shopIndices: shopIndices)
            
            self.isUploading = false
            self.uploadResult = result
            self.showResult = true
        }
    }
}

// 店家上傳行視圖
struct ShopUploadRow: View {
    let shop: Shop
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(shop.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    cloudStatusIcon(for: shop.cloudStatus)
                }
                
                HStack {
                    Text("\(shop.menuItems.count) 項商品")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(cloudStatusText(for: shop.cloudStatus))
                        .font(.caption)
                        .foregroundColor(cloudStatusColor(for: shop.cloudStatus))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func cloudStatusIcon(for status: CloudSyncStatus) -> some View {
        switch status {
        case .notSynced:
            Image(systemName: "cloud")
                .foregroundColor(.gray)
                .font(.caption)
        case .synced:
            Image(systemName: "cloud.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .modified:
            Image(systemName: "cloud.fill")
                .foregroundColor(.orange)
                .font(.caption)
                .overlay(
                    Image(systemName: "exclamationmark")
                        .foregroundColor(.white)
                        .font(.system(size: 6, weight: .bold))
                        .offset(x: 1, y: -1)
                )
        case .uploading:
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 12, height: 12)
        case .failed:
            Image(systemName: "cloud.fill")
                .foregroundColor(.red)
                .font(.caption)
                .overlay(
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 5, weight: .bold))
                        .offset(x: 1, y: -1)
                )
        }
    }
    
    private func cloudStatusText(for status: CloudSyncStatus) -> String {
        switch status {
        case .notSynced:
            return "未上傳"
        case .synced:
            return "已同步"
        case .modified:
            return "已修改"
        case .uploading:
            return "上傳中..."
        case .failed:
            return "上傳失敗"
        }
    }
    
    private func cloudStatusColor(for status: CloudSyncStatus) -> Color {
        switch status {
        case .notSynced:
            return .gray
        case .synced:
            return .green
        case .modified:
            return .orange
        case .uploading:
            return .blue
        case .failed:
            return .red
        }
    }
}

// 項目符號文字
struct BulletText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.caption)
            Text(text)
                .font(.caption)
        }
    }
}
