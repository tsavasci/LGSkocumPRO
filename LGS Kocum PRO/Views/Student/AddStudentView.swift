import SwiftData
import SwiftUI
import UIKit

struct AddStudentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var school = ""
    @State private var grade = 8
    @State private var branch = ""
    @State private var notes = ""
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profil Fotoğrafı")) {
                    HStack {
                        PhotoPickerView(selectedImage: $selectedImage)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profil Fotoğrafı")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Öğrencinin fotoğrafını ekleyin")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Temel Bilgiler")) {
                    TextField("Adı", text: $firstName)
                    TextField("Soyadı", text: $lastName)
                    TextField("Okul", text: $school)

                    HStack {
                        Picker("Sınıf", selection: $grade) {
                            ForEach(5...12, id: \.self) { grade in
                                Text("\(grade). Sınıf").tag(grade)
                            }
                        }
                        .pickerStyle(.menu)

                        TextField("Şube", text: $branch)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 60)
                            .textCase(.uppercase)
                            .multilineTextAlignment(.center)
                    }

                    if !branch.isEmpty {
                        Text("Sınıf: \(grade). Sınıf \(branch.uppercased())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
            branch: branch.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        // Set profile image if selected
        if let selectedImage = selectedImage {
            student.profileImage = selectedImage
        }

        // Manual students are offline (no Student App)
        student.connectionType = "offline"
        student.status = "solo"
        student.teacherID = FirestoreService.shared.currentTeacherID

        modelContext.insert(student)

        // Sync to Firebase for backup
        Task {
            do {
                try await FirestoreService.shared.syncStudentToFirestore(student)
                print("✅ Manuel öğrenci Firebase'e kaydedildi: \(student.fullName)")
            } catch {
                print("❌ Manuel öğrenci Firebase'e kaydedilemedi: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    AddStudentView()
        .modelContainer(for: Student.self, inMemory: true)
}
