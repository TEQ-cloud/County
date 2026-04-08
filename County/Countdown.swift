//
//  Countdown.swift
//  County
//
//  Created by Quinten de Haard on 19/03/2026.
//

import Foundation
import SwiftData

@Model
final class Countdown {
    var name: String
    var date: Date
    var createdAt: Date

    init(name: String, date: Date) {
        self.name = name
        self.date = date
        self.createdAt = Date()
    }

    var daysLeft: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: now, to: target)
        return components.day ?? 0
    }

    var isPast: Bool {
        daysLeft < 0
    }
}
