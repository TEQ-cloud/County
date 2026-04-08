//
//  CountdownEntry.swift
//  County
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
    static let widgetBundleID = "net.teqcloud.County.CountyWidget"

    /// Path inside the widget's sandbox container (Application Support)
    private static var widgetContainerFileURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home
            .appendingPathComponent("Library/Containers")
            .appendingPathComponent(widgetBundleID)
            .appendingPathComponent("Data/Library/Application Support/County")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("countdowns.json")
    }

    static func save(_ countdowns: [CountdownEntry]) {
        guard let data = try? JSONEncoder().encode(countdowns) else { return }
        try? data.write(to: widgetContainerFileURL, options: .atomic)
    }

    static func load() -> [CountdownEntry] {
        guard let data = try? Data(contentsOf: widgetContainerFileURL),
              let entries = try? JSONDecoder().decode([CountdownEntry].self, from: data) else {
            return []
        }
        return entries
    }
}
