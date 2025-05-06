import SwiftUI

// MARK: - 設定頁面
struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showCSVImport = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear.onTapGesture { UIApplication.shared.endEditing() }
                Form {
                    Section(header: Text("使用者檔案")) {
                        TextField("使用者名稱", text: $dataStore.userName)
                    }
                    
                    Section(header: Text("資料管理")) {
                        Button("匯入/匯出店家資料") {
                            showCSVImport = true
                        }
                        .foregroundColor(.blue)
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Text("清除所有資料")
                        }
                        .alert("確認刪除", isPresented: $showDeleteConfirmation) {
                            Button("取消", role: .cancel) { }
                            Button("確認刪除", role: .destructive) {
                                dataStore.clearAllData()
                            }
                        } message: {
                            Text("此操作將刪除所有資料，且無法恢復。確定要繼續嗎？")
                        }
                    }
                    
                    Section(header: Text("統計資訊")) {
                        Button("重置統計資料") {
                            dataStore.resetStats()
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Section(header: Text("聯絡支援")) {
                        if let email = URL(string: "mailto:elvislo.work@gmail.com") {
                            Link("elvislo.work@gmail.com", destination: email)
                        } else {
                            Text("elvislo.work@gmail.com")
                        }
                    }
                    
                    Section(header: Text("關於")) {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showCSVImport) {
                CSVImportView()
                    .environmentObject(dataStore)
            }
        }
    }
} 
