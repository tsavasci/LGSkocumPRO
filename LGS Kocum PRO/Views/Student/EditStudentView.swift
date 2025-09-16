import SwiftData
import SwiftUI
import UIKit

struct EditStudentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let student: Student

    @State private var firstName: String
    @State private var lastName: String
    @State private var school: String
    @State private var grade: Int
    @State private var branch: String
    @State private var notes: String
    @State private var selectedImage: UIImage?

    init(student: Student) {
        self.student = student
        _firstName = State(initialValue: student.firstName)
        _lastName = State(initialValue: student.lastName)
        _school = State(initialValue: student.school)
        _grade = State(initialValue: student.grade)
        _branch = State(initialValue: student.branch)
        _notes = State(initialValue: student.notes)
        _selectedImage = State(initialValue: student.profileImage)
    }

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
                            Text("Öğrencinin fotoğrafını değiştirin")
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
            .navigationTitle("Öğrenci Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        updateStudent()
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }

    private func updateStudent() {
        student.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        student.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        student.school = school.trimmingCharacters(in: .whitespacesAndNewlines)
        student.grade = grade
        student.branch = branch.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        student.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        // Update profile image
        student.profileImage = selectedImage

        do {
            try modelContext.save()
        } catch {
            print("Failed to update student: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Student.self, configurations: config)

    let student = Student(
        firstName: "Ahmet",
        lastName: "Yılmaz",
        school: "Örnek Ortaokulu",
        grade: 8,
        branch: "A",
        notes: "Örnek not"
    )

    return NavigationStack {
        EditStudentView(student: student)
    }
    .modelContainer(container)
}
