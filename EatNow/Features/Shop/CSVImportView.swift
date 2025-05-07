import SwiftUI

// CSV匯入視圖
struct CSVImportView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var csvText: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var importSuccess = false
    @State private var isShowingDocumentPicker = false
    @FocusState private var textEditorFocused: Bool
    
    var importOnly: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("CSV格式說明")) {
                    Text("請依照以下格式填寫：店家名稱,品項名稱,價格")
                        .font(.caption)
                    
                    Button("匯入範例資料") {
                        csvText = CSVHandler.getExampleCSV()
                    }
                    .foregroundColor(.blue)
                    
                    Button("從文件匯入") {
                        isShowingDocumentPicker = true
                    }
                    .foregroundColor(.blue)
                }
                
                Section(header: Text("輸入CSV資料")) {
                    TextEditor(text: $csvText)
                        .frame(minHeight: 200)
                        .focused($textEditorFocused)
                }
                
                Section {
                    Button("匯入資料") {
                        importCSVData()
                    }
                    .disabled(csvText.isEmpty)
                }
            }
            .navigationTitle("店家資料匯入")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        importCSVData()
                    }
                    .disabled(csvText.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Button("取消") {
                            // 清空文本框或恢復原始狀態
                            textEditorFocused = false
                            UIApplication.shared.endEditing()
                        }
                        Spacer()
                        Button("確定") {
                            // 如果有需要，在此處理文本輸入完成後的操作
                            textEditorFocused = false
                            UIApplication.shared.endEditing()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .ignoresSafeArea(.keyboard)
            .alert("錯誤", isPresented: $showError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("匯入成功", isPresented: $importSuccess) {
                Button("確定") { dismiss() }
            } message: {
                Text("店家資料已成功匯入")
            }
            .sheet(isPresented: $isShowingDocumentPicker) {
                DocumentPicker { url in
                    importCSVFromFile(url: url)
                }
            }
        }
    }
    
    // 從檔案匯入CSV
    private func importCSVFromFile(url: URL) {
        let result = CSVHandler.loadCSVFromFile(url: url)
        
        switch result {
        case .success(let shops):
            dataStore.shops.append(contentsOf: shops)
            importSuccess = true
        case .failure(let error):
            errorMessage = error.errorDescription ?? "匯入失敗"
            showError = true
        }
    }
    
    // 從文本框匯入CSV
    private func importCSVData() {
        let result = CSVHandler.parseCSV(text: csvText)
        
        switch result {
        case .success(let shops):
            dataStore.shops.append(contentsOf: shops)
            importSuccess = true
        case .failure(let error):
            errorMessage = error.errorDescription ?? "匯入失敗"
            showError = true
        }
    }
}

// 文件選擇器
struct DocumentPicker: UIViewControllerRepresentable {
    var callback: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .commaSeparatedText, .plainText], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.callback(url)
        }
    }
}

// 分享表單
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}