import SwiftUI
import Foundation

// MARK: - 設定頁面
struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showCSVExport = false
    @State private var showDeleteConfirmation = false
    @State private var showResetStatsConfirmation = false

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

                    Section(header: Text("統計資訊")) {
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
                            NavigationLink("版本 1.1.1") {
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
    
    // 檢查是否解鎖視覺特效
    private func isEffectsUnlocked() -> Bool {
        return dataStore.shouldUnlockEffects()
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
