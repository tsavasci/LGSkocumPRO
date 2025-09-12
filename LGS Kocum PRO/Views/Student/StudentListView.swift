import SwiftUI
import SwiftData

struct StudentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.lastName) private var students: [Student]
    
    @State private var showingAddStudent = false
    
    var body: some View {
        NavigationStack {
            List {
                if students.isEmpty {
                    ContentUnavailableView("Öğrenci Bulunamadı",
                                        systemImage: "person.fill.questionmark",
                                        description: Text("Yeni öğrenci eklemek için + butonuna tıklayın"))
                } else {
                    ForEach(students) { student in
                        NavigationLink(destination: StudentDetailView(student: student)) {
                            VStack(alignment: .leading) {
                                Text(student.fullName)
                                    .font(.headline)
                                Text(student.school)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteStudents)
                }
            }
            .navigationTitle("Öğrencilerim")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddStudent = true }) {
                        Label("Öğrenci Ekle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddStudent) {
                AddStudentView()
            }
        }
    }
    
    private func deleteStudents(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(students[index])
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Student.self, configurations: config)
    
    // Add example students
    for i in 1...5 {
        let student = Student(
            firstName: "Öğrenci",
            lastName: "\(i)",
            school: "Örnek Okul",
            grade: 8,
            notes: "Örnek öğrenci"
        )
        container.mainContext.insert(student)
    }
    
    return StudentListView()
        .modelContainer(container)
}
