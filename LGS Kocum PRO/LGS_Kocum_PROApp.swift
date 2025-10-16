//
//  LGS_Kocum_PROApp.swift
//  LGS Kocum PRO
//
//  Created by Tamer Savaşcı on 11.09.2025.
//

import SwiftUI
import SwiftData
import FirebaseCore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct LGS_Kocum_PROApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var syncManager = FirestoreSyncManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Student.self,
            PracticeExam.self,
            QuestionPerformance.self,
            Teacher.self,
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
                .environmentObject(syncManager)
                .onAppear {
                    // Uygulama açıldığında Firestore dinleyicilerini başlat
                    syncManager.startListening(modelContext: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
