import Charts
import SwiftData
import SwiftUI

struct StudentDetailView: View {
    let student: Student
    @State private var selectedTab: Tab = .overview
    @State private var showingEditSheet = false

    enum Tab {
        case overview, practiceExams, questions, notes
    }

    var body: some View {
        VStack(spacing: 0) {
            // Student Info Header
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    Button("Düzenle") {
                        showingEditSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)

                StudentProfileImageView(student: student, size: 80, showBorder: true)

                Text(student.fullName)
                    .font(.title2.bold())

                if !student.school.isEmpty {
                    Text(student.school)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))

            // Tab Picker
            Picker("View", selection: $selectedTab) {
                Label("Genel Bakış", systemImage: "chart.bar").tag(Tab.overview)
                Label("Denemeler", systemImage: "doc.text").tag(Tab.practiceExams)
                Label("Sorular", systemImage: "questionmark.square").tag(Tab.questions)
                Label("Notlar", systemImage: "note.text").tag(Tab.notes)
            }
            .pickerStyle(.segmented)
            .padding()

            // Tab Content
            ScrollView {
                switch selectedTab {
                case .overview:
                    OverviewTab(student: student)
                case .practiceExams:
                    PracticeExamsTab(student: student)
                case .questions:
                    QuestionsTab(student: student)
                case .notes:
                    NotesTab(student: student)
                }
            }
        }
        .navigationTitle(student.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditStudentView(student: student)
        }
    }
}

// MARK: - Tab Views

struct OverviewTab: View {
    let student: Student

    // Computed properties for real statistics
    private var examCount: Int {
        student.practiceExams.count
    }

    private var averageScore: Double {
        guard !student.practiceExams.isEmpty else { return 0 }
        let totalScore = student.practiceExams.reduce(0) { $0 + $1.totalScore }
        return totalScore / Double(student.practiceExams.count)
    }

    private var totalQuestions: Int {
        // LGS'de toplam 90 soru var, her sınav için hesapla
        return examCount * 90
    }

    private var recentExams: [PracticeExam] {
        let sorted = student.practiceExams.sorted { $0.date > $1.date }
        return Array(sorted.prefix(5))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Stats Overview
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    StatCard(
                        value: "\(examCount)", label: "Deneme Sınavı", icon: "doc.text",
                        color: .blue)
                    StatCard(
                        value: "\(totalQuestions)", label: "Çözülen Soru", icon: "checkmark.circle",
                        color: .green)
                }

                HStack(spacing: 16) {
                    StatCard(
                        value: String(format: "%.0f", averageScore), label: "Ortalama Puan",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .purple)
                    StatCard(
                        value: examCount > 0 ? "\(examCount)" : "0",
                        label: "Toplam Sınav",
                        icon: "flame",
                        color: .orange)
                }
            }
            .padding(.horizontal)

            // Performance Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Puan Grafiği")
                    .font(.headline)
                    .padding(.horizontal)

                if recentExams.isEmpty {
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Henüz deneme sınavı yok")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    Chart {
                        ForEach(Array(recentExams.reversed().enumerated()), id: \.offset) {
                            index, exam in
                            LineMark(
                                x: .value("Sınav", index + 1),
                                y: .value("Puan", exam.totalScore)
                            )
                            .foregroundStyle(.blue)
                            .symbol(Circle().strokeBorder(lineWidth: 2))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }

            // Recent Activity
            VStack(alignment: .leading, spacing: 8) {
                Text("Son Deneme Sınavları")
                    .font(.headline)
                    .padding(.horizontal)

                if recentExams.isEmpty {
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                        Text("Henüz deneme sınavı yok")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(recentExams.prefix(3).enumerated()), id: \.offset) {
                            index, exam in
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exam.name)
                                        .font(.subheadline)

                                    Text(
                                        "\(daysAgo(from: exam.date)) • \(Int(exam.totalScore)) puan"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))

                            if index < min(recentExams.count, 3) - 1 {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }

            // Solved Questions Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Çözülen Sorular")
                    .font(.headline)
                    .padding(.horizontal)

                if questionsBySubject.isEmpty {
                    VStack {
                        Image(systemName: "questionmark.square")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                        Text("Henüz soru çözümü yok")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    let sortedSubjects = Array(questionsBySubject.keys.sorted())
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 12
                    ) {
                        ForEach(sortedSubjects, id: \.self) { subject in
                            SubjectQuestionCard(
                                subject: subject,
                                totalQuestions: questionsBySubject[subject] ?? 0,
                                dailyRate: questionRatesBySubject[subject] ?? 0
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding(.vertical)
    }

    // Helper computed properties for questions
    private var questionsBySubject: [String: Int] {
        var result: [String: Int] = [:]
        for performance in student.questionPerformances {
            result[performance.subject, default: 0] += performance.totalQuestions
        }
        return result
    }

    private var questionRatesBySubject: [String: Double] {
        var result: [String: Double] = [:]

        for (subject, totalQuestions) in questionsBySubject {
            let subjectPerformances = student.questionPerformances.filter { $0.subject == subject }

            guard !subjectPerformances.isEmpty else {
                result[subject] = 0
                continue
            }

            // Find first and last dates for this subject
            let dates = subjectPerformances.map { $0.date }.sorted()
            guard let firstDate = dates.first, let lastDate = dates.last else {
                result[subject] = Double(totalQuestions)
                continue
            }

            // Calculate days between first and last question solving
            let daysDifference =
                Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
            let totalDays = max(1, daysDifference + 1)  // +1 to include both start and end days

            result[subject] = Double(totalQuestions) / Double(totalDays)
        }

        return result
    }

    // Helper computed properties
    private var daysSinceFirstExam: Int {
        guard let firstExam = student.practiceExams.min(by: { $0.date < $1.date }) else { return 1 }
        let days =
            Calendar.current.dateComponents([.day], from: firstExam.date, to: Date()).day ?? 1
        return max(1, days)
    }

    // Helper function for date formatting
    private func daysAgo(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0

        if days == 0 {
            return "Bugün"
        } else if days == 1 {
            return "Dün"
        } else if days < 7 {
            return "\(days) gün önce"
        } else {
            let weeks = days / 7
            return "\(weeks) hafta önce"
        }
    }
}

struct PracticeExamsTab: View {
    let student: Student
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddExam = false
    @State private var showingEditExam = false
    @State private var examToEdit: PracticeExam?
    @State private var showingDeleteConfirmation = false
    @State private var examToDelete: PracticeExam?
    @State private var swipeOffsets: [UUID: CGFloat] = [:]

    @Query private var exams: [PracticeExam]

    init(student: Student) {
        self.student = student
        let studentID = student.id
        _exams = Query(
            filter: #Predicate<PracticeExam> { exam in
                exam.student?.id == studentID
            },
            sort: \.date,
            order: .reverse
        )
    }

    var body: some View {
        VStack {
            if exams.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "Henüz Deneme Sınavı Yok",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Öğrenci için yeni bir deneme sınavı ekleyin")
                    )
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(exams) { exam in
                            examCardWithSwipe(for: exam)
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddExam = true }) {
                    Label("Ekle", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExam) {
            AddPracticeExamView(student: student)
                .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: $showingEditExam) {
            if let examToEdit = examToEdit {
                EditPracticeExamView(student: student, exam: examToEdit)
                    .environment(\.modelContext, modelContext)
            }
        }
        .alert("Sınavı Sil", isPresented: $showingDeleteConfirmation) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                if let examToDelete = examToDelete {
                    deleteExam(examToDelete)
                    self.examToDelete = nil
                }
            }
        } message: {
            Text("Bu deneme sınavını kalıcı olarak silmek istediğinizden emin misiniz?")
        }
        .onAppear {
            print("🔄 PracticeExamsTab appeared with \(exams.count) exams")
        }
    }

    private func deleteExams(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let exam = exams[index]
                modelContext.delete(exam)
            }
            try? modelContext.save()
        }
    }

    private func deleteExam(_ exam: PracticeExam) {
        withAnimation {
            // Delete from context
            modelContext.delete(exam)
            try? modelContext.save()
        }
    }

    private func editExam(_ exam: PracticeExam) {
        examToEdit = exam
        showingEditExam = true
    }

    @ViewBuilder
    private func examCard(for exam: PracticeExam) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exam.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(exam.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Puan")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text("\(Int(exam.totalScore))")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                }

                Spacer()

                if !exam.notes.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Not")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(exam.notes)
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: 120)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private func examCardWithSwipe(for exam: PracticeExam) -> some View {
        ZStack {
            // Background action buttons (behind the card)
            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        editExam(exam)
                    } label: {
                        VStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                            Text("Düzenle")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                        .background(Color.blue)
                    }

                    Button {
                        examToDelete = exam
                        showingDeleteConfirmation = true
                    } label: {
                        VStack {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                            Text("Sil")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                        .background(Color.red)
                    }
                }
            }

            // Main card content (slides over the buttons)
            examCard(for: exam)
                .background(Color(.systemBackground))
                .offset(x: swipeOffset(for: exam))
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.width
                    if translation < 0 {
                        setSwipeOffset(for: exam, offset: max(translation, -160))
                    } else if translation > 0 {
                        setSwipeOffset(for: exam, offset: min(translation * 0.5, 0))
                    }
                }
                .onEnded { value in
                    let translation = value.translation.width
                    let velocity = value.velocity.width

                    withAnimation(.spring(response: 0.3)) {
                        if translation < -80 || velocity < -500 {
                            setSwipeOffset(for: exam, offset: -160)
                        } else {
                            setSwipeOffset(for: exam, offset: 0)
                        }
                    }
                }
        )
        .clipped()
    }

    private func swipeOffset(for exam: PracticeExam) -> CGFloat {
        swipeOffsets[exam.id] ?? 0
    }

    private func setSwipeOffset(for exam: PracticeExam, offset: CGFloat) {
        swipeOffsets[exam.id] = offset
    }
}

struct QuestionsTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddQuestion = false

    let student: Student

    private var sortedQuestions: [QuestionPerformance] {
        student.questionPerformances.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack {
            if sortedQuestions.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "Henüz Soru Çözümü Yok",
                        systemImage: "questionmark.square.dashed",
                        description: Text("Öğrenci için yeni bir soru çözümü ekleyin")
                    )
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedQuestions) { question in
                            questionCard(for: question)
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddQuestion = true }) {
                    Label("Ekle", systemImage: "plus")
                }
            }
        }
        .sheet(
            isPresented: $showingAddQuestion,
            onDismiss: {
                // Refresh will happen automatically via SwiftData
            }
        ) {
            AddQuestionPerformanceView(student: student)
                .environment(\.modelContext, modelContext)
        }
    }

    @ViewBuilder
    private func questionCard(for question: QuestionPerformance) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(question.subject)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(question.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Soru")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text("\(question.totalQuestions)")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                }

                Spacer()

                if question.timeInMinutes > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Süre")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text("\(question.timeInMinutes) dk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct NotesTab: View {
    let student: Student
    @State private var notes: String = ""

    var body: some View {
        VStack {
            TextEditor(text: $notes)
                .frame(minHeight: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding()
                .onAppear {
                    notes = student.notes
                }
                .onChange(of: notes) {
                    student.notes = notes
                }

            Spacer()
        }
    }
}

// MARK: - Helper Views

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SubjectQuestionCard: View {
    let subject: String
    let totalQuestions: Int
    let dailyRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subject)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Text("\(totalQuestions) soru")
                .font(.title2.bold())
                .foregroundStyle(.green)

            Text("\(String(format: "%.1f", dailyRate)) soru/gün")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    struct StudentDetailViewPreview: View {
        @State private var student: Student = {
            let student = Student(
                firstName: "Ahmet",
                lastName: "Yılmaz",
                school: "Örnek Ortaokulu",
                grade: 8,
                notes: "Matematikte iyi, fen derslerine ağırlık verilmeli."
            )

            // Örnek deneme sınavları
            let subjects = ["Matematik", "Fen Bilimleri", "Türkçe", "Sosyal Bilgiler"]
            for i in 1...5 {
                let exam = PracticeExam(
                    name: "LGS Deneme \(i)",
                    date: Calendar.current.date(byAdding: .day, value: -i * 7, to: Date())!,
                    totalScore: Double.random(in: 400...500),
                    notes: subjects.randomElement()! + " ağırlıklı"
                )
                student.practiceExams.append(exam)
            }

            return student
        }()

        var body: some View {
            NavigationStack {
                StudentDetailView(student: student)
            }
        }
    }

    return StudentDetailViewPreview()
        .modelContainer(
            for: [Student.self, PracticeExam.self, QuestionPerformance.self], inMemory: true)
}
