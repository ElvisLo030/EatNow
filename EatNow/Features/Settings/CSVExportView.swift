import SwiftUI

// CSV匯出視圖
struct CSVExportView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("匯出功能說明")) {
                    Text("此功能將匯出所有店家資料為CSV檔案，可以備份或轉移至其他裝置使用。")
                        .font(.caption)
                }
                
                Section {
                    Button("匯出為CSV") {
                        exportCurrentData()
                    }
                    .foregroundColor(.blue)
                }
                
                Section(header: Text("CSV資料格式")) {
                    Text("匯出的CSV檔案格式為：店家名稱,品項名稱,價格")
                        .font(.caption)
                }
            }
            .navigationTitle("店家資料匯出")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("錯誤", isPresented: $showError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // 匯出目前資料
    private func exportCurrentData() {
        let csvContent = CSVHandler.exportToCSV(shops: dataStore.shops)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "EatNow_Shops_\(dateString).csv"
        
        let result = CSVHandler.saveCSVToFile(csv: csvContent, filename: filename)
        
        switch result {
        case .success(let fileURL):
            exportedFileURL = fileURL
            showShareSheet = true
        case .failure(let error):
            errorMessage = error.errorDescription ?? "匯出失敗"
            showError = true
        }
    }
}