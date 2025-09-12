//
//  ContentView.swift
//  LGS Kocum PRO
//
//  Created by Tamer Savaşcı on 11.09.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Student.self,
            PracticeExam.self,
            QuestionPerformance.self
        ], inMemory: true)
}
