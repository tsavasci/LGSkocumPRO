//
//  LGS_Kocum_PROApp.swift
//  LGS Kocum PRO
//
//  Created by Tamer Savaşcı on 11.09.2025.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseMessaging
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Notification setup
        Task { @MainActor in
            NotificationService.shared.setup()
        }

        return true
    }

    // FCM Token registration
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("✅ [AppDelegate] APNS Token registered")
    }

    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [AppDelegate] Failed to register: \(error.localizedDescription)")
    }
}

@main
struct LGS_Kocum_PROApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var syncManager = FirestoreSyncManager.shared
    @StateObject private var authService = TeacherAuthService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Student.self,
            PracticeExam.self,
            QuestionPerformance.self,
            Teacher.self,
            PendingRequest.self,
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
            Group {
                if authService.isAuthenticated {
                    // Öğretmen giriş yapmış - Ana uygulamayı göster
                    ContentView()
                        .environmentObject(syncManager)
                        .onAppear {
                            // Uygulama açıldığında Firestore dinleyicilerini başlat
                            syncManager.startListening(modelContext: sharedModelContainer.mainContext)

                            // FCM Token al ve kaydet
                            Task {
                                await NotificationService.shared.getFCMToken()
                            }
                        }
                } else {
                    // Öğretmen giriş yapmamış - Onboarding göster
                    OnboardingContainerView()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
