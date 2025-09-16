import SwiftData
import SwiftUI

struct StudentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.lastName) private var students: [Student]

    @State private var showingAddStudent = false
    @State private var selectedSchool: String = "Tüm Okullar"
    @State private var selectedGrade: String = "Tüm Sınıflar"
    @State private var selectedBranch: String = "Tüm Şubeler"
    @State private var showingFilters = false
    @State private var searchText = ""

    // MARK: - Computed Properties

    private var uniqueSchools: [String] {
        let schools = Set(students.compactMap { $0.school.isEmpty ? nil : $0.school })
        return Array(schools).sorted()
    }

    private var uniqueGrades: [String] {
        let grades = Set(students.map { "\($0.grade). Sınıf" })
        return Array(grades).sorted()
    }

    private var uniqueBranches: [String] {
        let branches = Set(students.compactMap { $0.branch.isEmpty ? nil : $0.branch })
        return Array(branches).sorted()
    }

    private var filteredStudents: [Student] {
        students.filter { student in
            let matchesSearch =
                searchText.isEmpty || student.fullName.localizedCaseInsensitiveContains(searchText)
                || student.school.localizedCaseInsensitiveContains(searchText)

            let matchesSchool = selectedSchool == "Tüm Okullar" || student.school == selectedSchool

            let matchesGrade =
                selectedGrade == "Tüm Sınıflar" || "\(student.grade). Sınıf" == selectedGrade

            let matchesBranch =
                selectedBranch == "Tüm Şubeler" || student.branch == selectedBranch

            return matchesSearch && matchesSchool && matchesGrade && matchesBranch
        }
    }

    private var hasActiveFilters: Bool {
        selectedSchool != "Tüm Okullar" || selectedGrade != "Tüm Sınıflar"
            || selectedBranch != "Tüm Şubeler" || !searchText.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Header
                if hasActiveFilters || showingFilters {
                    filterHeader
                }

                // Student List
                List {
                    if filteredStudents.isEmpty {
                        if students.isEmpty {
                            ContentUnavailableView(
                                "Öğrenci Bulunamadı",
                                systemImage: "person.fill.questionmark",
                                description: Text("Yeni öğrenci eklemek için + butonuna tıklayın")
                            )
                        } else {
                            ContentUnavailableView(
                                "Filtre Sonucu Bulunamadı",
                                systemImage: "magnifyingglass",
                                description: Text("Farklı filtre seçenekleri deneyin")
                            )
                        }
                    } else {
                        // Statistics Header
                        if hasActiveFilters {
                            Section {
                                HStack {
                                    Image(systemName: "person.3.fill")
                                        .foregroundStyle(.blue)
                                    Text("\(filteredStudents.count) öğrenci gösteriliyor")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Button("Temizle") {
                                        clearFilters()
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        // Student Cards
                        ForEach(filteredStudents) { student in
                            NavigationLink(destination: StudentDetailView(student: student)) {
                                StudentCard(student: student)
                            }
                        }
                        .onDelete(perform: deleteStudents)
                    }
                }
            }
            .navigationTitle("Öğrencilerim (\(students.count))")
            .searchable(text: $searchText, prompt: "Öğrenci veya okul ara...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring()) {
                            showingFilters.toggle()
                        }
                    }) {
                        Label(
                            "Filtreler",
                            systemImage: hasActiveFilters
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease.circle")
                    }
                    .foregroundStyle(hasActiveFilters ? .blue : .primary)
                }

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

    // MARK: - Filter Header View

    private var filterHeader: some View {
        VStack(spacing: 12) {
            // School Filter
            HStack {
                Image(systemName: "building.2")
                    .foregroundStyle(.blue)
                    .frame(width: 20)

                Menu {
                    Button("Tüm Okullar") { selectedSchool = "Tüm Okullar" }

                    Divider()

                    ForEach(uniqueSchools, id: \.self) { school in
                        Button(school) { selectedSchool = school }
                    }
                } label: {
                    HStack {
                        Text(selectedSchool)
                            .foregroundStyle(
                                selectedSchool == "Tüm Okullar" ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }

            // Grade Filter
            HStack {
                Image(systemName: "graduationcap")
                    .foregroundStyle(.green)
                    .frame(width: 20)

                Menu {
                    Button("Tüm Sınıflar") { selectedGrade = "Tüm Sınıflar" }

                    Divider()

                    ForEach(uniqueGrades, id: \.self) { grade in
                        Button(grade) { selectedGrade = grade }
                    }
                } label: {
                    HStack {
                        Text(selectedGrade)
                            .foregroundStyle(
                                selectedGrade == "Tüm Sınıflar" ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }

            // Branch Filter
            HStack {
                Image(systemName: "square.grid.3x3")
                    .foregroundStyle(.orange)
                    .frame(width: 20)

                Menu {
                    Button("Tüm Şubeler") { selectedBranch = "Tüm Şubeler" }

                    Divider()

                    ForEach(uniqueBranches, id: \.self) { branch in
                        Button(branch) { selectedBranch = branch }
                    }
                } label: {
                    HStack {
                        Text(selectedBranch)
                            .foregroundStyle(
                                selectedBranch == "Tüm Şubeler" ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Helper Methods

    private func clearFilters() {
        withAnimation {
            selectedSchool = "Tüm Okullar"
            selectedGrade = "Tüm Sınıflar"
            selectedBranch = "Tüm Şubeler"
            searchText = ""
        }
    }

    private func deleteStudents(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let studentToDelete = filteredStudents[index]
                if let originalIndex = students.firstIndex(where: { $0.id == studentToDelete.id }) {
                    modelContext.delete(students[originalIndex])
                }
            }
        }
    }
}

// MARK: - Student Card View

struct StudentCard: View {
    let student: Student

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Student Avatar
                StudentProfileImageView(student: student, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(student.fullName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        if !student.school.isEmpty {
                            Image(systemName: "building.2")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(student.school)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if !student.school.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Image(systemName: "graduationcap")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if !student.branch.isEmpty {
                            Text("\(student.grade). Sınıf \(student.branch)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(student.grade). Sınıf")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Quick Stats
                VStack(alignment: .trailing, spacing: 2) {
                    if student.practiceExams.count > 0 {
                        Text("\(student.practiceExams.count) sınav")
                            .font(.caption)
                            .foregroundStyle(.blue)

                        if student.currentAverageScore > 0 {
                            Text("\(Int(student.currentAverageScore)) ort.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Sınav yok")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Progress indicator
                    if student.targetTotalScore > 0 && student.currentAverageScore > 0 {
                        let progress = student.scoreProgress
                        let progressColor: Color =
                            progress >= 0.8 ? .green : progress >= 0.6 ? .orange : .red

                        HStack(spacing: 4) {
                            Circle()
                                .fill(progressColor)
                                .frame(width: 8, height: 8)
                            Text("\(Int(progress * 100))%")
                                .font(.caption2)
                                .foregroundStyle(progressColor)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Student.self, configurations: config)

    // Add example students with variety
    let schools = ["Atatürk Ortaokulu", "Fatih Ortaokulu", "Cumhuriyet Ortaokulu"]
    let branches = ["A", "B", "C"]
    let names = [
        ("Ahmet", "Yılmaz"), ("Ayşe", "Demir"), ("Mehmet", "Kaya"), ("Zeynep", "Öztürk"),
        ("Can", "Arslan"),
    ]

    for i in 0..<5 {
        let student = Student(
            firstName: names[i].0,
            lastName: names[i].1,
            school: schools[i % schools.count],
            grade: i % 2 == 0 ? 8 : 7,
            branch: branches[i % branches.count],
            notes: "Örnek öğrenci"
        )
        container.mainContext.insert(student)
    }

    return StudentListView()
        .modelContainer(container)
}
