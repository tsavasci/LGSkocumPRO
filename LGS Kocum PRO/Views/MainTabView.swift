import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.lastName) private var students: [Student]
    
    var body: some View {
        TabView {
            StudentListView()
                .tabItem {
                    Label("Öğrenciler", systemImage: "person.3.fill")
                }
            
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
        .modelContainer(for: [Student.self, PracticeExam.self, QuestionPerformance.self], inMemory: true)
}
