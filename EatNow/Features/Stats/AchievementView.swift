import SwiftUI

// MARK: - 成就系統視圖 (獨立分類)
struct AchievementView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAchievementDetails = false
    @State private var selectedAchievement: Achievement? = nil
    
    // 成就數據
    var achievements: [Achievement] {
        return [
            // 原有成就
            Achievement(
                id: "food_decisions_10",
                title: "初級美食家",
                description: "解決10次食物選擇障礙",
                icon: "fork.knife.circle",
                progress: min(Double(dataStore.personalDecisionsMade) / 10.0, 1.0),
                unlocked: dataStore.personalDecisionsMade >= 10,
                reward: "解鎖更多統計數據"
            ),
            Achievement(
                id: "food_decisions_50",
                title: "進階美食家",
                description: "解決50次食物選擇障礙",
                icon: "fork.knife.circle.fill",
                progress: min(Double(dataStore.personalDecisionsMade) / 50.0, 1.0),
                unlocked: dataStore.personalDecisionsMade >= 50,
                reward: "專屬美食家頭銜"
            ),
            Achievement(
                id: "food_variety_5",
                title: "多元飲食",
                description: "嘗試5種不同的食物",
                icon: "square.grid.2x2",
                progress: min(Double(dataStore.foodSelections.count) / 5.0, 1.0),
                unlocked: dataStore.foodSelections.count >= 5,
                reward: "解鎖食物圖表"
            ),
            Achievement(
                id: "quick_decision",
                title: "果斷決策者",
                description: "連續5次一鍵決定食物",
                icon: "bolt.circle",
                progress: min(Double(dataStore.personalDecisionsMade) / 5.0, 1.0),
                unlocked: dataStore.personalDecisionsMade >= 5,
                reward: "提升隨機推薦權重"
            ),
            Achievement(
                id: "food_master",
                title: "美食達人",
                description: "解決100次食物選擇障礙",
                icon: "star.circle.fill",
                progress: min(Double(dataStore.personalDecisionsMade) / 100.0, 1.0),
                unlocked: dataStore.personalDecisionsMade >= 100,
                reward: "專屬金色主題"
            ),
            Achievement(
                id: "group_decisions_10",
                title: "初級聚餐組織者",
                description: "解決10次店家選擇障礙",
                icon: "person.3.fill",
                progress: min(Double(dataStore.groupDecisionsMade) / 10.0, 1.0),
                unlocked: dataStore.groupDecisionsMade >= 10,
                reward: "聚餐組織者徽章"
            ),
            Achievement(
                id: "balanced_user",
                title: "平衡使用者",
                description: "同時累積10次食物和店家決定",
                icon: "equal.circle.fill",
                progress: min(Double(min(dataStore.personalDecisionsMade, dataStore.groupDecisionsMade)) / 10.0, 1.0),
                unlocked: dataStore.personalDecisionsMade >= 10 && dataStore.groupDecisionsMade >= 10,
                reward: "特殊使用者界面主題"
            ),
            
            // 新增戳按鈕相關成就
            Achievement(
                id: "click_50",
                title: "戳戳新手",
                description: "總共戳按鈕50次",
                icon: "hand.point.up.left.fill",
                progress: min(Double(dataStore.personalRandomCount + dataStore.groupRandomCount) / 50.0, 1.0),
                unlocked: (dataStore.personalRandomCount + dataStore.groupRandomCount) >= 50,
                reward: "特殊點擊音效"
            ),
            Achievement(
                id: "click_100",
                title: "戳戳達人",
                description: "總共戳按鈕500次",
                icon: "hand.point.up.left.fill",
                progress: min(Double(dataStore.personalRandomCount + dataStore.groupRandomCount) / 500.0, 1.0),
                unlocked: (dataStore.personalRandomCount + dataStore.groupRandomCount) >= 500,
                reward: "獨特按鈕動畫效果"
            ),
            Achievement(
                id: "click_ratio_high",
                title: "高效決策者",
                description: "點擊決定比率達到50%以上",
                icon: "gauge.high",
                progress: dataStore.personalRandomCount + dataStore.groupRandomCount > 0 ? 
                    min(Double(dataStore.totalDecisionsMade) / Double(dataStore.personalRandomCount + dataStore.groupRandomCount) * 2, 1.0) : 0.0,
                unlocked: dataStore.personalRandomCount + dataStore.groupRandomCount >= 10 && 
                    Double(dataStore.totalDecisionsMade) / Double(dataStore.personalRandomCount + dataStore.groupRandomCount) >= 0.5,
                reward: "解鎖高效率使用者徽章"
            ),
            Achievement(
                id: "click_streak_5",
                title: "瘋狂點擊者",
                description: "單次使用中連續點擊10次以上",
                icon: "bolt.horizontal.fill",
                progress: min(Double(max(dataStore.personalRandomCount, dataStore.groupRandomCount)) / 10.0, 1.0),
                unlocked: dataStore.personalRandomCount >= 10 || dataStore.groupRandomCount >= 10,
                reward: "獲得點擊特效"
            ),
            Achievement(
                id: "click_master",
                title: "按鈕破壞王",
                description: "總共戳按鈕1000次",
                icon: "hand.tap.fill",
                progress: min(Double(dataStore.personalRandomCount + dataStore.groupRandomCount) / 500.0, 1.0),
                unlocked: (dataStore.personalRandomCount + dataStore.groupRandomCount) >= 1000,
                reward: "特殊個人主題定制"
            ),
            Achievement(
                id: "indecision_king",
                title: "選擇障礙之王",
                description: "單次決策點擊超過10次",
                icon: "arrow.2.squarepath",
                progress: min(Double(max(dataStore.personalRandomCount, dataStore.groupRandomCount)) / 10.0, 1.0),
                unlocked: dataStore.personalRandomCount >= 10 || dataStore.groupRandomCount >= 10,
                reward: "飢餓模式特別提示"
            )
        ]
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
                                Text("美食探險進度")
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
                                    Text("再接再厲，繼續探索！")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
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
                StatsCard(title: "戳按鈕成就") {
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
                StatsCard(title: "團體和特殊成就") {
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
        }
    }
}

// MARK: - 成就模型
struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let progress: Double // 0.0 到 1.0
    let unlocked: Bool
    let reward: String
}

// MARK: - 成就行視圖
struct AchievementRow: View {
    let achievement: Achievement
    
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
                    Text("已解鎖")
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
    let achievement: Achievement
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
                    
                    // 獎勵
                    VStack(spacing: 8) {
                        Text("獎勵")
                            .font(.headline)
                        
                        Text(achievement.reward)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(achievement.unlocked ? .primary : .secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    if achievement.unlocked {
                        Text("恭喜您解鎖了這個成就！")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding(.top, 20)
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
