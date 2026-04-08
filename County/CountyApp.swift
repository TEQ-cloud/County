//
//  CountyApp.swift
//  County
//
//  Created by Quinten de Haard on 19/03/2026.
//

import SwiftUI
import SwiftData

@main
struct CountyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Countdown.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
