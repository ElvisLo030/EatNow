import SwiftUI
import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 安全索引存取，避免陣列越界
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension DateFormatter {
    static var short: DateFormatter {
        let fmt = DateFormatter()
        fmt.dateStyle = .short; fmt.timeStyle = .short
        return fmt
    }
} 