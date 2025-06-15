import Foundation
import SwiftUI

// MARK: - API數據模型

// 健康檢查回應
struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let version: String
}

// 用戶創建請求
struct UserCreationRequest: Codable {
    let name: String
    let userID: String
    let createdDate: String
}

// 通用API回應格式
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let timestamp: String?
}

// 用戶創建回應數據
struct UserCreationData: Codable {
    let userID: String
    let name: String
    let createdDate: String
    let registered: Bool
}

// 用戶ID生成回應數據
struct UserIDGenerationData: Codable {
    let userID: String
    let createdAt: String
    let message: String
}

// 用戶ID驗證回應數據
struct UserIDValidationData: Codable {
    let isValid: Bool
    let userID: String
    let exists: Bool
}

// 用戶同步請求
struct UserSyncRequest: Codable {
    let userID: String
    let userName: String
    let lastActiveAt: String
}

// 用戶同步回應數據
struct UserSyncData: Codable {
    let userID: String
    let syncedAt: String
    let message: String
}

// 用戶更新請求
struct UserUpdateRequest: Codable {
    let name: String
    let lastUpdatedAt: String
}

// 用戶更新回應數據
struct UserUpdateData: Codable {
    let userID: String
    let name: String
    let updatedAt: String
}

// MARK: - API服務管理類
class APIService: ObservableObject {
    static let shared = APIService()
    
    // 配置
    private let baseURL = "http://localhost:8000"
    private let timeoutInterval: TimeInterval = 30.0
    
    // URLSession配置
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        return URLSession(configuration: config)
    }()
    
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    private init() {}
    
    // MARK: - API端點方法
    
    /// 1. 健康檢查
    func checkHealth() async -> HealthResponse? {
        return await performGETRequest(endpoint: "/health")
    }
    
    /// 2. 創建用戶
    func createUser(name: String, userID: String, createdDate: Date) async -> APIResponse<UserCreationData>? {
        let request = UserCreationRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            userID: userID,
            createdDate: dateFormatter.string(from: createdDate)
        )
        
        return await performPOSTRequest(endpoint: "/users", body: request)
    }
    
    /// 3. 生成使用者編號
    func generateUserID() async -> APIResponse<UserIDGenerationData>? {
        return await performPOSTRequest(endpoint: "/api/user/id/generate", body: EmptyBody())
    }
    
    /// 4. 驗證使用者編號
    func validateUserID(_ userID: String) async -> APIResponse<UserIDValidationData>? {
        return await performGETRequest(endpoint: "/api/user/id/validate/\(userID)")
    }
    
    /// 5. 同步使用者資料
    func syncUserData(userID: String, userName: String) async -> APIResponse<UserSyncData>? {
        let request = UserSyncRequest(
            userID: userID,
            userName: userName,
            lastActiveAt: dateFormatter.string(from: Date())
        )
        
        return await performPOSTRequest(endpoint: "/api/user/sync", body: request)
    }
    
    /// 6. 更新用戶名稱
    func updateUserName(userID: String, newName: String) async -> APIResponse<UserUpdateData>? {
        let request = UserUpdateRequest(
            name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastUpdatedAt: dateFormatter.string(from: Date())
        )
        
        return await performPUTRequest(endpoint: "/users/\(userID)", body: request)
    }
    
    // MARK: - 通用請求方法
    
    private func performGETRequest<T: Codable>(endpoint: String) async -> T? {
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ 無效的URL: \(baseURL + endpoint)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("EatNow-iOS/\(getAppVersion())", forHTTPHeaderField: "User-Agent")
        
        return await executeRequest(request: request)
    }
    
    private func performPOSTRequest<RequestBody: Codable, ResponseType: Codable>(
        endpoint: String,
        body: RequestBody
    ) async -> ResponseType? {
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ 無效的URL: \(baseURL + endpoint)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("EatNow-iOS/\(getAppVersion())", forHTTPHeaderField: "User-Agent")
        
        // 編碼請求體
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            print("❌ 編碼請求失敗: \(error)")
            return nil
        }
        
        return await executeRequest(request: request)
    }
    
    private func performPUTRequest<RequestBody: Codable, ResponseType: Codable>(
        endpoint: String,
        body: RequestBody
    ) async -> ResponseType? {
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ 無效的URL: \(baseURL + endpoint)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("EatNow-iOS/\(getAppVersion())", forHTTPHeaderField: "User-Agent")
        
        // 編碼請求體
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            print("❌ 編碼請求失敗: \(error)")
            return nil
        }
        
        return await executeRequest(request: request)
    }
    
    private func executeRequest<T: Codable>(request: URLRequest) async -> T? {
        do {
            let (data, response) = try await session.data(for: request)
            
            // 檢查HTTP狀態碼
            if let httpResponse = response as? HTTPURLResponse {
                let endpoint = request.url?.path ?? "unknown"
                let method = request.httpMethod ?? "unknown"
                print("📡 API請求: \(method) \(endpoint) - 狀態碼: \(httpResponse.statusCode)")
                
                // 打印回應數據（調試用）
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 回應數據: \(responseString)")
                }
                
                if httpResponse.statusCode >= 400 {
                    print("❌ HTTP錯誤: \(httpResponse.statusCode)")
                    
                    // 嘗試解析錯誤回應
                    if let errorResponse = try? JSONDecoder().decode(APIResponse<EmptyData>.self, from: data) {
                        print("❌ 錯誤訊息: \(errorResponse.message ?? "未知錯誤")")
                    }
                    return nil
                }
            }
            
            // 解析回應
            let decoder = JSONDecoder()
            let result = try decoder.decode(T.self, from: data)
            return result
            
        } catch {
            print("❌ API請求失敗: \(error)")
            if let decodingError = error as? DecodingError {
                print("❌ 解碼錯誤詳情: \(decodingError)")
            }
            return nil
        }
    }
    
    // MARK: - 輔助方法
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 檢查網路連線狀態
    func checkNetworkConnection() async -> Bool {
        if let healthResponse = await checkHealth() {
            return healthResponse.status == "healthy"
        }
        return false
    }
}

// MARK: - 輔助結構
struct EmptyBody: Codable {}
struct EmptyData: Codable {}

// MARK: - 擴展DataStore以支援API整合
extension DataStore {
    /// 重新同步用戶資料到API
    func syncUserToAPI() {
        guard !userName.isEmpty, !userID.isEmpty, let createdDate = userCreatedDate else { 
            print("⚠️ 缺少用戶資料，無法同步")
            return 
        }
        
        Task {
            let result = await APIService.shared.createUser(
                name: userName, 
                userID: userID, 
                createdDate: createdDate
            )
            
            if let response = result, response.success {
                print("✅ 用戶同步成功: \(userID)")
                DispatchQueue.main.async {
                    // 可在此處更新UI狀態
                }
            } else {
                print("❌ 用戶同步失敗: \(result?.message ?? "未知錯誤")")
            }
        }
    }
    
    /// 驗證用戶ID是否有效
    func validateUserID() async -> Bool {
        guard !userID.isEmpty else { return false }
        
        let result = await APIService.shared.validateUserID(userID)
        
        if let response = result, response.success, let data = response.data {
            return data.isValid && data.exists
        }
        
        return false
    }
    
    /// 生成新的用戶ID
    func generateNewUserID() async -> String? {
        let result = await APIService.shared.generateUserID()
        
        if let response = result, response.success, let data = response.data {
            return data.userID
        }
        
        return nil
    }
    
    /// 同步用戶數據到伺服器
    func syncUserData() async -> Bool {
        guard !userName.isEmpty, !userID.isEmpty else { return false }
        
        let result = await APIService.shared.syncUserData(userID: userID, userName: userName)
        
        if let response = result, response.success {
            print("✅ 用戶數據同步成功")
            return true
        } else {
            print("❌ 用戶數據同步失敗: \(result?.message ?? "未知錯誤")")
            return false
        }
    }
    
    /// 檢查API連線狀態
    func checkAPIConnection() async -> Bool {
        return await APIService.shared.checkNetworkConnection()
    }
    
    /// 更新用戶名稱到API
    func updateUserNameToAPI(oldName: String, newName: String) {
        guard !userID.isEmpty, !newName.isEmpty else { return }
        
        Task {
            let result = await APIService.shared.updateUserName(userID: userID, newName: newName)
            
            if let response = result, response.success {
                print("✅ 用戶名稱更新成功: \(oldName) -> \(newName)")
            } else {
                print("❌ 用戶名稱更新失敗: \(result?.message ?? "未知錯誤")")
            }
        }
    }
}
