import Foundation
import SwiftUI

// MARK: - API錯誤類型

enum APIError: Error {
    case invalidURL
    case networkError(String)
    case unauthorized(String)
    case notFound(String)
    case badRequest(String)
    case serverError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "無效的URL"
        case .networkError(let message):
            return "網路錯誤: \(message)"
        case .unauthorized(let message):
            return "權限錯誤: \(message)"
        case .notFound(let message):
            return "資源不存在: \(message)"
        case .badRequest(let message):
            return "請求錯誤: \(message)"
        case .serverError(let message):
            return "伺服器錯誤: \(message)"
        }
    }
}

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

// MARK: - 雲端菜單相關數據模型

// 菜單上傳請求
struct MenuUploadRequest: Codable {
    let userID: String
    let shopName: String
    let shopCode: String
    let menuItems: [CloudMenuItem]
    let uploadDate: String
}

// 雲端菜單項目
struct CloudMenuItem: Codable {
    let name: String
    let price: Int
}

// 菜單上傳回應數據
struct MenuUploadData: Codable {
    let shopCode: String
    let shopName: String
    let uploadedAt: String
    let itemCount: Int
    let contentHash: String? // 新增：內容雜湊
    let syncStatus: String? // 新增：同步狀態
    let message: String
}

// 菜單狀態檢查回應數據
struct MenuStatusData: Codable {
    let shops: [CloudShopStatus]
}

// 雲端店家狀態
struct CloudShopStatus: Codable {
    let shopCode: String
    let shopName: String
    let uploadDate: String
    let lastModifiedDate: String? // 新增：最後修改日期
    let itemCount: Int
    let isUploaded: Bool
    let contentHash: String? // 新增：內容雜湊
    let syncStatus: String? // 新增：同步狀態 (synced, modified, not_synced)
}

// 菜單批量上傳請求
struct BatchMenuUploadRequest: Codable {
    let userID: String
    let shops: [ShopUploadData]
    let uploadDate: String
}

// 店家上傳數據
struct ShopUploadData: Codable {
    let shopName: String
    let shopCode: String
    let menuItems: [CloudMenuItem]
}

// 批量上傳回應數據
struct BatchMenuUploadData: Codable {
    let uploadedShops: [MenuUploadData]
    let failedShops: [String]
    let totalShops: Int
    let successCount: Int
}

// MARK: - 增強版雲端菜單 API 數據模型

// 菜單內容驗證請求
struct MenuVerificationRequest: Codable {
    let userID: String
    let shops: [MenuVerificationShop]
}

// 菜單驗證店家數據
struct MenuVerificationShop: Codable {
    let shopCode: String
    let contentHash: String
    let menuItems: [CloudMenuItem]
}

// 菜單驗證回應數據
struct MenuVerificationData: Codable {
    let verificationResults: [MenuVerificationResult]
}

// 菜單驗證結果
struct MenuVerificationResult: Codable {
    let shopCode: String
    let isContentMatched: Bool
    let lastUploadDate: String
    let cloudContentHash: String
    let itemCount: Int
}

// 詳細菜單狀態回應數據
struct DetailedMenuStatusData: Codable {
    let shops: [DetailedCloudShopStatus]
}

// 詳細雲端店家狀態
struct DetailedCloudShopStatus: Codable {
    let shopCode: String
    let shopName: String
    let isUploaded: Bool
    let uploadDate: String
    let lastModifiedDate: String?
    let itemCount: Int
    let contentHash: String
    let syncStatus: String // synced, modified, not_synced
}

// 內容雜湊生成請求
struct ContentHashRequest: Codable {
    let menuItems: [CloudMenuItem]
}

// 內容雜湊生成回應數據
struct ContentHashData: Codable {
    let contentHash: String
    let itemCount: Int
    let algorithm: String
}

// MARK: - 刪除菜單相關數據模型

// 菜單刪除請求
struct MenuDeleteRequest: Codable {
    let userID: String
}

// 菜單刪除回應數據
struct MenuDeleteData: Codable {
    let shopCode: String
    let shopName: String
    let deletedAt: String
    let message: String
}

// 菜單刪除回應
struct MenuDeleteResponse: Codable {
    let success: Bool
    let data: MenuDeleteData?
    let timestamp: String
    let detail: String?  // 用於錯誤訊息
}

// MARK: - 錯誤處理相關數據模型

// 通用錯誤回應
struct ErrorResponse: Codable {
    let success: Bool
    let detail: String
}

// 增強的API回應格式（支援詳細錯誤）
struct EnhancedAPIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let timestamp: String?
    let detail: String?  // 用於錯誤詳情
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
    
    // MARK: - 雲端菜單API方法
    
    /// 7. 上傳單個店家菜單
    func uploadMenu(userID: String, shopName: String, shopCode: String, menuItems: [MenuItem]) async -> APIResponse<MenuUploadData>? {
        let cloudMenuItems = menuItems.map { CloudMenuItem(name: $0.name, price: $0.price) }
        let request = MenuUploadRequest(
            userID: userID,
            shopName: shopName,
            shopCode: shopCode,
            menuItems: cloudMenuItems,
            uploadDate: dateFormatter.string(from: Date())
        )
        
        return await performPOSTRequest(endpoint: "/api/menu/upload", body: request)
    }
    
    /// 8. 批量上傳多個店家菜單
    func batchUploadMenus(userID: String, shops: [Shop]) async -> APIResponse<BatchMenuUploadData>? {
        let shopUploadData = shops.map { shop in
            ShopUploadData(
                shopName: shop.name,
                shopCode: shop.shopCode ?? generateShopCode(),
                menuItems: shop.menuItems.map { CloudMenuItem(name: $0.name, price: $0.price) }
            )
        }
        
        let request = BatchMenuUploadRequest(
            userID: userID,
            shops: shopUploadData,
            uploadDate: dateFormatter.string(from: Date())
        )
        
        return await performPOSTRequest(endpoint: "/api/menu/batch-upload", body: request)
    }
    
    /// 9. 檢查用戶的菜單上傳狀態
    func checkMenuStatus(userID: String) async -> APIResponse<MenuStatusData>? {
        return await performGETRequest(endpoint: "/api/menu/status/\(userID)")
    }
    
    /// 10. 更新店家菜單（增強錯誤處理）
    func updateMenu(userID: String, shopCode: String, shopName: String, menuItems: [MenuItem]) async -> Result<APIResponse<MenuUploadData>, APIError> {
        guard let url = URL(string: baseURL + "/api/menu/update/\(shopCode)") else {
            return .failure(.invalidURL)
        }
        
        let cloudMenuItems = menuItems.map { CloudMenuItem(name: $0.name, price: $0.price) }
        let request = MenuUploadRequest(
            userID: userID,
            shopName: shopName,
            shopCode: shopCode,
            menuItems: cloudMenuItems,
            uploadDate: dateFormatter.string(from: Date())
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("EatNow-iOS/\(getAppVersion())", forHTTPHeaderField: "User-Agent")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await session.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API請求: PUT /api/menu/update/\(shopCode) - 狀態碼: \(httpResponse.statusCode)")
                
                // 打印回應數據（調試用）
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 回應數據: \(responseString)")
                }
                
                let decoder = JSONDecoder()
                
                if httpResponse.statusCode == 200 {
                    // 成功回應
                    let successResponse = try decoder.decode(APIResponse<MenuUploadData>.self, from: data)
                    return .success(successResponse)
                } else {
                    // 錯誤回應
                    let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                    
                    switch httpResponse.statusCode {
                    case 403:
                        return .failure(.unauthorized(errorResponse.detail))
                    case 404:
                        return .failure(.notFound(errorResponse.detail))
                    case 400:
                        return .failure(.badRequest(errorResponse.detail))
                    default:
                        return .failure(.serverError(errorResponse.detail))
                    }
                }
            }
            
            return .failure(.networkError("無效的回應"))
            
        } catch {
            print("❌ 更新菜單失敗: \(error)")
            return .failure(.networkError(error.localizedDescription))
        }
    }
    
    // MARK: - 增強版雲端菜單 API 方法
    
    /// 11. 菜單內容驗證
    func verifyMenuContent(userID: String, shops: [MenuVerificationShop]) async -> APIResponse<MenuVerificationData>? {
        let request = MenuVerificationRequest(userID: userID, shops: shops)
        return await performPOSTRequest(endpoint: "/api/menu/verify", body: request)
    }
    
    /// 12. 詳細菜單狀態查詢
    func getDetailedMenuStatus(userID: String) async -> APIResponse<DetailedMenuStatusData>? {
        return await performGETRequest(endpoint: "/api/menu/status/detailed?userID=\(userID)")
    }
    
    /// 13. 生成菜單內容雜湊
    func generateContentHash(menuItems: [MenuItem]) async -> APIResponse<ContentHashData>? {
        let cloudMenuItems = menuItems.map { CloudMenuItem(name: $0.name, price: $0.price) }
        let request = ContentHashRequest(menuItems: cloudMenuItems)
        return await performPOSTRequest(endpoint: "/api/menu/hash", body: request)
    }
    
    // MARK: - 刪除菜單 API 方法
    
    /// 14. 刪除菜單
    func deleteMenu(shopCode: String, userID: String) async -> Result<MenuDeleteResponse, APIError> {
        guard let url = URL(string: baseURL + "/api/menu/delete/\(shopCode)") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("EatNow-iOS/\(getAppVersion())", forHTTPHeaderField: "User-Agent")
        
        let deleteRequest = MenuDeleteRequest(userID: userID)
        
        do {
            let jsonData = try JSONEncoder().encode(deleteRequest)
            request.httpBody = jsonData
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API請求: DELETE /api/menu/delete/\(shopCode) - 狀態碼: \(httpResponse.statusCode)")
                
                // 打印回應數據（調試用）
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 回應數據: \(responseString)")
                }
                
                // 解析回應
                let decoder = JSONDecoder()
                
                if httpResponse.statusCode == 200 {
                    // 成功回應
                    let deleteResponse = try decoder.decode(MenuDeleteResponse.self, from: data)
                    return .success(deleteResponse)
                } else {
                    // 錯誤回應
                    let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                    
                    switch httpResponse.statusCode {
                    case 403:
                        return .failure(.unauthorized(errorResponse.detail))
                    case 404:
                        return .failure(.notFound(errorResponse.detail))
                    case 400:
                        return .failure(.badRequest(errorResponse.detail))
                    default:
                        return .failure(.serverError(errorResponse.detail))
                    }
                }
            }
            
            return .failure(.networkError("無效的回應"))
            
        } catch {
            print("❌ 刪除菜單失敗: \(error)")
            return .failure(.networkError(error.localizedDescription))
        }
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
    
    // MARK: - 錯誤處理輔助方法
    
    /// 處理 API 錯誤並提供用戶友好的訊息
    func handleAPIError(_ error: APIError) -> String {
        switch error {
        case .unauthorized(let detail):
            if detail.contains("無權限修改") {
                return "您沒有權限修改此店家菜單"
            } else if detail.contains("無權限刪除") {
                return "您沒有權限刪除此店家菜單"
            } else {
                return "權限不足，請檢查您的登入狀態"
            }
        case .notFound(let detail):
            if detail.contains("店家不存在") {
                return "找不到指定的店家"
            } else if detail.contains("用戶不存在") || detail.contains("用戶或店家不存在") {
                return "用戶資訊異常，請重新登入"
            } else {
                return "找不到請求的資源"
            }
        case .badRequest(let detail):
            return "請求格式錯誤：\(detail)"
        case .serverError(let detail):
            return "伺服器發生錯誤：\(detail)"
        case .networkError(let message):
            return "網路連線問題：\(message)"
        case .invalidURL:
            return "系統錯誤，請聯繫客服"
        }
    }
    
    /// 顯示刪除確認對話框的輔助方法
    static func showDeleteConfirmation(
        shopName: String,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: "確認刪除",
            message: "確定要刪除「\(shopName)」的菜單嗎？此操作無法復原。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            onCancel?()
        })
        
        alert.addAction(UIAlertAction(title: "刪除", style: .destructive) { _ in
            onConfirm()
        })
        
        return alert
    }
    
    // MARK: - 輔助方法
    
    /// 生成6位數店家編號
    private func generateShopCode() -> String {
        return String(format: "%06d", Int.random(in: 100000...999999))
    }
    
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
