import SwiftUI

// MARK: - 成就項目結構體，用於在整個應用中共享
struct AchievementItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let progress: Double // 0.0 到 1.0
    let unlocked: Bool
}

// MARK: - 成就管理器擴展，用於共享成就相關邏輯
extension DataStore {
    // 創建成就列表，供應用各處使用
    func createAchievementsList() -> [AchievementItem] {
        return [
            // 原有成就
            AchievementItem(
                id: "food_decisions_10",
                title: "初級美食家",
                description: "解決50次食物選擇障礙",
                icon: "fork.knife.circle",
                progress: min(Double(self.personalDecisionsMade) / 50.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "food_decisions_10") || self.personalDecisionsMade >= 50
            ),
            AchievementItem(
                id: "food_master",
                title: "美食達人",
                description: "解決100次食物選擇障礙",
                icon: "star.circle.fill",
                progress: min(Double(self.personalDecisionsMade) / 100.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "food_master") || self.personalDecisionsMade >= 100
            ),
            AchievementItem(
                id: "food_decisions_50",
                title: "進階美食家",
                description: "解決500次食物選擇障礙",
                icon: "fork.knife.circle.fill",
                progress: min(Double(self.personalDecisionsMade) / 500.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "food_decisions_50") || self.personalDecisionsMade >= 500
            ),
            AchievementItem(
                id: "food_variety_50",
                title: "多元飲食",
                description: "嘗試50種不同的食物",
                icon: "square.grid.2x2",
                progress: min(Double(self.foodSelections.count) / 50.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "food_variety_50") || self.foodSelections.count >= 50
            ),
            AchievementItem(
                id: "quick_decision",
                title: "果斷決策者",
                description: "連續10次一鍵決定食物",
                icon: "bolt.circle",
                progress: min(Double(self.personalDecisionsMade) / 10.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "quick_decision") || self.personalDecisionsMade >= 10
            ),
            AchievementItem(
                id: "group_decisions_100",
                title: "聚餐組織者",
                description: "解決100次店家選擇障礙",
                icon: "person.3.fill",
                progress: min(Double(self.groupDecisionsMade) / 100.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "group_decisions_100") || self.groupDecisionsMade >= 100
            ),
            AchievementItem(
                id: "balanced_user",
                title: "平衡使用者",
                description: "同時累積500次食物和店家決定",
                icon: "equal.circle.fill",
                progress: min(Double(min(self.personalDecisionsMade, self.groupDecisionsMade)) / 500.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "balanced_user") || (self.personalDecisionsMade >= 500 && self.groupDecisionsMade >= 500)
            ),
            
            // 新增戳按鈕相關成就
            AchievementItem(
                id: "click_100",
                title: "戳戳新手",
                description: "總共戳按鈕100次",
                icon: "hand.point.up.left.fill",
                progress: min(Double(self.personalRandomCount + self.groupRandomCount) / 100.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "click_100") || (self.personalRandomCount + self.groupRandomCount) >= 100
            ),
            AchievementItem(
                id: "click_1000",
                title: "戳戳達人",
                description: "總共戳按鈕1000次",
                icon: "hand.point.up.left.fill",
                progress: min(Double(self.personalRandomCount + self.groupRandomCount) / 1000.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "click_1000") || (self.personalRandomCount + self.groupRandomCount) >= 1000
            ),
            AchievementItem(
                id: "click_master",
                title: "按鈕破壞王",
                description: "總共戳按鈕10000次",
                icon: "hand.tap.fill",
                progress: min(Double(self.personalRandomCount + self.groupRandomCount) / 10000.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "click_master") || (self.personalRandomCount + self.groupRandomCount) >= 10000
            ),
            AchievementItem(
                id: "click_streak_5",
                title: "瘋狂點擊者",
                description: "單次使用中連續點擊100次以上",
                icon: "bolt.horizontal.fill",
                progress: min(Double(max(self.personalRandomCount, self.groupRandomCount)) / 100.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "click_streak_5") || self.personalRandomCount >= 100 || self.groupRandomCount >= 100
            ),
            AchievementItem(
                id: "indecision_king",
                title: "選擇障礙之王",
                description: "單次決策點擊超過500次",
                icon: "arrow.2.squarepath",
                progress: min(Double(max(self.personalRandomCount, self.groupRandomCount)) / 500.0, 1.0),
                unlocked: self.isAchievementUnlocked(id: "indecision_king") || self.personalRandomCount >= 500 || self.groupRandomCount >= 500
            )
        ]
    }
    
    // 檢查是否應解鎖視覺特效
    func shouldUnlockEffects() -> Bool {
        let achievements = createAchievementsList()
        let unlockedCount = achievements.filter { $0.unlocked }.count
        return unlockedCount >= 3
    }
    
    // 檢查和記錄成就的解鎖
    func checkAndRecordAchievements() {
        for achievement in createAchievementsList() {
            if achievement.unlocked && !isAchievementUnlocked(id: achievement.id) {
                unlockAchievement(id: achievement.id)
            }
        }
    }
}

// MARK: - 成就系統視圖 (獨立分類)
struct AchievementView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAchievementDetails = false
    @State private var selectedAchievement: AchievementItem? = nil
    
    // 成就數據
    var achievements: [AchievementItem] {
        return dataStore.createAchievementsList()
    }
    
    // 計算已解鎖成就數
    var unlockedAchievementsCount: Int {
        return achievements.filter { $0.unlocked }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 成就總覽卡片
                StatsCard(title: "成就進度") {
                    VStack(spacing: 15) {
                        // 成就進度總覽
                        HStack {
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 5)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(Double(unlockedAchievementsCount) / Double(achievements.count)))
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack(spacing: 0) {
                                    Text("\(unlockedAchievementsCount)")
                                        .font(.system(size: 24, weight: .bold))
                                    Text("\(achievements.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EatNow!探險進度")
                                    .font(.headline)
                                
                                Text("已解鎖 \(unlockedAchievementsCount)/\(achievements.count) 個成就")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if unlockedAchievementsCount == achievements.count {
                                    Text("恭喜！您已完成所有成就！")
                                        .font(.footnote)
                                        .foregroundColor(.green)
                                        .padding(.top, 2)
                                } else {
                                    Text("繼續解決選擇障礙，達成更多成就！")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                }
                                
                                if dataStore.shouldUnlockEffects() {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("已解鎖視覺特效功能")
                                            .font(.footnote)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            .padding(.leading, 15)
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 點擊相關成就
                StatsCard(title: "點擊成就") {
                    VStack(spacing: 12) {
                        ForEach(achievements.filter { 
                            $0.id.contains("click") || $0.id == "indecision_king" 
                        }) { achievement in
                            AchievementRow(achievement: achievement)
                                .onTapGesture {
                                    self.selectedAchievement = achievement
                                    self.showAchievementDetails = true
                                }
                        }
                    }
                }
                
                // 食物相關成就
                StatsCard(title: "食物相關成就") {
                    VStack(spacing: 12) {
                        ForEach(achievements.filter { $0.id.contains("food") }) { achievement in
                            AchievementRow(achievement: achievement)
                                .onTapGesture {
                                    self.selectedAchievement = achievement
                                    self.showAchievementDetails = true
                                }
                        }
                    }
                }
                
                // 其他成就
                StatsCard(title: "特殊成就") {
                    VStack(spacing: 12) {
                        ForEach(achievements.filter { 
                            !$0.id.contains("food") && 
                            !$0.id.contains("click") && 
                            $0.id != "indecision_king" 
                        }) { achievement in
                            AchievementRow(achievement: achievement)
                                .onTapGesture {
                                    self.selectedAchievement = achievement
                                    self.showAchievementDetails = true
                                }
                        }
                    }
                }
            }
            .padding()
            .sheet(isPresented: $showAchievementDetails) {
                if let achievement = selectedAchievement {
                    AchievementDetailView(achievement: achievement)
                }
            }
            .onAppear {
                dataStore.checkAndRecordAchievements()
            }
        }
    }
}

// MARK: - 成就行視圖
struct AchievementRow: View {
    let achievement: AchievementItem
    
    var body: some View {
        HStack(spacing: 15) {
            // 成就圖標
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? Color.blue : Color(.systemGray5))
                    .frame(width: 40, height: 40)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 18))
                    .foregroundColor(achievement.unlocked ? .white : .gray)
            }
            
            // 成就信息
            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 成就狀態
            VStack(alignment: .trailing, spacing: 3) {
                if achievement.unlocked {
                    Text("已達成")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                } else {
                    Text("\(Int(achievement.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .opacity(achievement.unlocked ? 1 : 0.7)
    }
}

// MARK: - 成就詳細視圖
struct AchievementDetailView: View {
    let achievement: AchievementItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // 圖標區域
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: achievement.unlocked
                                        ? Gradient(colors: [.blue, .purple])
                                        : Gradient(colors: [Color(.systemGray4), Color(.systemGray3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        
                        Image(systemName: achievement.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 30)
                    
                    // 標題和描述
                    VStack(spacing: 10) {
                        Text(achievement.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(achievement.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 進度條
                    VStack(spacing: 8) {
                        HStack {
                            Text("完成進度")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(achievement.progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: geometry.size.width, height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(achievement.progress), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    
                    if achievement.unlocked {
                        Text("恭喜您解鎖了這個成就！")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding(.top, 20)
                        
                        Text("達成至少3個成就即可解鎖特殊功能")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    } else {
                        Text("繼續使用應用以解鎖此成就")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("成就詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
