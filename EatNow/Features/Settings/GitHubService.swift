import Foundation

// MARK: - GitHub API 模型
struct GitHubCommit: Codable, Identifiable {
    let sha: String
    let commit: CommitDetails
    let html_url: String
    
    var id: String { sha }
    
    struct CommitDetails: Codable {
        let message: String
        let committer: Committer
    }
    
    struct Committer: Codable {
        let name: String
        let email: String
        let date: String
    }
}

// MARK: - 版本資訊模型
struct VersionRelease: Identifiable {
    let id = UUID()
    let version: String
    let commitHash: String
    let commitUrl: String
    let releaseDate: Date
    let newFeatures: [String]
    let improvements: [String]
    let fullMessage: String // 完整的 commit 訊息
    
    // 為顯示準備的日期字串
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: releaseDate)
    }
    
    // 將 commit message 分析成版本資訊
    static func parseFromCommit(_ commit: GitHubCommit) -> VersionRelease? {
        // 保存完整的 commit 訊息
        let fullMessage = commit.commit.message
        
        // 嘗試提取版本號
        let versionPattern = #"v?(\d+\.\d+(\.\d+)?)"#
        let versionMatch = fullMessage.range(of: versionPattern, options: .regularExpression)
        
        // 如果沒有找到版本號，直接使用短哈希作為版本
        let version = versionMatch != nil ? 
            String(fullMessage[versionMatch!]).replacingOccurrences(of: "v", with: "") : 
            ""
        
        // 處理日期
        let dateFormatter = ISO8601DateFormatter()
        let releaseDate = dateFormatter.date(from: commit.commit.committer.date) ?? Date()
        
        // 從 message 提取功能和優化
        var newFeatures: [String] = []
        var improvements: [String] = []
        
        // 簡單的解析邏輯
        let lines = fullMessage.split(separator: "\n")
        var currentSection = ""
        
        for line in lines.dropFirst() { // 跳過第一行(通常是標題)
            let lineStr = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if lineStr.isEmpty { continue }
            
            if lineStr.contains("新功能") || lineStr.contains("新增") {
                currentSection = "features"
                continue
            } else if lineStr.contains("修改") || lineStr.contains("優化") || lineStr.contains("修復") {
                currentSection = "improvements"
                continue
            }
            
            if !lineStr.isEmpty {
                if lineStr.hasPrefix("-") || lineStr.hasPrefix("*") {
                    let item = lineStr.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                    if currentSection == "features" {
                        newFeatures.append(item)
                    } else if currentSection == "improvements" {
                        improvements.append(item)
                    }
                }
            }
        }
        
        return VersionRelease(
            version: version,
            commitHash: String(commit.sha.prefix(7)),
            commitUrl: commit.html_url,
            releaseDate: releaseDate,
            newFeatures: newFeatures,
            improvements: improvements,
            fullMessage: fullMessage
        )
    }
}

// MARK: - GitHub 服務
class GitHubService {
    static let shared = GitHubService()
    
    private let owner = "ElvisLo030"
    private let repo = "EatNow"
    private let baseURL = "https://api.github.com"
    
    private init() {}
    
    // 獲取所有 commits
    func fetchCommits(completion: @escaping ([GitHubCommit]?, Error?) -> Void) {
        let urlString = "\(baseURL)/repos/\(owner)/\(repo)/commits"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "GitHubService", code: 400, userInfo: [NSLocalizedDescriptionKey: "無效的 URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "GitHubService", code: 500, userInfo: [NSLocalizedDescriptionKey: "沒有收到數據"]))
                return
            }
            
            do {
                let commits = try JSONDecoder().decode([GitHubCommit].self, from: data)
                completion(commits, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    // 將 commits 轉換為版本發布資訊
    func getVersionReleases(from commits: [GitHubCommit]) -> [VersionRelease] {
        var releases: [VersionRelease] = []
        
        for commit in commits {
            if let release = VersionRelease.parseFromCommit(commit) {
                releases.append(release)
            }
        }
        
        // 回退機制：如果解析失敗，提供默認數據
        if releases.isEmpty {
            releases = defaultVersionReleases()
        }
        
        return releases.sorted { $0.releaseDate > $1.releaseDate }
    }
    
    // 默認版本資訊 (公開方法)
    func defaultVersionReleases() -> [VersionRelease] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return [
            VersionRelease(
                version: "1.1.2",
                commitHash: "b742dfc",
                commitUrl: "https://github.com/ElvisLo030/EatNow/commit/b742dfc",
                releaseDate: dateFormatter.date(from: "2025-05-09") ?? Date(),
                newFeatures: [],
                improvements: ["修正部分文本", "修正成就系統的計算問題"],
                fullMessage: "Commit b742dfc: 版本 1.1.2 更新\n\n修改:\n- 修正部分文本\n- 修正成就系統的計算問題"
            ),
        ]
    }
}