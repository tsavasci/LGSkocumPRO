import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.lastName) private var students: [Student]
    @StateObject private var syncManager = FirestoreSyncManager.shared

    var body: some View {
        TabView {
            if !students.isEmpty {
                MentorDashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
                    }
            }

            StudentListView()
                .tabItem {
                    Label("Öğrenciler", systemImage: "person.3.fill")
                }

            PendingRequestsView()
                .tabItem {
                    Label("İstekler", systemImage: "person.badge.clock.fill")
                }
                .badge(syncManager.pendingRequestsCount)

            if !students.isEmpty {
                AnalyticsView()
                    .tabItem {
                        Label("Analizler", systemImage: "chart.bar.fill")
                    }
            } else {
                ContentUnavailableView(
                    "Veri Yok",
                    systemImage: "chart.bar.fill",
                    description: Text("Analizleri görmek için öğrenci ekleyin")
                )
                .tabItem {
                    Label("Analizler", systemImage: "chart.bar.fill")
                }
            }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(
            for: [Student.self, PracticeExam.self, QuestionPerformance.self], inMemory: true)
}
