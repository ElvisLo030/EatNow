# EatNow 使用者編號 API 文檔

## 概述

EatNow App 的使用者編號系統提供了唯一的用戶識別功能，為未來的團體點餐功能做準備。本文檔詳細說明了相關的API端點規格，供後端開發使用。

## API 基本資訊

- **基礎 URL**: `https://api.eatnow.example.com/v1`
- **內容類型**: `application/json`
- **編碼**: UTF-8
- **日期格式**: ISO 8601 (YYYY-MM-DDTHH:mm:ssZ)

## 認證

所有API請求都應在Header中包含：
```
User-Agent: EatNow-iOS/{版本號}
Content-Type: application/json
```

## API 端點規格

### 1. 創建用戶

**端點**: `POST /users`

**描述**: 當用戶首次輸入使用者名稱時，記錄用戶基本資料。

**請求體**:
```json
{
  "name": "使用者名稱",
  "userID": "A1B2C3D4",
  "createdDate": "2025-06-15T10:30:00Z"
}
```

**請求體欄位說明**:
- `name` (string, 必填): 使用者輸入的名稱，長度1-50字元
- `userID` (string, 必填): App生成的8位英數字編號，格式: [A-Z0-9]{8}
- `createdDate` (string, 必填): 用戶編號生成的時間，ISO 8601格式

**成功回應** (201 Created):
```json
{
  "success": true,
  "data": {
    "userID": "A1B2C3D4",
    "name": "使用者名稱",
    "createdDate": "2025-06-15T10:30:00Z",
    "registered": true
  },
  "message": "用戶創建成功",
  "timestamp": "2025-06-15T10:30:00Z"
}
```

**錯誤回應**:

*400 Bad Request (資料格式錯誤)*:
```json
{
  "success": false,
  "data": null,
  "message": "請求資料格式無效",
  "timestamp": "2025-06-15T10:30:00Z"
}
```

*409 Conflict (用戶編號已存在)*:
```json
{
  "success": false,
  "data": null,
  "message": "用戶編號已存在",
  "timestamp": "2025-06-15T10:30:00Z"
}
```

*500 Internal Server Error*:
```json
{
  "success": false,
  "data": null,
  "message": "伺服器內部錯誤",
  "timestamp": "2025-06-15T10:30:00Z"
}
```

### 2. 健康檢查

**端點**: `GET /health`

**描述**: 檢查API服務狀態。

**成功回應** (200 OK):
```json
{
  "status": "healthy",
  "timestamp": "2025-06-15T12:00:00Z",
  "version": "1.0.0"
}
```

## 資料庫設計建議

### users 表

| 欄位名稱 | 型別 | 限制 | 說明 |
|---------|------|------|------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | 內部ID |
| user_id | VARCHAR(8) | UNIQUE, NOT NULL | 使用者編號 |
| name | VARCHAR(50) | NOT NULL | 使用者名稱 |
| created_date | DATETIME | NOT NULL | 建立時間 |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE | 更新時間 |

### 索引建議
```sql
CREATE UNIQUE INDEX idx_user_id ON users(user_id);
CREATE INDEX idx_created_date ON users(created_date);
```

## 實作注意事項

### 1. 用戶編號唯一性檢查
- 在創建用戶前，必須檢查 `userID` 是否已存在
- 如果存在，返回 409 Conflict 錯誤
- 建議使用資料庫唯一約束確保資料一致性

### 2. 輸入驗證
- `name`: 長度1-50字元，移除前後空白
- `userID`: 必須符合正規表達式 `^[A-Z0-9]{8}$`
- `createdDate`: 必須是有效的ISO 8601格式

### 3. 錯誤處理
- 提供明確的錯誤訊息
- 記錄詳細的錯誤日誌供除錯使用
- 避免在錯誤訊息中洩漏敏感資訊

### 4. 效能考量
- 對 `user_id` 欄位建立唯一索引
- 考慮實作API速率限制
- 對於高流量場景，可考慮快取機制

## 安全性要求

1. **資料驗證**: 嚴格驗證所有輸入資料
2. **SQL注入防護**: 使用參數化查詢
3. **HTTPS**: 所有通訊必須使用HTTPS加密
4. **日誌記錄**: 記錄所有API請求，但不記錄敏感資料
5. **速率限制**: 實作適當的API呼叫頻率限制

## 範例實作 (Node.js/Express)

```javascript
// POST /users
app.post('/users', async (req, res) => {
  try {
    const { name, userID, createdDate } = req.body;
    
    // 輸入驗證
    if (!name || name.length > 50) {
      return res.status(400).json({
        success: false,
        data: null,
        message: "使用者名稱無效",
        timestamp: new Date().toISOString()
      });
    }
    
    if (!/^[A-Z0-9]{8}$/.test(userID)) {
      return res.status(400).json({
        success: false,
        data: null,
        message: "使用者編號格式無效",
        timestamp: new Date().toISOString()
      });
    }
    
    // 檢查編號是否已存在
    const existingUser = await db.query('SELECT id FROM users WHERE user_id = ?', [userID]);
    if (existingUser.length > 0) {
      return res.status(409).json({
        success: false,
        data: null,
        message: "用戶編號已存在",
        timestamp: new Date().toISOString()
      });
    }
    
    // 創建用戶
    await db.query(
      'INSERT INTO users (user_id, name, created_date) VALUES (?, ?, ?)',
      [userID, name.trim(), new Date(createdDate)]
    );
    
    res.status(201).json({
      success: true,
      data: {
        userID,
        name: name.trim(),
        createdDate,
        registered: true
      },
      message: "用戶創建成功",
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('創建用戶失敗:', error);
    res.status(500).json({
      success: false,
      data: null,
      message: "伺服器內部錯誤",
      timestamp: new Date().toISOString()
    });
  }
});
```

## 測試建議

### 1. 單元測試
- 測試輸入驗證邏輯
- 測試用戶編號唯一性檢查
- 測試錯誤處理邏輯

### 2. 整合測試
- 測試完整的API流程
- 測試資料庫交互
- 測試併發請求處理

### 3. 負載測試
- 測試API在高負載下的表現
- 測試資料庫連線池的處理能力

## 監控與維護

1. **API監控**: 監控回應時間、錯誤率、請求量
2. **資料庫監控**: 監控資料庫效能、連線數
3. **日誌分析**: 定期分析錯誤日誌，優化系統
4. **備份策略**: 定期備份使用者資料

## 未來擴展考量

設計時已預留擴展空間，未來可能新增：
- 用戶群組管理
- 團體點餐功能
- 使用者活動記錄
- 資料分析功能

## 版本歷史

- **v1.0** (2025-06-15): 初始版本，支援基本的用戶創建功能

#### 回應
```json
{
  "success": true,
  "data": {
    "userID": "A1B2C3D4",
    "createdAt": "2025-06-15T10:30:00Z"
  }
}
```

#### 錯誤回應
```json
{
  "success": false,
  "error": {
    "code": "USER_ID_NOT_FOUND",
    "message": "使用者編號不存在"
  }
}
```

### 2. 生成新使用者編號
**端點**: `POST /api/user/id/generate`
**描述**: 為使用者生成新的編號（會覆蓋現有編號）

#### 請求參數
無需參數

#### 回應
```json
{
  "success": true,
  "data": {
    "userID": "X9Y8Z7W6",
    "createdAt": "2025-06-15T10:35:00Z",
    "message": "新的使用者編號已生成"
  }
}
```

### 3. 驗證使用者編號
**端點**: `GET /api/user/id/validate/{userID}`
**描述**: 驗證給定的使用者編號是否有效

#### 路徑參數
- `userID` (string): 要驗證的使用者編號

#### 回應
```json
{
  "success": true,
  "data": {
    "isValid": true,
    "userID": "A1B2C3D4",
    "exists": true
  }
}
```

#### 無效編號回應
```json
{
  "success": true,
  "data": {
    "isValid": false,
    "userID": "INVALID1",
    "exists": false
  }
}
```

### 4. 同步使用者資料
**端點**: `POST /api/user/sync`
**描述**: 同步使用者的基本資料到伺服器

#### 請求體
```json
{
  "userID": "A1B2C3D4",
  "userName": "使用者暱稱",
  "lastActiveAt": "2025-06-15T10:35:00Z"
}
```

#### 回應
```json
{
  "success": true,
  "data": {
    "userID": "A1B2C3D4",
    "syncedAt": "2025-06-15T10:35:00Z",
    "message": "使用者資料同步成功"
  }
}
```

## 錯誤代碼

| 錯誤代碼 | 描述 | HTTP 狀態碼 |
|---------|------|------------|
| USER_ID_NOT_FOUND | 使用者編號不存在 | 404 |
| INVALID_USER_ID | 使用者編號格式無效 | 400 |
| USER_ID_ALREADY_EXISTS | 使用者編號已存在 | 409 |
| SYNC_FAILED | 資料同步失敗 | 500 |
| SERVER_ERROR | 伺服器內部錯誤 | 500 |

## 使用者編號格式

- **長度**: 8個字元
- **字元集**: A-Z (大寫字母) 和 0-9 (數字)
- **範例**: `A1B2C3D4`, `X9Y8Z7W6`, `M5N6P7Q8`

## 安全性考量

1. 使用者編號不包含個人敏感資訊
2. 編號隨機生成，避免可預測性
3. 建議在團體點餐功能中結合其他驗證機制
4. 編號可重新生成，但會影響已加入的團體點餐

## 實作注意事項

1. **本地優先**: 使用者編號首先在本地生成和儲存
2. **離線支援**: App 可在離線狀態下正常使用編號功能
3. **資料同步**: 當網路可用時，自動同步到伺服器
4. **重複處理**: 如果生成的編號與伺服器上的重複，自動重新生成

## 未來擴展

此 API 設計為未來團體點餐功能預留了擴展空間：

- 團體建立和加入
- 點餐狀態同步
- 群組內的消息傳遞
- 分帳功能

## 更新記錄

- **2025-06-15**: 初始版本，包含基本的使用者編號管理功能
