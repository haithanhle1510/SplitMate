//
//  Item.swift
//  SplitMate
//
//  Created by Hai Thanh Le on 27/4/2026.
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
