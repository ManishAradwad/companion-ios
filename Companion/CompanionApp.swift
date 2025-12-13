//
//  CompanionApp.swift
//  Companion
//
//  Created by Manish Aradwad on 12/2/25.
//

import SwiftData
import SwiftUI

@main
struct CompanionApp: App {
    // define persistable model types in this ModelContainer
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChatSession.self,
            ChatMessage.self,
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
            MainTabView()
                .environment(DeviceStat())
        }
        .modelContainer(sharedModelContainer)
    }
}
