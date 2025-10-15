import Charts
import SwiftData
import SwiftUI

public struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.lastName) var students: [Student]

    public init() {}

    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedStudent: Student?

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Haftalık"
        case month = "Aylık"
        case year = "Yıllık"
        case all = "Tüm Zamanlar"

        var id: String { self.rawValue }
    }

    public var body: some View {
        NavigationStack {
            if students.isEmpty {
                ContentUnavailableView(
                    "Öğrenci Bulunamadı",
                    systemImage: "person.3.fill",
                    description: Text("Analizleri görmek için öğrenci ekleyin")
                )
                .navigationTitle("Analizler")
            } else {
                ZStack {
                    // Modern Gradient Background
                    LinearGradient(
                        colors: [
                            Color(hex: "667eea").opacity(0.05),
                            Color(hex: "764ba2").opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 20) {
                            // Time Range Picker
                            Picker("Zaman Aralığı", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.top, 8)

                            // Student Picker
                            if students.count > 1 {
                                Picker("Öğrenci", selection: $selectedStudent) {
                                    Text("Tüm Öğrenciler").tag(Student?.none)
                                    ForEach(students) { student in
                                        Text(student.fullName).tag(Optional(student))
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal)
                            }

                            // Overall Stats
                            VStack(spacing: 16) {
                                Text("Genel İstatistikler")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.primaryGradient)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                HStack(spacing: 16) {
                                    StatCard(
                                        value: "\(students.count)",
                                        label: "Öğrenci",
                                        icon: "person.3.fill",
                                        color: .blue
                                    )

                                    StatCard(
                                        value: "\(filteredExams.count)",
                                        label: selectedTimeRange == .all
                                            ? "Toplam Deneme" : "Deneme Sayısı",
                                        icon: "doc.text.fill",
                                        color: .green
                                    )
                                }
                                .padding(.horizontal)

                                HStack(spacing: 16) {
                                    StatCard(
                                        value: String(format: "%.1f", averageScore),
                                        label: "Ortalama Puan",
                                        icon: "chart.bar.fill",
                                        color: .orange
                                    )

                                    StatCard(
                                        value: "\(topSubject?.0 ?? "-")",
                                        label: "En İyi Ders",
                                        icon: "star.fill",
                                        color: .purple
                                    )
                                }
                                .padding(.horizontal)
                            }

                            // Performance Chart
                            VStack(spacing: 12) {
                                Text("Başarı Grafiği")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.primaryGradient)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                Chart {
                                    ForEach(filteredExams.sorted(by: { $0.date < $1.date })) {
                                        exam in
                                        LineMark(
                                            x: .value("Tarih", exam.date, unit: .day),
                                            y: .value("Puan", exam.totalScore)
                                        )
                                        .foregroundStyle(
                                            by: .value(
                                                "Öğrenci", exam.student?.fullName ?? "Bilinmeyen")
                                        )
                                        .symbol(Circle().strokeBorder(lineWidth: 2))
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { value in
                                        if let date = value.as(Date.self) {
                                            AxisValueLabel {
                                                Text(date, format: .dateTime.day().month(.narrow))
                                            }
                                        }
                                        AxisGridLine()
                                        AxisTick()
                                    }
                                }
                                .frame(height: 200)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .padding(.horizontal)
                            }

                            // Subject Performance
                            if !subjectPerformance.isEmpty {
                                VStack(spacing: 12) {
                                    Text("Ders Bazlı Performans")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.primaryGradient)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)

                                    VStack(spacing: 16) {
                                        ForEach(subjectPerformance, id: \.subject) { data in
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "book.fill")
                                                            .font(.caption)
                                                            .foregroundStyle(
                                                                scoreColor(data.averageScore))
                                                        Text(data.subject)
                                                            .font(.headline)
                                                    }

                                                    Spacer()

                                                    Text("\(Int(data.averageScore))%")
                                                        .font(.title3.bold())
                                                        .foregroundStyle(
                                                            scoreColor(data.averageScore))
                                                }

                                                GeometryReader { geometry in
                                                    ZStack(alignment: .leading) {
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.gray.opacity(0.2))

                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(
                                                                LinearGradient(
                                                                    colors: [
                                                                        scoreColor(
                                                                            data.averageScore),
                                                                        scoreColor(
                                                                            data.averageScore
                                                                        ).opacity(0.7),
                                                                    ],
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                            .frame(
                                                                width: geometry.size.width
                                                                    * (data.averageScore / 100))
                                                    }
                                                }
                                                .frame(height: 10)
                                            }
                                            .padding()
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                            .shadow(
                                                color: Color.black.opacity(0.05), radius: 5, x: 0,
                                                y: 2)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical)
                    }
                    .navigationTitle("Analizler")
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredExams: [PracticeExam] {
        let allExams = selectedStudent?.practiceExams ?? students.flatMap { $0.practiceExams }

        switch selectedTimeRange {
        case .week:
            return allExams.filter {
                Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0 <= 7
            }
        case .month:
            return allExams.filter {
                Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0 <= 30
            }
        case .year:
            return allExams.filter {
                Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0 <= 365
            }
        case .all:
            return allExams
        }
    }

    private var averageScore: Double {
        let exams = filteredExams
        guard !exams.isEmpty else { return 0 }
        return exams.map { $0.totalScore }.reduce(0, +) / Double(exams.count)
    }

    private var topSubject: (String, Double)? {
        let exams = filteredExams
        guard !exams.isEmpty else { return nil }

        // Calculate average scores for each subject
        let subjectAverages: [String: Double] = [
            "Türkçe": exams.map { $0.turkceNet }.reduce(0, +) / Double(exams.count),
            "Matematik": exams.map { $0.matematikNet }.reduce(0, +) / Double(exams.count),
            "Fen Bilimleri": exams.map { $0.fenNet }.reduce(0, +) / Double(exams.count),
            "Sosyal Bilgiler": exams.map { $0.sosyalNet }.reduce(0, +) / Double(exams.count),
            "Din Kültürü": exams.map { $0.dinNet }.reduce(0, +) / Double(exams.count),
            "İngilizce": exams.map { $0.ingilizceNet }.reduce(0, +) / Double(exams.count),
        ]

        // Find the subject with highest average
        return subjectAverages.max(by: { $0.value < $1.value })
    }

    private var subjectPerformance: [SubjectPerformance] {
        let exams = filteredExams
        guard !exams.isEmpty else { return [] }

        let subjects = [
            ("Türkçe", exams.map { $0.turkceNet }),
            ("Matematik", exams.map { $0.matematikNet }),
            ("Fen Bilimleri", exams.map { $0.fenNet }),
            ("Sosyal Bilgiler", exams.map { $0.sosyalNet }),
            ("Din Kültürü", exams.map { $0.dinNet }),
            ("İngilizce", exams.map { $0.ingilizceNet }),
        ]

        return subjects.compactMap { (subject, nets) in
            let average = nets.reduce(0, +) / Double(nets.count)
            // Only show subjects with data (net > 0)
            guard average > 0 else { return nil }
            // Convert net scores to approximate percentage (simplified conversion)
            let percentage = min(100, average * 2.5)  // Rough conversion: 40 net ≈ 100%
            return SubjectPerformance(subject: subject, averageScore: percentage)
        }.sorted { $0.averageScore > $1.averageScore }
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<50: return .red
        case 50..<70: return .orange
        case 70..<85: return .yellow
        default: return .green
        }
    }
}

// MARK: - Supporting Types

struct SubjectPerformance: Identifiable {
    let id = UUID()
    let subject: String
    let averageScore: Double
}


struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Student.self, PracticeExam.self, QuestionPerformance.self,
            configurations: config
        )

        // Add example data
        for i in 1...3 {
            let student = Student(
                firstName: ["Ahmet", "Ayşe", "Mehmet"][i - 1],
                lastName: "Öğrenci \(i)",
                school: "Örnek Okul",
                grade: 8
            )

            // Add practice exams for each student
            for j in 1...5 {
                let exam = PracticeExam(
                    name: "Deneme \(j)",
                    date: Calendar.current.date(byAdding: .day, value: -j * 7, to: Date())!,
                    totalScore: Double.random(in: 300...500),
                    notes: ""
                )
                student.practiceExams.append(exam)
            }

            container.mainContext.insert(student)
        }

        return NavigationStack {
            AnalyticsView()
        }
        .modelContainer(container)
    }
}
