//
//  ContentView.swift
//  LGS Kocum PRO
//
//  Created by Tamer Savaşcı on 11.09.2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            MainTabView()

            // In-app notification banner (üstte gösterilecek)
            InAppNotificationBanner()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                Student.self,
                PracticeExam.self,
                QuestionPerformance.self,
            ], inMemory: true)
}
