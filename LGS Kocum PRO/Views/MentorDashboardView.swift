import Charts
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MentorDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.lastName) private var students: [Student]

    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingGoalsSheet = false
    @State private var selectedStudentForGoals: Student?
    @State private var showingAddStudent = false
    @State private var showingReportOptions = false

    enum TimeRange: String, CaseIterable, Identifiable {
        case day = "Bugün"
        case week = "Bu Hafta"
        case month = "Bu Ay"

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Stats Header
                    VStack(spacing: 16) {
                        HStack {
                            Text("Mentor Dashboard")
                                .font(.title.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Picker("Zaman", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .padding(.horizontal)

                        // Quick Stats Cards
                        HStack(spacing: 12) {
                            DashboardCard(
                                title: "Toplam Öğrenci",
                                value: "\(students.count)",
                                icon: "person.3.fill",
                                color: .blue
                            )

                            DashboardCard(
                                title: "Aktif Öğrenci",
                                value: "\(activeStudentsCount)",
                                icon: "figure.walk",
                                color: .green
                            )

                            DashboardCard(
                                title: "Uyarı",
                                value: "\(warningStudentsCount)",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Student Activity Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Öğrenci Durumu")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVStack(spacing: 8) {
                            ForEach(students) { student in
                                StudentStatusCard(
                                    student: student,
                                    timeRange: selectedTimeRange,
                                    onSetGoals: {
                                        selectedStudentForGoals = student
                                        showingGoalsSheet = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Performance Summary Chart
                    if !students.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Genel Performans Trendi")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart {
                                ForEach(recentPerformanceData, id: \.date) { data in
                                    LineMark(
                                        x: .value("Tarih", data.date),
                                        y: .value("Ortalama", data.averageScore)
                                    )
                                    .foregroundStyle(.blue)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hızlı İşlemler")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ], spacing: 12
                        ) {
                            QuickActionButton(
                                title: "Yeni Öğrenci",
                                icon: "person.badge.plus",
                                color: .blue
                            ) {
                                showingAddStudent = true
                            }

                            QuickActionButton(
                                title: "Rapor Oluştur",
                                icon: "doc.text.fill",
                                color: .purple
                            ) {
                                showingReportOptions = true
                            }

                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .refreshable {
                refreshDashboardData()
            }
            .fullScreenCover(isPresented: $showingGoalsSheet) {
                Group {
                    if let student = selectedStudentForGoals {
                        SetGoalsView(student: student)
                            .environment(\.modelContext, modelContext)
                    } else {
                        EmptyView()
                        NavigationStack {
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)

                                Text("Bir Hata Oluştu")
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                Text("Öğrenci bilgileri yüklenemedi. Lütfen tekrar deneyin.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button("Kapat") {
                                    showingGoalsSheet = false
                                    selectedStudentForGoals = nil
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .navigationTitle("Hata")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingAddStudent) {
                AddStudentView()
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showingReportOptions) {
                ReportOptionsView(students: students)
                    .environment(\.modelContext, modelContext)
            }
        }
    }

    // MARK: - Computed Properties

    private var activeStudentsCount: Int {
        students.filter { student in
            hasRecentActivity(student: student, timeRange: selectedTimeRange)
        }.count
    }

    private var warningStudentsCount: Int {
        students.filter { student in
            needsAttention(student: student)
        }.count
    }

    private var recentPerformanceData: [PerformanceDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var data: [PerformanceDataPoint] = []

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let dayExams = students.flatMap { $0.practiceExams }
                .filter { calendar.isDate($0.date, inSameDayAs: date) }

            let average: Double
            if dayExams.isEmpty {
                average = 0
            } else {
                let total = dayExams.map { $0.totalScore }.reduce(0, +)
                let count = Double(dayExams.count)
                average = count > 0 ? total / count : 0
            }

            // Ensure average is not NaN or infinite
            let safeAverage = average.isFinite ? average : 0

            data.append(PerformanceDataPoint(date: date, averageScore: safeAverage))
        }

        return data.reversed()
    }

    // MARK: - Data Refresh Methods

    private func refreshDashboardData() {
        // Force SwiftData to refresh by touching the modelContext
        try? modelContext.save()

        // Force refresh of all students' computed properties
        for student in students {
            student.objectWillChange.send()
        }
    }

    // MARK: - Helper Functions

    private func hasRecentActivity(student: Student, timeRange: TimeRange) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        let cutoffDate: Date
        switch timeRange {
        case .day:
            cutoffDate = calendar.startOfDay(for: now)
        case .week:
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }

        return student.practiceExams.contains { $0.date >= cutoffDate }
            || student.questionPerformances.contains { $0.date >= cutoffDate }
    }

    private func needsAttention(student: Student) -> Bool {
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()

        let hasRecentPracticeExam = student.practiceExams.contains { $0.date >= threeDaysAgo }
        let hasRecentQuestions = student.questionPerformances.contains { $0.date >= threeDaysAgo }

        return !hasRecentPracticeExam && !hasRecentQuestions
    }
}

// MARK: - Supporting Views

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StudentStatusCard: View {
    let student: Student
    let timeRange: MentorDashboardView.TimeRange
    let onSetGoals: () -> Void

    private var activityStatus: (status: String, color: Color, icon: String) {
        let calendar = Calendar.current
        let now = Date()

        let cutoffDate: Date
        switch timeRange {
        case .day:
            cutoffDate = calendar.startOfDay(for: now)
        case .week:
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }

        let recentPracticeExams = student.practiceExams.filter { $0.date >= cutoffDate }
        let recentQuestions = student.questionPerformances.filter { $0.date >= cutoffDate }

        let totalActivity = recentPracticeExams.count + recentQuestions.count

        if totalActivity == 0 {
            return ("Pasif", .red, "exclamationmark.circle.fill")
        } else if totalActivity < 3 {
            return ("Az Aktif", .orange, "minus.circle.fill")
        } else {
            return ("Aktif", .green, "checkmark.circle.fill")
        }
    }

    private var lastActivity: String {
        let allActivities =
            (student.practiceExams.map { $0.date } + student.questionPerformances.map { $0.date })
            .sorted { $0 > $1 }

        guard let lastDate = allActivities.first else { return "Hiç" }

        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

        if days == 0 {
            return "Bugün"
        } else if days == 1 {
            return "Dün"
        } else {
            return "\(days) gün önce"
        }
    }

    var body: some View {
        NavigationLink(destination: StudentDetailView(student: student)) {
            HStack(spacing: 12) {
                // Student Avatar
                StudentProfileImageView(student: student, size: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(student.fullName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    if !student.branch.isEmpty {
                        Text("\(student.school) • \(student.grade). Sınıf \(student.branch)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(student.school) • \(student.grade). Sınıf")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Son aktivite: \(lastActivity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: activityStatus.icon)
                            .foregroundStyle(activityStatus.color)
                        Text(activityStatus.status)
                            .font(.caption.bold())
                            .foregroundStyle(activityStatus.color)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        if let avgScore = averageScore {
                            Text("\(Int(avgScore)) puan ort.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if student.targetTotalScore > 0 {
                            Text("Hedef: \(Int(student.targetTotalScore))")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }

                    Button(action: onSetGoals) {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }

    private var averageScore: Double? {
        guard !student.practiceExams.isEmpty else { return nil }
        return student.practiceExams.map { $0.totalScore }.reduce(0, +)
            / Double(student.practiceExams.count)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)

                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color.gradient)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct PerformanceDataPoint {
    let date: Date
    let averageScore: Double
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Student.self, PracticeExam.self, QuestionPerformance.self,
        configurations: config
    )

    // Add example data
    for i in 1...5 {
        let student = Student(
            firstName: ["Ahmet", "Ayşe", "Mehmet", "Fatma", "Ali"][i - 1],
            lastName: "Öğrenci \(i)",
            school: "Örnek Ortaokulu",
            grade: 8
        )

        // Add practice exams
        for j in 1...3 {
            let exam = PracticeExam(
                name: "Deneme \(j)",
                date: Calendar.current.date(byAdding: .day, value: -j, to: Date())!,
                totalScore: Double.random(in: 350...480),
                notes: ""
            )
            student.practiceExams.append(exam)
        }

        container.mainContext.insert(student)
    }

    return MentorDashboardView()
        .modelContainer(container)
}

struct SetGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let student: Student

    @State private var targetTotalScore: String
    @State private var targetTurkceNet: String
    @State private var targetMatematikNet: String
    @State private var targetFenNet: String
    @State private var targetSosyalNet: String
    @State private var targetDinNet: String
    @State private var targetIngilizceNet: String

    init(student: Student) {
        self.student = student
        _targetTotalScore = State(initialValue: String(format: "%.0f", student.targetTotalScore))
        _targetTurkceNet = State(initialValue: String(format: "%.0f", student.targetTurkceNet))
        _targetMatematikNet = State(
            initialValue: String(format: "%.0f", student.targetMatematikNet))
        _targetFenNet = State(initialValue: String(format: "%.0f", student.targetFenNet))
        _targetSosyalNet = State(initialValue: String(format: "%.0f", student.targetSosyalNet))
        _targetDinNet = State(initialValue: String(format: "%.0f", student.targetDinNet))
        _targetIngilizceNet = State(
            initialValue: String(format: "%.0f", student.targetIngilizceNet))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Öğrenci Bilgileri")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(student.fullName)
                            .font(.headline)

                        if !student.school.isEmpty {
                            if !student.branch.isEmpty {
                                Text(
                                    "\(student.school) • \(student.grade). Sınıf \(student.branch)"
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            } else {
                                Text("\(student.school) • \(student.grade). Sınıf")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            if !student.branch.isEmpty {
                                Text("\(student.grade). Sınıf \(student.branch)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(student.grade). Sınıf")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Genel Hedef")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Hedef Puan")
                            Spacer()
                            TextField("400", text: $targetTotalScore)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        if student.practiceExams.count > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Mevcut Ortalama:")
                                    Spacer()
                                    Text("\(Int(student.currentAverageScore)) puan")
                                        .foregroundColor(.blue)
                                }
                                .font(.caption)

                                let progressValue =
                                    student.scoreProgress.isFinite ? student.scoreProgress : 0
                                ProgressView(value: progressValue)
                                    .progressViewStyle(
                                        LinearProgressViewStyle(tint: progressColor(progressValue))
                                    )
                                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            }
                        }
                    }
                }

                Section(header: Text("Ders Bazlı Net Hedefleri")) {
                    GoalRow(
                        subject: "Türkçe", target: $targetTurkceNet,
                        current: student.averageTurkceNet, maxNet: 20)
                    GoalRow(
                        subject: "Matematik", target: $targetMatematikNet,
                        current: student.averageMatematikNet, maxNet: 20)
                    GoalRow(
                        subject: "Fen Bilimleri", target: $targetFenNet,
                        current: student.averageFenNet, maxNet: 20)
                    GoalRow(
                        subject: "Sosyal Bilgiler", target: $targetSosyalNet,
                        current: student.averageSosyalNet, maxNet: 10)
                    GoalRow(
                        subject: "Din Kültürü", target: $targetDinNet,
                        current: student.averageDinNet, maxNet: 10)
                    GoalRow(
                        subject: "İngilizce", target: $targetIngilizceNet,
                        current: student.averageIngilizceNet, maxNet: 10)
                }
            }
            .navigationTitle("Hedef Belirle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveGoals()
                    }
                }
            }
        }
    }

    private func progressColor(_ progress: Double) -> Color {
        switch progress {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        case 0.8..<0.95: return .yellow
        default: return .green
        }
    }

    private func saveGoals() {
        student.targetTotalScore = Double(targetTotalScore) ?? 400
        student.targetTurkceNet = Double(targetTurkceNet) ?? 15
        student.targetMatematikNet = Double(targetMatematikNet) ?? 15
        student.targetFenNet = Double(targetFenNet) ?? 15
        student.targetSosyalNet = Double(targetSosyalNet) ?? 8
        student.targetDinNet = Double(targetDinNet) ?? 8
        student.targetIngilizceNet = Double(targetIngilizceNet) ?? 8

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving goals: \(error)")
        }
    }

}

struct ReportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let students: [Student]

    @State private var reportType: ReportType = .summary
    @State private var timeRange: TimeRange = .month
    @State private var selectedStudents: Set<Student> = []
    @State private var includeCharts = true
    @State private var isGenerating = false
    @State private var generatedReportURL: URL?

    enum ReportType: String, CaseIterable, Identifiable {
        case summary = "Özet Rapor"
        case detailed = "Detaylı Rapor"
        case performance = "Performans Analizi"
        case progress = "İlerleme Raporu"

        var id: String { self.rawValue }
    }

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Son 7 Gün"
        case month = "Son 30 Gün"
        case quarter = "Son 3 Ay"
        case all = "Tüm Zamanlar"

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rapor Türü")) {
                    Picker("Tür", selection: $reportType) {
                        ForEach(ReportType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Zaman Aralığı")) {
                    Picker("Aralık", selection: $timeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }

                Section(header: Text("Öğrenci Seçimi")) {
                    NavigationLink("Öğrencileri Seç (\(selectedStudents.count) seçili)") {
                        StudentSelectionForReportView(
                            students: students,
                            selectedStudents: $selectedStudents
                        )
                    }

                    if selectedStudents.isEmpty {
                        Text("Tüm öğrenciler dahil edilecek")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Seçenekler")) {
                    Toggle("Grafikleri Dahil Et", isOn: $includeCharts)
                }

                Section {
                    Button("Rapor Oluştur") {
                        generateReport()
                    }
                    .disabled(isGenerating)
                    .frame(maxWidth: .infinity)

                    if isGenerating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Rapor hazırlanıyor...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Rapor Oluştur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: .constant(generatedReportURL != nil),
                document: ReportDocument(url: generatedReportURL),
                contentType: .pdf,
                defaultFilename:
                    "LGS_Rapor_\(DateFormatter.filenameDateFormatter.string(from: Date()))"
            ) { result in
                generatedReportURL = nil
                isGenerating = false
                switch result {
                case .success(let url):
                    print("Rapor başarıyla oluşturuldu: \(url)")
                    dismiss()
                case .failure(let error):
                    print("Rapor oluşturma hatası: \(error.localizedDescription)")
                }
            }
        }
    }

    private func generateReport() {
        isGenerating = true

        Task {
            do {
                let studentsToReport = selectedStudents.isEmpty ? students : Array(selectedStudents)
                let url = try await generateReportFile(
                    students: studentsToReport,
                    type: reportType,
                    timeRange: timeRange,
                    includeCharts: includeCharts
                )

                await MainActor.run {
                    generatedReportURL = url
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    print("Rapor oluşturma hatası: \(error.localizedDescription)")
                }
            }
        }
    }

    private func generateReportFile(
        students: [Student],
        type: ReportType,
        timeRange: TimeRange,
        includeCharts: Bool
    ) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
            0]
        let fileName =
            "LGS_\(type.rawValue.replacingOccurrences(of: " ", with: "_"))_\(DateFormatter.filenameDateFormatter.string(from: Date())).pdf"
        let fileURL = documentsPath.appendingPathComponent(fileName)

        let reportContent = generateReportContent(
            students: students,
            type: type,
            timeRange: timeRange,
            includeCharts: includeCharts
        )

        // Simple text-based PDF for now (in a real app, you'd use PDFKit)
        try reportContent.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    private func generateReportContent(
        students: [Student],
        type: ReportType,
        timeRange: TimeRange,
        includeCharts: Bool
    ) -> String {
        var content = """
            LGS KOÇUM PRO - \(type.rawValue.uppercased())
            ================================

            Oluşturulma Tarihi: \(DateFormatter.displayDateFormatter.string(from: Date()))
            Zaman Aralığı: \(timeRange.rawValue)
            Öğrenci Sayısı: \(students.count)

            """

        switch type {
        case .summary:
            content += generateSummaryReport(students: students)
        case .detailed:
            content += generateDetailedReport(students: students)
        case .performance:
            content += generatePerformanceReport(students: students)
        case .progress:
            content += generateProgressReport(students: students)
        }

        content += """

            ================================
            Bu rapor LGS Koçum PRO ile oluşturulmuştur.
            © 2025 Tüm Hakları Saklıdır
            """

        return content
    }

    private func generateSummaryReport(students: [Student]) -> String {
        let totalExams = students.reduce(0) { $0 + $1.practiceExams.count }
        let avgScore =
            students.compactMap { $0.currentAverageScore }.reduce(0, +)
            / Double(max(students.count, 1))

        return """
            GENEL ÖZET
            ==========

            Toplam Sınav: \(totalExams)
            Ortalama Puan: \(String(format: "%.1f", avgScore))

            ÖĞRENCİ PERFORMANSLARI:
            \(students.map { student in
                let examCount = student.practiceExams.count
                let avgScore = student.currentAverageScore
                return "• \(student.fullName): \(examCount) sınav, \(String(format: "%.1f", avgScore)) puan ort."
            }.joined(separator: "\n"))

            """
    }

    private func generateDetailedReport(students: [Student]) -> String {
        var content = "DETAYLI RAPOR\n=============\n\n"

        for student in students {
            content += """
                ÖĞRENCİ: \(student.fullName)
                Okul: \(student.school)
                Sınıf: \(student.grade)
                Hedef Puan: \(student.targetTotalScore)

                SINAV GEÇMİŞİ:
                """

            for exam in student.practiceExams.sorted(by: { $0.date > $1.date }) {
                content +=
                    "\n• \(exam.name): \(exam.totalScore) puan (\(DateFormatter.shortDateFormatter.string(from: exam.date)))"
            }

            content += """

                NET ORTALAMALARI:
                • Türkçe: \(String(format: "%.1f", student.averageTurkceNet))
                • Matematik: \(String(format: "%.1f", student.averageMatematikNet))
                • Fen: \(String(format: "%.1f", student.averageFenNet))
                • Sosyal: \(String(format: "%.1f", student.averageSosyalNet))
                • Din: \(String(format: "%.1f", student.averageDinNet))
                • İngilizce: \(String(format: "%.1f", student.averageIngilizceNet))

                ================================

                """
        }

        return content
    }

    private func generatePerformanceReport(students: [Student]) -> String {
        return """
            PERFORMANS ANALİZİ
            ==================

            \(students.map { student in
            let progress = student.scoreProgress * 100
            let status = progress >= 80 ? "HEDEF ÜZERİNDE" :
                        progress >= 60 ? "HEDEF YAKLAŞIYOR" : "HEDEF ALTINDA"

            return """
                \(student.fullName):
                • Hedef İlerleme: %\(String(format: "%.1f", progress))
                • Durum: \(status)
                • Son 3 Sınav Ortalaması: \(String(format: "%.1f", student.practiceExams.suffix(3).map { $0.totalScore }.reduce(0, +) / Double(max(student.practiceExams.suffix(3).count, 1))))
                """
            }.joined(separator: "\n\n"))

            """
    }

    private func generateProgressReport(students: [Student]) -> String {
        return """
            İLERLEME RAPORU
            ===============

            \(students.map { student in
            let examCount = student.practiceExams.count
            let recentExams = student.practiceExams.suffix(5)
            let trend = recentExams.count > 1 ?
                (recentExams.last!.totalScore > recentExams.first!.totalScore ? "ARTIŞ" : "AZALIŞ") : "YETERSİZ VERİ"

            return """
                \(student.fullName):
                • Toplam Sınav: \(examCount)
                • Trend: \(trend)
                • En Yüksek Puan: \(student.practiceExams.map { $0.totalScore }.max() ?? 0)
                • En Son Puan: \(student.practiceExams.last?.totalScore ?? 0)
                """
            }.joined(separator: "\n\n"))

            """
    }
}

struct StudentSelectionForReportView: View {
    let students: [Student]
    @Binding var selectedStudents: Set<Student>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(students) { student in
            HStack {
                Text(student.fullName)
                Spacer()
                if selectedStudents.contains(where: { $0.id == student.id }) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let existingStudent = selectedStudents.first(where: { $0.id == student.id }) {
                    selectedStudents.remove(existingStudent)
                } else {
                    selectedStudents.insert(student)
                }
            }
        }
        .navigationTitle("Öğrenci Seç")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Tamam") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button(selectedStudents.isEmpty ? "Tümünü Seç" : "Tümünü Kaldır") {
                    if selectedStudents.isEmpty {
                        selectedStudents = Set(students)
                    } else {
                        selectedStudents.removeAll()
                    }
                }
            }
        }
    }
}

struct ReportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    var url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url,
            let data = try? Data(contentsOf: url)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

struct GoalRow: View {
    let subject: String
    @Binding var target: String
    let current: Double
    let maxNet: Int

    private var progress: Double {
        guard let targetValue = Double(target), targetValue > 0, current > 0 else { return 0 }
        let prog = current / targetValue
        return prog.isFinite ? min(1.0, max(0.0, prog)) : 0
    }

    private var progressColor: Color {
        switch progress {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        case 0.8..<0.95: return .yellow
        default: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subject)
                    .font(.subheadline.bold())

                Spacer()

                HStack(spacing: 4) {
                    TextField("15", text: $target)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 40)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("/ \(maxNet)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if current > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Mevcut: \(current, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if let targetValue = Double(target), targetValue > 0 {
                            let difference = current - targetValue
                            if difference >= 0 {
                                Text("+\(difference, specifier: "%.1f")")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            } else {
                                Text("\(difference, specifier: "%.1f")")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
