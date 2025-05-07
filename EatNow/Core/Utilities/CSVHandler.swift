import Foundation
import SwiftUI

// CSV處理工具
struct CSVHandler {
    
    // 從CSV文本創建Shop模型
    static func parseCSV(text: String) -> Result<[Shop], CSVError> {
        // 清除前後空白
        let trimmedCSV = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmedCSV.components(separatedBy: .newlines)
        
        // 檢查是否有資料
        if lines.count <= 1 {
            return .failure(.insufficientData)
        }
        
        var tempShops: [String: Shop] = [:]
        
        // 從第二行開始，第一行是標題
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let components = line.components(separatedBy: ",")
            if components.count < 3 {
                return .failure(.invalidFormat(line: i+1))
            }
            
            let shopName = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let itemName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let priceString = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let price = Int(priceString) else {
                return .failure(.invalidPrice(line: i+1))
            }
            
            // 創建或更新店家
            if var shop = tempShops[shopName] {
                shop.menuItems.append(MenuItem(name: itemName, price: price))
                tempShops[shopName] = shop
            } else {
                let newShop = Shop(name: shopName, menuItems: [MenuItem(name: itemName, price: price)])
                tempShops[shopName] = newShop
            }
        }
        
        // 檢查是否成功創建店家
        let shops = Array(tempShops.values)
        if shops.isEmpty {
            return .failure(.noValidData)
        }
        
        return .success(shops)
    }
    
    // 從URL加載CSV文件
    static func loadCSVFromFile(url: URL) -> Result<[Shop], CSVError> {
        do {
            let csvString = try String(contentsOf: url, encoding: .utf8)
            return parseCSV(text: csvString)
        } catch {
            return .failure(.fileReadError)
        }
    }
    
    // 將Shop模型導出為CSV文本
    static func exportToCSV(shops: [Shop]) -> String {
        var csvString = "店家名稱,品項名稱,價格\n"
        
        for shop in shops {
            for item in shop.menuItems {
                csvString += "\(shop.name),\(item.name),\(item.price)\n"
            }
        }
        
        return csvString
    }
    
    // 將CSV文本保存到文件
    static func saveCSVToFile(csv: String, filename: String) -> Result<URL, CSVError> {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(fileURL)
        } catch {
            return .failure(.fileWriteError)
        }
    }
    
    // 取得範例CSV數據
    static func getExampleCSV() -> String {
        // 嘗試從Resources資源目錄讀取
        if let path = Bundle.main.path(forResource: "ExampleCSV", ofType: "txt"),
           let content = try? String(contentsOfFile: path, encoding: .utf8) {
            return content
        }
        
        // 如果文件不存在，返回硬編碼的範例
        return """
        店家名稱,品項名稱,價格
        好好小吃店,炒麵,80
        好好小吃店,水餃,60
        好好小吃店,鍋貼,70
        好好小吃店,滷肉飯,50
        美味餐廳,漢堡,120
        美味餐廳,炸雞排,150
        美味餐廳,薯條,60
        美味餐廳,沙拉,90
        樂園麵店,牛肉麵,160
        樂園麵店,陽春麵,70
        樂園麵店,餛飩湯,80
        樂園麵店,滷蛋,20
        """
    }
}

// CSV錯誤類型
enum CSVError: Error, LocalizedError {
    case insufficientData
    case invalidFormat(line: Int)
    case invalidPrice(line: Int)
    case noValidData
    case fileReadError
    case fileWriteError
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "資料不足，請至少提供一筆完整的店家菜單項目"
        case .invalidFormat(let line):
            return "第\(line)行資料格式錯誤，請確保包含店家名稱、品項名稱和價格"
        case .invalidPrice(let line):
            return "第\(line)行價格格式錯誤，請確保價格為整數"
        case .noValidData:
            return "無法匯入資料，請檢查格式是否正確"
        case .fileReadError:
            return "無法讀取CSV文件"
        case .fileWriteError:
            return "無法寫入CSV文件"
        }
    }
} 