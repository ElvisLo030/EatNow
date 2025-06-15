import SwiftUI
import Foundation

// MARK: - DateFormatter 擴展
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - 設定頁面
struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showCSVExport = false
    @State private var showDeleteConfirmation = false
    @State private var showResetStatsConfirmation = false
    @State private var showCopySuccess = false
    @State private var apiRetrySuccess = false
    @State private var isCheckingConnection = false
    @State private var isValidatingUserID = false
    @State private var connectionStatus: String = "未知"
    @State private var validationResult: String = ""
    @State private var isUserIDValid: Bool? = nil // 新增：跟踪用戶ID驗證狀態

    var body: some View {
        NavigationView {
            ZStack {
                Color.clear.onTapGesture { UIApplication.shared.endEditing() }
                Form {
                    Section(header: Text("個人檔案")) {
                        TextField("使用者名稱", text: $dataStore.userName)
                    }

                    Section(header: Text("顯示設定")) {
                        Toggle("啟用視覺特效", isOn: $dataStore.effectsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .disabled(!isEffectsUnlocked())
                        
                        if !isEffectsUnlocked() {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                Text("達成至少3個成就以解鎖視覺特效")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }

                    Section(header: Text("資料管理")) {
                        Button("匯出店家資料") {
                            showCSVExport = true
                        }
                        .foregroundColor(.blue)

                        Button("重置統計資料") {
                            showResetStatsConfirmation = true
                        }
                        .foregroundColor(.orange)
                        .alert("確認重置", isPresented: $showResetStatsConfirmation) {
                            Button("取消", role: .cancel) { }
                            Button("確認重置", role: .destructive) {
                                dataStore.resetStats()
                            }
                        } message: {
                            Text("此操作將重置所有統計資料，且無法恢復。確定要繼續嗎？\n\n重置統計資料不會重置成就。")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Text("清除所有店家資料")
                        }
                        .alert("確認刪除", isPresented: $showDeleteConfirmation) {
                            Button("取消", role: .cancel) { }
                            Button("確認刪除", role: .destructive) {
                                dataStore.clearShopsData()
                            }
                        } message: {
                            Text("此操作將刪除所有店家和菜單資料，但會保留您的統計數據和個人設定。確定要繼續嗎？")
                        }
                    }

                    Section(header: Text("關於")) {

                        HStack {
                            Image(systemName: "envelope")
                            Text("help@elvislo.tw")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    if let url = URL(string: "mailto:help@elvislo.tw") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                        }

                        HStack {
                            Image(systemName: "text.document.fill")
                            Link("GitHub", destination: URL(string: "https://github.com/ElvisLo030/EatNow")!)
                        }
                        
                        HStack {
                            Image(systemName: "book.circle")
                            NavigationLink("LICENSE") {
                                LicenseView()
                            }
                        }
                        HStack {
                            Image(systemName: "info.circle")
                            NavigationLink("版本 1.1.2") {
                                UpdateHistoryView()
                            }
                        }
                    }
                    
                    // 使用者編號區塊
                    Section(header: Text("使用者編號")) {
                        if dataStore.userID.isEmpty {
                            if dataStore.userName.isEmpty {
                                HStack {
                                    Image(systemName: "person.badge.key")
                                        .foregroundColor(.gray)
                                    Text("請先輸入使用者名稱以獲得專屬編號")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            } else {
                                // 有名稱但沒有編號的情況
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                        Text("編號生成失敗")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    
                                    Button(action: {
                                        // 重新生成編號
                                        dataStore.userID = ""
                                        dataStore.userCreatedDate = nil
                                        let _ = dataStore.generateUserID()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                            Text("重新獲取編號")
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "person.badge.key")
                                    .foregroundColor(.blue)
                                Text("編號")
                                Spacer()
                                Text(dataStore.userID)
                                    .font(.monospaced(.body)())
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    UIPasteboard.general.string = dataStore.userID
                                    showCopySuccess = true
                                    // 添加觸感回饋
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            
                            if let createdDate = dataStore.userCreatedDate {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.green)
                                    Text("建立日期")
                                    Spacer()
                                    Text(DateFormatter.shortDate.string(from: createdDate))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // API重新同步按鈕 - 只在驗證失敗或尚未驗證時顯示
                            if isUserIDValid == false {
                                Button(action: {
                                    dataStore.retryUserIDRegistration()
                                    apiRetrySuccess = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .foregroundColor(.orange)
                                        Text("重新同步到伺服器")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            
                            // 驗證用戶ID按鈕
                            Button(action: {
                                validateUserID()
                            }) {
                                HStack {
                                    if isValidatingUserID {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "checkmark.shield")
                                            .foregroundColor(.green)
                                    }
                                    Text("驗證編號有效性")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .disabled(isValidatingUserID)
                            
                            if !validationResult.isEmpty {
                                HStack {
                                    Image(systemName: validationResult.contains("有效") ? "checkmark.circle" : "xmark.circle")
                                        .foregroundColor(validationResult.contains("有效") ? .green : .red)
                                    Text(validationResult)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // API 連線狀態區塊
                    Section(header: Text("伺服器狀態")) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                            Text("連線狀態")
                            Spacer()
                            Text(connectionStatus)
                                .foregroundColor(getConnectionStatusColor())
                        }
                        
                        Button(action: {
                            checkAPIConnection()
                        }) {
                            HStack {
                                if isCheckingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.blue)
                                }
                                Text("檢查連線")
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(isCheckingConnection)
                    }
                    
                    // 添加 Buy Me A Coffee 按鈕區塊
                    Section {
                        Link(destination: URL(string: "https://www.buymeacoffee.com/elvislo030")!) {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .font(.title)
                                        .foregroundColor(.yellow)
                                    
                                    Text("Buy Me A Coffee")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("支持開發者持續改進 EatNow")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.yellow, lineWidth: 2)
                                    )
                            )
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .navigationTitle("設定")
                .sheet(isPresented: $showCSVExport) {
                    CSVExportView()
                        .environmentObject(dataStore)
                }
                .alert("複製成功", isPresented: $showCopySuccess) {
                    Button("確定", role: .cancel) { }
                } message: {
                    Text("使用者編號已複製到剪貼簿")
                }
                .alert("同步成功", isPresented: $apiRetrySuccess) {
                    Button("確定", role: .cancel) { }
                } message: {
                    Text("使用者資料已重新同步到伺服器")
                }
            }
        }
    }
    
    // 檢查是否解鎖視覺特效
    private func isEffectsUnlocked() -> Bool {
        return dataStore.shouldUnlockEffects()
    }
    
    // 檢查 API 連線狀態
    private func checkAPIConnection() {
        isCheckingConnection = true
        connectionStatus = "檢查中..."
        
        Task {
            let isConnected = await dataStore.checkAPIConnection()
            
            DispatchQueue.main.async {
                self.isCheckingConnection = false
                self.connectionStatus = isConnected ? "已連線" : "離線"
            }
        }
    }
    
    // 驗證用戶ID
    private func validateUserID() {
        guard !dataStore.userID.isEmpty else {
            validationResult = "無用戶編號"
            isUserIDValid = false
            return
        }
        
        isValidatingUserID = true
        validationResult = ""
        
        Task {
            let isValid = await dataStore.validateUserID()
            
            DispatchQueue.main.async {
                self.isValidatingUserID = false
                self.isUserIDValid = isValid
                self.validationResult = isValid ? "編號有效且已註冊" : "編號無效或未註冊"
            }
        }
    }
    
    // 獲取連線狀態顏色
    private func getConnectionStatusColor() -> Color {
        switch connectionStatus {
        case "已連線":
            return .green
        case "離線":
            return .red
        case "檢查中...":
            return .orange
        default:
            return .gray
        }
    }
}

// 為Settings模塊創建一個獨立的Achievement結構體，以避免命名衝突
struct StatsAchievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let progress: Double
    let unlocked: Bool
    let reward: String
}

// MARK: - 更新歷史頁面
struct UpdateHistoryView: View {
    @State private var versionReleases: [VersionRelease] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("正在從 GitHub 獲取更新資訊...")
                    .padding()
            } else if let error = error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("無法連接到 GitHub")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("重試") {
                        loadCommits()
                    }
                    .padding()
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                List {
                    ForEach(versionReleases) { release in
                        Section(header: Text("Commit \(release.commitHash)")
                                 .font(.headline)
                                 .foregroundColor(.primary)) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("\(release.formattedDate)發布")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if !release.version.isEmpty {
                                        Text("版本: \(release.version)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Link(destination: URL(string: release.commitUrl)!) {
                                        HStack(spacing: 2) {
                                            Text("前往GitHub")
                                            Image(systemName: "arrow.up.right.square")
                                        }
                                        .font(.caption)
                                    }
                                    .buttonStyle(BorderlessButtonStyle()) // 確保按鈕不影響其他按鈕的觸發
                                }
                                
                                // 使用可展開的 commit 訊息
                                ExpandableCommitMessage(message: release.fullMessage)
                                    
                                Divider()
                                
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("更新歷史")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if versionReleases.isEmpty {
                loadCommits()
            }
        }
    }
    
    private func loadCommits() {
        isLoading = true
        GitHubService.shared.fetchCommits { commits, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    // 加載失敗時使用默認資料（好像怪怪的，就不顯示了）
                    //self.versionReleases = GitHubService.shared.defaultVersionReleases()
                    return
                }
                
                if let commits = commits {
                    self.versionReleases = GitHubService.shared.getVersionReleases(from: commits)
                }
            }
        }
    }
}

// 新增一個可展開的 commit 訊息組件
struct ExpandableCommitMessage: View {
    let message: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.spring(), value: isExpanded)
            
            if message.count > 150 { // 只有當文字較長時才顯示按鈕
                Button(action: {
                    isExpanded.toggle()
                }) {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                        Text(isExpanded ? "收起內容" : "展開完整內容")
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
                    .foregroundColor(.primary)
                }
                .buttonStyle(BorderlessButtonStyle()) // 防止按鈕事件傳播
                .padding(.bottom, 4)
            }
        }
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
