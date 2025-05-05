//
//  Item.swift
//  EatNow
//
//  Created by 羅來恩 on 2025/5/5.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
