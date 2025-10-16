import Foundation
import FirebaseFirestore
import SwiftData

/// Öğretmen uygulaması için Firestore'dan veri alma ve dinleme yöneticisi
@MainActor
class FirestoreSyncManager: ObservableObject {
    static let shared = FirestoreSyncManager()

    private let db = Firestore.firestore()
    private let firestoreService = FirestoreService.shared

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    // Active listeners
    private var studentListener: ListenerRegistration?
    private var examListener: ListenerRegistration?
    private var performanceListener: ListenerRegistration?

    private init() {}

    // MARK: - Fetch & Import from Firestore to SwiftData

    /// Firestore'dan tüm öğrenci verilerini çek ve SwiftData'ya kaydet
    func fetchAndImportAllData(modelContext: ModelContext) async throws {
        isSyncing = true
        syncError = nil

        do {
            // 1. Fetch students from Firestore
            let studentsData = try await firestoreService.fetchStudentsFromFirestore()

            // 2. Import students to SwiftData
            for studentData in studentsData {
                try await importStudent(studentData, modelContext: modelContext)
            }

            lastSyncDate = Date()
            isSyncing = false
        } catch {
            syncError = error.localizedDescription
            isSyncing = false
            throw error
        }
    }

    /// Tek bir öğrenciyi Firestore'dan SwiftData'ya import et
    private func importStudent(_ data: [String: Any], modelContext: ModelContext) async throws {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String else {
            print("Invalid student data")
            return
        }

        // Check if student already exists
        let descriptor = FetchDescriptor<Student>(
            predicate: #Predicate { $0.id == id }
        )

        let existingStudents = try modelContext.fetch(descriptor)

        let student: Student
        if let existing = existingStudents.first {
            // Update existing student
            student = existing
        } else {
            // Create new student
            student = Student(
                firstName: firstName,
                lastName: lastName,
                school: data["school"] as? String ?? "",
                grade: data["grade"] as? Int ?? 8,
                branch: data["branch"] as? String ?? "",
                notes: data["notes"] as? String ?? ""
            )
            student.id = id
            modelContext.insert(student)
        }

        // Update fields
        student.firstName = firstName
        student.lastName = lastName
        student.school = data["school"] as? String ?? ""
        student.grade = data["grade"] as? Int ?? 8
        student.branch = data["branch"] as? String ?? ""
        student.notes = data["notes"] as? String ?? ""
        student.teacherID = data["teacherID"] as? String ?? "teacher_default"

        // Update targets
        if let targets = data["targets"] as? [String: Any] {
            student.targetTotalScore = targets["totalScore"] as? Double ?? 400
            student.targetTurkceNet = targets["turkceNet"] as? Double ?? 15
            student.targetMatematikNet = targets["matematikNet"] as? Double ?? 15
            student.targetFenNet = targets["fenNet"] as? Double ?? 15
            student.targetSosyalNet = targets["sosyalNet"] as? Double ?? 8
            student.targetDinNet = targets["dinNet"] as? Double ?? 8
            student.targetIngilizceNet = targets["ingilizceNet"] as? Double ?? 8
        }

        student.lastSyncDate = Date()

        // Fetch and import exams for this student
        try await fetchAndImportExams(for: student, modelContext: modelContext)

        // Fetch and import performances for this student
        try await fetchAndImportPerformances(for: student, modelContext: modelContext)

        try modelContext.save()
    }

    /// Öğrencinin sınavlarını Firestore'dan çek ve import et
    private func fetchAndImportExams(for student: Student, modelContext: ModelContext) async throws {
        let examsData = try await firestoreService.fetchExamsFromFirestore(studentID: student.id)

        for examData in examsData {
            guard let idString = examData["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let name = examData["name"] as? String,
                  let totalScore = examData["totalScore"] as? Double else {
                continue
            }

            // Check if exam already exists
            let existingExam = student.practiceExams.first { $0.id == id }

            let exam: PracticeExam
            if let existing = existingExam {
                exam = existing
            } else {
                exam = PracticeExam(name: name, totalScore: totalScore)
                exam.id = id
                exam.student = student
                modelContext.insert(exam)
            }

            // Update fields
            exam.name = name
            exam.totalScore = totalScore
            exam.notes = examData["notes"] as? String ?? ""

            // Parse date
            if let timestamp = examData["date"] as? Timestamp {
                exam.date = timestamp.dateValue()
            }

            // Update nets
            if let nets = examData["nets"] as? [String: Any] {
                exam.turkceNet = nets["turkce"] as? Double ?? 0
                exam.matematikNet = nets["matematik"] as? Double ?? 0
                exam.fenNet = nets["fen"] as? Double ?? 0
                exam.sosyalNet = nets["sosyal"] as? Double ?? 0
                exam.dinNet = nets["din"] as? Double ?? 0
                exam.ingilizceNet = nets["ingilizce"] as? Double ?? 0
            }
        }
    }

    /// Öğrencinin performanslarını Firestore'dan çek ve import et
    private func fetchAndImportPerformances(for student: Student, modelContext: ModelContext) async throws {
        let performancesData = try await firestoreService.fetchPerformancesFromFirestore(studentID: student.id)

        for perfData in performancesData {
            guard let idString = perfData["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let subject = perfData["subject"] as? String,
                  let topic = perfData["topic"] as? String,
                  let correctCount = perfData["correctCount"] as? Int,
                  let wrongCount = perfData["wrongCount"] as? Int,
                  let emptyCount = perfData["emptyCount"] as? Int else {
                continue
            }

            // Check if performance already exists
            let existingPerf = student.questionPerformances.first { $0.id == id }

            let performance: QuestionPerformance
            if let existing = existingPerf {
                performance = existing
            } else {
                performance = QuestionPerformance(
                    subject: subject,
                    topic: topic,
                    correct: correctCount,
                    wrong: wrongCount,
                    empty: emptyCount
                )
                performance.id = id
                performance.student = student
                modelContext.insert(performance)
            }

            // Update fields
            performance.subject = subject
            performance.topic = topic
            performance.correctCount = correctCount
            performance.wrongCount = wrongCount
            performance.emptyCount = emptyCount
            performance.timeInMinutes = perfData["timeInMinutes"] as? Int ?? 0
            performance.notes = perfData["notes"] as? String ?? ""

            // Parse date
            if let timestamp = perfData["date"] as? Timestamp {
                performance.date = timestamp.dateValue()
            }
        }
    }

    // MARK: - Real-time Listeners

    /// Firestore'u sürekli dinle - yeni veri geldiğinde otomatik import et
    func startListening(modelContext: ModelContext) {
        stopListening() // Stop existing listeners first

        let teacherID = firestoreService.currentTeacherID

        // Listen to new students
        studentListener = db.collection("students")
            .whereField("teacherID", isEqualTo: teacherID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    Task { @MainActor in
                        self.syncError = "Öğrenci dinleme hatası: \(error.localizedDescription)"
                    }
                    return
                }

                guard let snapshot = snapshot else { return }

                Task { @MainActor in
                    for change in snapshot.documentChanges {
                        if change.type == .added || change.type == .modified {
                            do {
                                try await self.importStudent(change.document.data(), modelContext: modelContext)
                                print("✅ Öğrenci senkronize edildi: \(change.document.documentID)")
                            } catch {
                                print("❌ Öğrenci import hatası: \(error)")
                            }
                        }
                    }
                }
            }

        // Listen to new exams
        examListener = db.collection("exams")
            .whereField("teacherID", isEqualTo: teacherID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    Task { @MainActor in
                        self.syncError = "Sınav dinleme hatası: \(error.localizedDescription)"
                    }
                    return
                }

                guard let snapshot = snapshot else { return }

                Task { @MainActor in
                    for change in snapshot.documentChanges {
                        if change.type == .added || change.type == .modified {
                            await self.handleNewExam(change.document.data(), modelContext: modelContext)
                        }
                    }
                }
            }

        // Listen to new performances
        performanceListener = db.collection("questionPerformances")
            .whereField("teacherID", isEqualTo: teacherID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    Task { @MainActor in
                        self.syncError = "Performans dinleme hatası: \(error.localizedDescription)"
                    }
                    return
                }

                guard let snapshot = snapshot else { return }

                Task { @MainActor in
                    for change in snapshot.documentChanges {
                        if change.type == .added || change.type == .modified {
                            await self.handleNewPerformance(change.document.data(), modelContext: modelContext)
                        }
                    }
                }
            }

        print("🎧 Firestore dinleyicileri başlatıldı")
    }

    /// Dinleyicileri durdur
    func stopListening() {
        studentListener?.remove()
        examListener?.remove()
        performanceListener?.remove()

        studentListener = nil
        examListener = nil
        performanceListener = nil

        print("🔇 Firestore dinleyicileri durduruldu")
    }

    // MARK: - Handle Real-time Updates

    private func handleNewExam(_ data: [String: Any], modelContext: ModelContext) async {
        guard let studentIDString = data["studentID"] as? String,
              let studentID = UUID(uuidString: studentIDString) else {
            return
        }

        // Find student
        let descriptor = FetchDescriptor<Student>(
            predicate: #Predicate { $0.id == studentID }
        )

        do {
            let students = try modelContext.fetch(descriptor)
            guard let student = students.first else {
                print("⚠️ Öğrenci bulunamadı: \(studentIDString)")
                return
            }

            // Import exam
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let name = data["name"] as? String,
                  let totalScore = data["totalScore"] as? Double else {
                return
            }

            let existingExam = student.practiceExams.first { $0.id == id }

            let exam: PracticeExam
            if let existing = existingExam {
                exam = existing
            } else {
                exam = PracticeExam(name: name, totalScore: totalScore)
                exam.id = id
                exam.student = student
                modelContext.insert(exam)
                print("🆕 Yeni sınav eklendi: \(name)")
            }

            exam.name = name
            exam.totalScore = totalScore
            exam.notes = data["notes"] as? String ?? ""

            if let timestamp = data["date"] as? Timestamp {
                exam.date = timestamp.dateValue()
            }

            if let nets = data["nets"] as? [String: Any] {
                exam.turkceNet = nets["turkce"] as? Double ?? 0
                exam.matematikNet = nets["matematik"] as? Double ?? 0
                exam.fenNet = nets["fen"] as? Double ?? 0
                exam.sosyalNet = nets["sosyal"] as? Double ?? 0
                exam.dinNet = nets["din"] as? Double ?? 0
                exam.ingilizceNet = nets["ingilizce"] as? Double ?? 0
            }

            try modelContext.save()
        } catch {
            print("❌ Sınav import hatası: \(error)")
        }
    }

    private func handleNewPerformance(_ data: [String: Any], modelContext: ModelContext) async {
        guard let studentIDString = data["studentID"] as? String,
              let studentID = UUID(uuidString: studentIDString) else {
            return
        }

        // Find student
        let descriptor = FetchDescriptor<Student>(
            predicate: #Predicate { $0.id == studentID }
        )

        do {
            let students = try modelContext.fetch(descriptor)
            guard let student = students.first else {
                print("⚠️ Öğrenci bulunamadı: \(studentIDString)")
                return
            }

            // Import performance
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let subject = data["subject"] as? String,
                  let topic = data["topic"] as? String,
                  let correctCount = data["correctCount"] as? Int,
                  let wrongCount = data["wrongCount"] as? Int,
                  let emptyCount = data["emptyCount"] as? Int else {
                return
            }

            let existingPerf = student.questionPerformances.first { $0.id == id }

            let performance: QuestionPerformance
            if let existing = existingPerf {
                performance = existing
            } else {
                performance = QuestionPerformance(
                    subject: subject,
                    topic: topic,
                    correct: correctCount,
                    wrong: wrongCount,
                    empty: emptyCount
                )
                performance.id = id
                performance.student = student
                modelContext.insert(performance)
                print("🆕 Yeni performans eklendi: \(subject) - \(topic)")
            }

            performance.subject = subject
            performance.topic = topic
            performance.correctCount = correctCount
            performance.wrongCount = wrongCount
            performance.emptyCount = emptyCount
            performance.timeInMinutes = data["timeInMinutes"] as? Int ?? 0
            performance.notes = data["notes"] as? String ?? ""

            if let timestamp = data["date"] as? Timestamp {
                performance.date = timestamp.dateValue()
            }

            try modelContext.save()
        } catch {
            print("❌ Performans import hatası: \(error)")
        }
    }
}
