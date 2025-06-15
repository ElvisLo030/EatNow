# EatNow API 前端使用指南

## 概述

本文檔提供 EatNow 使用者編號 API 的完整前端集成指南，包含所有可用端點、請求格式、回應格式和錯誤處理。

## API 基本資訊

- **基礎 URL**: `http://localhost:8000`（開發環境）
- **內容類型**: `application/json`
- **編碼**: UTF-8
- **時間格式**: ISO 8601 (YYYY-MM-DDTHH:mm:ss.sssZ)

## 通用回應格式

### 成功回應
```json
{
  "success": true,
  "data": { /* 具體資料 */ },
  "message": "操作成功訊息"
}
```

### 錯誤回應
```json
{
  "success": false,
  "data": null,
  "message": "錯誤訊息",
  "timestamp": "2025-06-15T10:30:00Z"
}
```

## API 端點詳細說明

### 1. 健康檢查

**端點**: `GET /health`  
**用途**: 檢查 API 服務狀態

#### 請求示例
```javascript
const response = await fetch('/health');
const data = await response.json();
```

#### 成功回應 (200)
```json
{
  "status": "healthy",
  "timestamp": "2025-06-15T10:30:00Z",
  "version": "1.0.0"
}
```

---

### 2. 創建用戶

**端點**: `POST /users`  
**用途**: 當用戶首次輸入使用者名稱時，註冊用戶資料

#### 請求格式
```json
{
  "name": "使用者名稱",
  "userID": "A1B2C3D4",
  "createdDate": "2025-06-15T10:30:00Z"
}
```

#### 欄位說明
- `name` (string, 必填): 使用者名稱，1-50字元
- `userID` (string, 必填): 8位英數字編號 (A-Z, 0-9)
- `createdDate` (string, 必填): ISO 8601 格式時間

#### 請求示例
```javascript
const createUser = async (userData) => {
  const response = await fetch('/users', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name: userData.name.trim(),
      userID: userData.userID,
      createdDate: new Date().toISOString()
    })
  });
  
  const result = await response.json();
  
  if (!response.ok) {
    throw new Error(result.message || '創建用戶失敗');
  }
  
  return result;
};
```

#### 成功回應 (201)
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

#### 錯誤回應
- **400 Bad Request**: 資料格式無效
- **409 Conflict**: 用戶編號已存在
- **500 Internal Server Error**: 伺服器內部錯誤

---

### 3. 生成使用者編號

**端點**: `POST /api/user/id/generate`  
**用途**: 生成新的8位使用者編號

#### 請求示例
```javascript
const generateUserID = async () => {
  const response = await fetch('/api/user/id/generate', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    }
  });
  
  const result = await response.json();
  return result.data.userID;
};
```

#### 成功回應 (200)
```json
{
  "success": true,
  "data": {
    "userID": "X9Y8Z7W6",
    "createdAt": "2025-06-15T10:30:00Z",
    "message": "新的使用者編號已生成"
  }
}
```

---

### 4. 驗證使用者編號

**端點**: `GET /api/user/id/validate/{userID}`  
**用途**: 驗證使用者編號格式和存在性

#### 請求示例
```javascript
const validateUserID = async (userID) => {
  const response = await fetch(`/api/user/id/validate/${userID}`);
  const result = await response.json();
  
  return {
    isValid: result.data.isValid,
    exists: result.data.exists
  };
};
```

#### 成功回應 (200)
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

---

### 5. 同步使用者資料

**端點**: `POST /api/user/sync`  
**用途**: 同步使用者基本資料到伺服器

#### 請求格式
```json
{
  "userID": "A1B2C3D4",
  "userName": "使用者暱稱",
  "lastActiveAt": "2025-06-15T10:30:00Z"
}
```

#### 請求示例
```javascript
const syncUserData = async (syncData) => {
  const response = await fetch('/api/user/sync', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      userID: syncData.userID,
      userName: syncData.userName,
      lastActiveAt: new Date().toISOString()
    })
  });
  
  const result = await response.json();
  return result;
};
```

#### 成功回應 (200)
```json
{
  "success": true,
  "data": {
    "userID": "A1B2C3D4",
    "syncedAt": "2025-06-15T10:30:00Z",
    "message": "使用者資料同步成功"
  }
}
```

## 前端實作建議

### 1. 使用者編號管理

```javascript
class UserIDManager {
  constructor() {
    this.userID = localStorage.getItem('eatnow_user_id');
    this.userName = localStorage.getItem('eatnow_user_name');
  }
  
  // 生成新編號
  async generateNewID() {
    try {
      const response = await fetch('/api/user/id/generate', {
        method: 'POST'
      });
      const result = await response.json();
      
      this.userID = result.data.userID;
      localStorage.setItem('eatnow_user_id', this.userID);
      
      return this.userID;
    } catch (error) {
      console.error('生成編號失敗:', error);
      throw error;
    }
  }
  
  // 創建用戶
  async createUser(userName) {
    if (!this.userID) {
      await this.generateNewID();
    }
    
    try {
      const userData = {
        name: userName.trim(),
        userID: this.userID,
        createdDate: new Date().toISOString()
      };
      
      const response = await fetch('/users', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(userData)
      });
      
      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || '創建用戶失敗');
      }
      
      const result = await response.json();
      this.userName = userName;
      localStorage.setItem('eatnow_user_name', userName);
      
      return result;
    } catch (error) {
      console.error('創建用戶失敗:', error);
      throw error;
    }
  }
  
  // 驗證編號
  async validateID(userID = this.userID) {
    try {
      const response = await fetch(`/api/user/id/validate/${userID}`);
      const result = await response.json();
      return result.data;
    } catch (error) {
      console.error('驗證編號失敗:', error);
      return { isValid: false, exists: false };
    }
  }
  
  // 同步資料
  async syncData() {
    if (!this.userID || !this.userName) {
      console.warn('缺少用戶資料，無法同步');
      return;
    }
    
    try {
      const response = await fetch('/api/user/sync', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userID: this.userID,
          userName: this.userName,
          lastActiveAt: new Date().toISOString()
        })
      });
      
      const result = await response.json();
      return result;
    } catch (error) {
      console.error('同步資料失敗:', error);
      throw error;
    }
  }
}
```

### 2. 錯誤處理

```javascript
class APIError extends Error {
  constructor(message, status, code) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const handleAPIError = (error, response) => {
  switch (response.status) {
    case 400:
      throw new APIError('請求資料格式無效', 400, 'INVALID_REQUEST');
    case 409:
      throw new APIError('用戶編號已存在', 409, 'USER_ID_EXISTS');
    case 500:
      throw new APIError('伺服器內部錯誤', 500, 'SERVER_ERROR');
    default:
      throw new APIError('未知錯誤', response.status, 'UNKNOWN_ERROR');
  }
};
```

### 3. 使用示例

```javascript
// 初始化管理器
const userManager = new UserIDManager();

// 用戶首次使用
const handleFirstTimeUser = async () => {
  try {
    const userName = document.getElementById('userName').value;
    
    if (!userName.trim()) {
      alert('請輸入使用者名稱');
      return;
    }
    
    // 創建用戶
    const result = await userManager.createUser(userName);
    
    console.log('用戶創建成功:', result);
    
    // 顯示用戶編號
    document.getElementById('userID').textContent = result.data.userID;
    
    // 自動同步資料
    await userManager.syncData();
    
  } catch (error) {
    console.error('操作失敗:', error);
    alert(`操作失敗: ${error.message}`);
  }
};

// 驗證現有編號
const verifyExistingUser = async () => {
  try {
    const userID = document.getElementById('existingUserID').value;
    
    const validation = await userManager.validateID(userID);
    
    if (validation.isValid && validation.exists) {
      console.log('用戶編號有效且存在');
      userManager.userID = userID;
      localStorage.setItem('eatnow_user_id', userID);
    } else if (validation.isValid) {
      console.log('用戶編號格式正確但不存在');
    } else {
      console.log('用戶編號格式無效');
    }
    
  } catch (error) {
    console.error('驗證失敗:', error);
  }
};
```

## 注意事項

### 1. 時間格式
- 所有時間都使用 ISO 8601 格式
- 建議使用 `new Date().toISOString()` 生成

### 2. 使用者編號規則
- 8位英數字 (A-Z, 0-9)
- 大寫字母和數字組合
- 範例: `A1B2C3D4`, `X9Y8Z7W6`

### 3. 錯誤處理
- 始終檢查 `response.ok` 
- 適當處理各種 HTTP 狀態碼
- 提供用戶友好的錯誤訊息

### 4. 本地儲存
- 使用 `localStorage` 儲存用戶編號和名稱
- 定期同步到伺服器

### 5. 網路狀態
- 支援離線操作
- 網路恢復時自動同步

## 環境配置

### 開發環境
```javascript
const API_BASE_URL = 'http://localhost:8000';
```

### 生產環境
```javascript
const API_BASE_URL = 'https://api.eatnow.example.com/v1';
```

## 測試工具

您可以使用以下工具測試 API：
- **API 文檔**: `http://localhost:8000/docs`
- **Swagger UI**: 互動式 API 測試介面
- **curl**: 命令行測試工具

## 更新記錄

- **2025-06-15**: 初始版本，包含完整的使用者編號管理功能
- **2025-06-15**: 修復寫入端點時區處理問題 