import SwiftUI

// MARK: - 設定頁面
struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showCSVExport = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.clear.onTapGesture { UIApplication.shared.endEditing() }
                Form {
                    Section(header: Text("個人檔案")) {
                        TextField("使用者名稱", text: $dataStore.userName)
                    }

                    Section(header: Text("資料管理")) {
                        Button("匯出店家資料") {
                            showCSVExport = true
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
                            showDeleteConfirmation = true
                        }
                        .foregroundColor(.orange)
                        .alert("確認重置", isPresented: $showDeleteConfirmation) {
                            Button("取消", role: .cancel) { }
                            Button("確認重置", role: .destructive) {
                                dataStore.resetStats()
                            }
                        } message: {
                            Text("此操作將重置所有統計資料，且無法恢復。確定要繼續嗎？")
                        }
                    }

                    Section(header: Text("關於")) {

                        HStack {
                            Image(systemName: "envelope")
                            Text("elvislo.work@gmail.com")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    if let url = URL(string: "mailto:elvislo.work@gmail.com") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                        }

                        HStack {
                            Image(systemName: "text.document.fill")
                            Link("原始碼", destination: URL(string: "https://github.com/ElvisLo030/EatNow")!)
                        }
                        
                        HStack {
                            Image(systemName: "book.circle")
                            NavigationLink("GNU GPL v3") {
                                LicenseView()
                            }
                        }
                        HStack {
                            Image(systemName: "info.circle")
                            NavigationLink("版本 1.1") {
                                UpdateHistoryView()
                            }
                        }
                    }
                }
                .navigationTitle("設定")
                .sheet(isPresented: $showCSVExport) {
                    CSVExportView()
                        .environmentObject(dataStore)
                }
            }
        }
    }
}

// MARK: - 更新歷史頁面
struct UpdateHistoryView: View {
    var body: some View {
        List {
            Section(header: Text("版本 1.1").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("2025年5月7日發布")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()

                    Text("新增功能：")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Group {
                        BulletPoint(text: "新增版本說明、License")
                    }
                    
                    Text("修改和優化：")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    
                    Group {
                        BulletPoint(text: "修改部分文本")
                        BulletPoint(text: "優化資料匯入和匯出功能")
                        BulletPoint(text: "優化使用者介面，提升操作流暢度")
                        BulletPoint(text: "優化CSV範本")
                    }
                }
                .padding(.vertical, 6)
            }
            
            Section(header: Text("版本 1.0").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("2025年5月6日發布")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("首次發布功能：")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Group {
                        BulletPoint(text: "食物和店家隨機推薦功能")
                        BulletPoint(text: "CSV 資料匯入匯出")
                        BulletPoint(text: "基本使用統計")
                        BulletPoint(text: "使用者自定義設定")
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("更新歷史")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 用於顯示帶有項目符號的文字行
struct BulletPoint: View {
    var text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.system(size: 12))
                .padding(.top, 3)
            Text(text)
                .padding(.leading, 2)
        }
        .padding(.vertical, 1)
    }
}