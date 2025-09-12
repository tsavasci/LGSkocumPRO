//
//  LGS_Kocum_PROApp.swift
//  LGS Kocum PRO
//
//  Created by Tamer Savaşcı on 11.09.2025.
//

import SwiftUI
import SwiftData

@main
struct LGS_Kocum_PROApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Student.self,
            PracticeExam.self,
            QuestionPerformance.self,
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
