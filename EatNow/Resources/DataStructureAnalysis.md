# EatNow App 資料結構關聯分析

## 核心資料模型架構

### 1. 資料結構圖表

```
┌───────────────────────────────────────┐
│                DataStore              │
│     (中央資料管理類，使用單例模式)         │
└───────────────────┬───────────────────┘
          ┌─────────┼─────────┬─────────┬─────────┐
          ▼         ▼         ▼         ▼         ▼
┌─────────────┐ ┌─────────┐ ┌──────────┐ ┌───────────┐ ┌───────────────┐
│    Shop     │ │ MenuItem│ │CustomFood│ │OrderRecord│ │ StatsSession  │
└──────┬──────┘ └─────────┘ └──────────┘ └───────────┘ └───────────────┘
       │
       │ 包含多個
       ▼
┌─────────────┐
│  MenuItem   │
└─────────────┘
```

### 2. 核心資料結構詳解

#### 模型層 (Models.swift)

1. **`Shop` 結構體**：店家資料
   - 屬性：`id`(UUID), `name`(String), `menuItems`([MenuItem])
   - 關聯：一對多關係包含多個 `MenuItem`

2. **`MenuItem` 結構體**：菜單項目
   - 屬性：`id`(UUID), `name`(String), `price`(Int)
   - 關聯：從屬於 `Shop`

3. **`CustomFood` 結構體**：自訂食物項目
   - 屬性：`id`(UUID), `name`(String)
   - 方法：`defaultItems()` 提供預設食物項目

4. **`OrderRecord` 結構體**：訂單記錄
   - 屬性：`id`(UUID), `personName`(String), `itemName`(String), `note`(String), `price`(Int)

5. **`StatsSession` 結構體**：統計分析區段
   - 屬性：`id`(UUID), `shopName`(String), `records`([OrderRecord]), `date`(Date)
   - 關聯：包含多個 `OrderRecord`

6. **`NavigationItem` 枚舉**：導航項目
   - 案例：`shop(index:)`, `menu(shopIndex:, itemIndex:)`, `customFoods`

#### 資料管理層 (DataStore.swift)

1. **`DataStore` 類別**：核心資料管理中心
   - 使用單例模式 (`static let shared`)，確保資料共享與一致性
   - 符合 `ObservableObject` 協議，支援 SwiftUI 的響應式更新

2. **統計數據**：
   - `personalRandomCount`: 個人模式隨機推薦點擊次數
   - `groupRandomCount`: 團體模式隨機推薦點擊次數
   - `personalDecisionsMade`: 個人決策採納次數
   - `groupDecisionsMade`: 團體決策採納次數
   - `totalDecisionsMade`: 總決策次數
   - `foodSelections`: 食物選擇統計字典 `[String: Int]`
   - `shopSelections`: 店家選擇統計字典 `[String: Int]`

3. **資料容器**：
   - `shops`: 店家陣列 `[Shop]`
   - `customFoods`: 自訂食物陣列 `[CustomFood]`
   - `statsHistory`: 統計記錄 `[StatsSession]`
   - `commonNames`: 常用名稱陣列 `[String]`
   - `unlockedAchievements`: 已解鎖成就集合 `Set<String>`

4. **使用者資料**：
   - `userName`: 使用者名稱
   - `userAvatarName`: 使用者頭像名稱
   - `effectsEnabled`: 特效是否啟用

5. **數據持久化**：
   - 各種資料類型都具有對應的 `save` 和 `load` 方法
   - 使用 JSON 格式儲存在 App Documents 目錄中

### 3. 視圖層與資料流

#### 主要視圖結構

1. **`TabView` 主導航**：
   - `HomeView`: 主頁隨機推薦功能
   - `ShopListView`: 店家管理功能
   - `StatsView`: 統計分析功能
   - `SettingsView`: 設定管理功能

2. **資料流動模式**：
   - 所有視圖都通過 `@EnvironmentObject var dataStore: DataStore` 共享中央資料
   - 視圖中的操作會透過 `dataStore` 修改資料，並自動觸發視圖刷新

## 詳細依賴關係分析

### 1. 資料依賴方向

```
┌───────────────────────────────────────────────────────┐
│                       App Views                       │
│  ┌───────────┐   ┌───────────┐   ┌───────────────┐    │
│  │ HomeView  │   │ ShopViews │   │ SettingsView  │    │
│  └─────┬─────┘   └─────┬─────┘   └───────┬───────┘    │
│        │               │                 │            │
│        ▼               ▼                 ▼            │
│  ┌──────────────────────────────────────────────┐     │
│  │               DataStore.shared               │     │
│  └────────────────────┬─────────────────────────┘     │
│                       │                               │
│                       ▼                               │
│  ┌────────────────────────────────────────────────┐   │
│  │              本地資料儲存 (JSON)                 │   │
│  └────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────┘
```

### 2. 重要變數依賴關係

#### HomeView 的依賴關係

- **隨機推薦功能**：
  - 依賴 `dataStore.shops` 和 `dataStore.customFoods` 獲取隨機項目
  - 觸發 `dataStore.personalRandomCount`/`groupRandomCount` 增加
  - 選擇採納時更新 `dataStore.foodSelections`/`shopSelections`
  - 選擇採納時更新 `dataStore.personalDecisionsMade`/`groupDecisionsMade`

```
HomeView
  ├── selectedMode (0:食物, 1:店家)
  │     └── 決定呼叫 dataStore.getRandomMenuItem() 或取得隨機店家
  ├── recommendedItem/recommendedShop
  │     └── 來自 dataStore 的隨機選擇結果
  └── 採納決策
        ├── 更新 dataStore.foodSelections/shopSelections
        ├── 更新 dataStore.personalDecisionsMade/groupDecisionsMade
        └── 更新 dataStore.totalDecisionsMade
```

#### ShopViews 的依賴關係

- **店家管理**：
  - 直接操作 `dataStore.shops` 陣列
  - 提供 CRUD 功能：新增、編輯、刪除店家和菜單項目

```
ShopListView
  ├── 顯示所有 dataStore.shops
  ├── 支援店家選取與批量刪除
  │     └── 調用 dataStore.deleteShop()
  ├── 支援匯入功能
  │     └── 通過 CSVImportView 匯入資料至 dataStore.shops
  └── 導航至 ShopDetailView
        ├── 顯示特定 dataStore.shops[index] 的詳情
        ├── 編輯店家名稱直接修改 dataStore.shops[index].name
        └── 管理菜單項目
              ├── 新增：dataStore.addMenuItem()
              ├── 編輯：直接修改 dataStore.shops[index].menuItems[idx]
              └── 刪除：dataStore.deleteMenuItem()
```

#### StatsView 的依賴關係

- **統計資料**：
  - 讀取並視覺化 `dataStore` 中的各種統計資料
  - 成就管理：讀取和解鎖 `dataStore.unlockedAchievements`

```
StatsView
  ├── 總覽統計 (OverviewStatsView)
  │     ├── 顯示 dataStore.personalRandomCount 和 groupRandomCount
  │     ├── 顯示 dataStore.totalDecisionsMade
  │     └── 顯示最常選擇的食物和店家 (來自 foodSelections 和 shopSelections)
  ├── 食物統計 (CombinedFoodStatsView)
  │     ├── 顯示 dataStore.personalRandomCount
  │     ├── 顯示 dataStore.personalDecisionsMade
  │     └── 分析 dataStore.foodSelections 的分布
  ├── 店家統計 (GroupStatsView)
  │     ├── 顯示 dataStore.groupRandomCount
  │     ├── 顯示 dataStore.groupDecisionsMade
  │     └── 分析 dataStore.shopSelections 的分布
  └── 成就系統 (AchievementView)
        ├── 讀取 dataStore.unlockedAchievements
        └── 根據各種統計數據顯示成就進度和解鎖狀態
```

#### SettingsView 的依賴關係

- **設定管理**：
  - 直接修改 `dataStore` 中的使用者設定
  - 提供資料重置和匯出功能

```
SettingsView
  ├── 使用者檔案
  │     ├── 編輯 dataStore.userName
  │     └── 編輯 dataStore.userAvatarName
  ├── 顯示設定
  │     └── 控制 dataStore.effectsEnabled
  ├── 資料管理
  │     ├── 匯出店家資料 (CSV)
  │     │     └── 讀取 dataStore.shops
  │     ├── 重置統計資料
  │     │     └── 調用 dataStore.resetStats()
  │     └── 清除所有店家資料
  │           └── 調用 dataStore.clearShopsData()
```

### 3. 關聯特性與資料流通路徑

1. **單向資料流模式**：
   - 視圖層通過 `dataStore` 讀取資料
   - 所有修改都經過 `dataStore` 的方法實現
   - `@Published` 屬性確保資料變更時視圖自動更新

2. **資料持久化路徑**：
   - 記憶體中的資料 (`@Published` 變數)
   - 資料變更觸發 `didSet` 觀察器
   - 呼叫對應的 `save` 方法
   - 資料序列化為 JSON 並寫入本地檔案
   - App 啟動時從本地檔案讀取並還原狀態

3. **跨模組資料共享**：
   - 主要功能模組間通過 `DataStore.shared` 共享資料
   - 功能模組間沒有直接依賴，降低耦合度
   - 所有視圖通過 `.environmentObject(dataStore)` 獲取共享資料

## 總結

EatNow App 採用集中式資料管理模式，以 `DataStore` 類別作為唯一的資料來源和管理中心。此架構具有以下特點：

1. **單一資料源**：所有資料儲存在 `DataStore` 中，視圖層僅負責顯示和用戶交互
2. **響應式更新**：利用 SwiftUI 的 `@Published` 和 `@EnvironmentObject` 實現視圖與資料的自動同步
3. **模組化設計**：各功能模組（主頁、店家管理、統計、設定）相互獨立，僅通過共享的 `DataStore` 交換資料
4. **資料持久化**：所有關鍵資料都自動保存至本地 JSON 檔案，確保 App 重啟後資料不丟失
5. **清晰的資料依賴**：每個視圖僅依賴其所需的資料子集，減少不必要的重繪和更新

這種架構使 EatNow App 具有良好的可維護性和擴展性，同時確保了資料的一致性和可靠性。
