import SwiftUI
import SwiftData
import Charts

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
                                .font(.headline)
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
                                    value: "\(students.flatMap({ $0.practiceExams }).count)",
                                    label: "Toplam Deneme",
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
                        VStack(spacing: 8) {
                            Text("Başarı Grafiği")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            Chart {
                                if let student = selectedStudent {
                                    // Show data for selected student
                                    ForEach(student.practiceExams.sorted(by: { $0.date < $1.date })) { exam in
                                        LineMark(
                                            x: .value("Tarih", exam.date, unit: .day),
                                            y: .value("Puan", exam.totalScore)
                                        )
                                        .foregroundStyle(by: .value("Öğrenci", student.fullName))
                                        .symbol(Circle().strokeBorder(lineWidth: 2))
                                    }
                                } else {
                                    // Show data for all students
                                    ForEach(students) { student in
                                        ForEach(student.practiceExams.sorted(by: { $0.date < $1.date })) { exam in
                                            LineMark(
                                                x: .value("Tarih", exam.date, unit: .day),
                                                y: .value("Puan", exam.totalScore)
                                            )
                                            .foregroundStyle(by: .value("Öğrenci", student.fullName))
                                            .symbol(Circle().strokeBorder(lineWidth: 2))
                                        }
                                    }
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
                            .frame(height: 250)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Subject Performance
                        if !subjectPerformance.isEmpty {
                            VStack(spacing: 8) {
                                Text("Ders Bazlı Performans")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(subjectPerformance, id: \.subject) { data in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(data.subject)
                                                    .font(.subheadline)
                                                
                                                Spacer()
                                                
                                                Text("\(Int(data.averageScore)) puan")
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(scoreColor(data.averageScore))
                                            }
                                            
                                            ProgressView(value: data.averageScore / 100)
                                                .progressViewStyle(LinearProgressViewStyle(tint: scoreColor(data.averageScore)))
                                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Analizler")
                .background(Color(.systemGroupedBackground))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageScore: Double {
        let exams = selectedStudent?.practiceExams ?? students.flatMap { $0.practiceExams }
        guard !exams.isEmpty else { return 0 }
        return exams.map { $0.totalScore }.reduce(0, +) / Double(exams.count)
    }
    
    private var topSubject: (String, Double)? {
        // This is a simplified example - you would need to track subject scores in your data model
        let subjects = ["Matematik", "Fen Bilimleri", "Türkçe", "Sosyal Bilgiler"]
        guard !subjects.isEmpty else { return nil }
        return (subjects[0], 85.0) // Placeholder
    }
    
    private var subjectPerformance: [SubjectPerformance] {
        // This is a simplified example - you would need to track subject scores in your data model
        return [
            SubjectPerformance(subject: "Matematik", averageScore: 78.5),
            SubjectPerformance(subject: "Fen Bilimleri", averageScore: 82.3),
            SubjectPerformance(subject: "Türkçe", averageScore: 75.0),
            SubjectPerformance(subject: "Sosyal Bilgiler", averageScore: 88.2)
        ]
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
                firstName: ["Ahmet", "Ayşe", "Mehmet"][i-1],
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
