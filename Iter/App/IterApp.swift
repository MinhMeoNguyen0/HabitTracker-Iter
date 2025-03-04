//
//  IterApp.swift
//  Iter
//
//  Created by Minh Nguyễn on 2/11/25.
//

/// The main application entry point for Iter.
/// This app uses SwiftData for persistence and SwiftUI for the user interface. 
import SwiftUI
import SwiftData

@main
struct IterApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: Habit.self, HabitCompletion.self, configurations: config)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(modelContext: container.mainContext)
                .modelContainer(container)
        }
    }
}
