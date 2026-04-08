//
//  CountdownEntry.swift
//  CountyWidget
//
//  Created by Quinten de Haard on 19/03/2026.
//

import Foundation

struct CountdownEntry: Codable, Identifiable {
    var id: String { name + date.timeIntervalSince1970.description }
    let name: String
    let date: Date

    var daysLeft: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: now, to: target)
        return components.day ?? 0
    }
}

enum SharedData {
    /// Widget reads from its own Application Support (sandbox remaps this to its container)
    private static var localFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("County")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("countdowns.json")
    }

    static func save(_ countdowns: [CountdownEntry]) {
        // Not used by widget
    }

    static func load() -> [CountdownEntry] {
        guard let data = try? Data(contentsOf: localFileURL),
              let entries = try? JSONDecoder().decode([CountdownEntry].self, from: data) else {
            return []
        }
        return entries
    }
}
