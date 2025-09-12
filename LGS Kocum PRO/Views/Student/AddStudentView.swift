import SwiftUI
import SwiftData

struct AddStudentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var school = ""
    @State private var grade = 8
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Temel Bilgiler")) {
                    TextField("Adı", text: $firstName)
                    TextField("Soyadı", text: $lastName)
                    TextField("Okul", text: $school)
                    Picker("Sınıf", selection: $grade) {
                        ForEach(5...12, id: \.self) { grade in
                            Text("\(grade). Sınıf").tag(grade)
                        }
                    }
                }
                
                Section(header: Text("Notlar")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Yeni Öğrenci")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        addStudent()
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
    
    private func addStudent() {
        let student = Student(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            school: school.trimmingCharacters(in: .whitespacesAndNewlines),
            grade: grade,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(student)
    }
}

#Preview {
    AddStudentView()
        .modelContainer(for: Student.self, inMemory: true)
}
