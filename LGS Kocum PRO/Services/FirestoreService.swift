import Foundation
import FirebaseFirestore
import SwiftData

@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    // Current teacher ID (şimdilik sabit, sonra Authentication ile dinamik olacak)
    @Published var currentTeacherID: String = "teacher_default"

    private init() {}

    // MARK: - Student Operations

    /// SwiftData Student'ı Firestore'a senkronize et
    func syncStudentToFirestore(_ student: Student) async throws {
        let studentData: [String: Any] = [
            "id": student.id.uuidString,
            "firstName": student.firstName,
            "lastName": student.lastName,
            "school": student.school,
            "grade": student.grade,
            "branch": student.branch,
            "notes": student.notes,
            "teacherID": currentTeacherID,
            "createdAt": Timestamp(date: student.createdAt),
            "targets": [
                "totalScore": student.targetTotalScore,
                "turkceNet": student.targetTurkceNet,
                "matematikNet": student.targetMatematikNet,
                "fenNet": student.targetFenNet,
                "sosyalNet": student.targetSosyalNet,
                "dinNet": student.targetDinNet,
                "ingilizceNet": student.targetIngilizceNet
            ]
        ]

        try await db.collection("students")
            .document(student.id.uuidString)
            .setData(studentData, merge: true)
    }

    /// Öğrenciyi Firestore'dan sil
    func deleteStudentFromFirestore(_ studentID: UUID) async throws {
        try await db.collection("students")
            .document(studentID.uuidString)
            .delete()
    }

    /// Öğretmenin tüm öğrencilerini Firestore'dan çek
    func fetchStudentsFromFirestore() async throws -> [[String: Any]] {
        let snapshot = try await db.collection("students")
            .whereField("teacherID", isEqualTo: currentTeacherID)
            .getDocuments()

        return snapshot.documents.map { $0.data() }
    }

    // MARK: - Exam Operations

    /// Sınavı Firestore'a senkronize et
    func syncExamToFirestore(_ exam: PracticeExam, studentID: UUID) async throws {
        let examData: [String: Any] = [
            "id": exam.id.uuidString,
            "studentID": studentID.uuidString,
            "teacherID": currentTeacherID,
            "name": exam.name,
            "date": Timestamp(date: exam.date),
            "totalScore": exam.totalScore,
            "notes": exam.notes,
            "nets": [
                "turkce": exam.turkceNet,
                "matematik": exam.matematikNet,
                "fen": exam.fenNet,
                "sosyal": exam.sosyalNet,
                "din": exam.dinNet,
                "ingilizce": exam.ingilizceNet
            ]
        ]

        try await db.collection("exams")
            .document(exam.id.uuidString)
            .setData(examData, merge: true)
    }

    /// Sınavı Firestore'dan sil
    func deleteExamFromFirestore(_ examID: UUID) async throws {
        try await db.collection("exams")
            .document(examID.uuidString)
            .delete()
    }

    /// Öğrencinin tüm sınavlarını Firestore'dan çek
    func fetchExamsFromFirestore(studentID: UUID) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("exams")
            .whereField("studentID", isEqualTo: studentID.uuidString)
            .order(by: "date", descending: true)
            .getDocuments()

        return snapshot.documents.map { $0.data() }
    }

    /// Öğrenciden gelen yeni sınavları dinle (Real-time)
    func listenForNewExams(studentID: UUID, completion: @escaping ([String: Any]) -> Void) -> ListenerRegistration {
        return db.collection("exams")
            .whereField("studentID", isEqualTo: studentID.uuidString)
            .whereField("teacherID", isEqualTo: currentTeacherID)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error fetching snapshots: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                snapshot.documentChanges.forEach { change in
                    if change.type == .added {
                        completion(change.document.data())
                    }
                }
            }
    }

    // MARK: - Question Performance Operations

    /// Soru performansını Firestore'a senkronize et
    func syncPerformanceToFirestore(_ performance: QuestionPerformance, studentID: UUID) async throws {
        let performanceData: [String: Any] = [
            "id": performance.id.uuidString,
            "studentID": studentID.uuidString,
            "teacherID": currentTeacherID,
            "subject": performance.subject,
            "topic": performance.topic,
            "correctCount": performance.correctCount,
            "wrongCount": performance.wrongCount,
            "emptyCount": performance.emptyCount,
            "timeInMinutes": performance.timeInMinutes,
            "notes": performance.notes,
            "date": Timestamp(date: performance.date)
        ]

        try await db.collection("questionPerformances")
            .document(performance.id.uuidString)
            .setData(performanceData, merge: true)
    }

    /// Performansı Firestore'dan sil
    func deletePerformanceFromFirestore(_ performanceID: UUID) async throws {
        try await db.collection("questionPerformances")
            .document(performanceID.uuidString)
            .delete()
    }

    /// Öğrencinin tüm performanslarını Firestore'dan çek
    func fetchPerformancesFromFirestore(studentID: UUID) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("questionPerformances")
            .whereField("studentID", isEqualTo: studentID.uuidString)
            .order(by: "date", descending: true)
            .getDocuments()

        return snapshot.documents.map { $0.data() }
    }

    // MARK: - Batch Operations

    /// Tüm öğrenci verilerini Firestore'a toplu senkronize et
    func syncAllDataToFirestore(students: [Student]) async throws {
        let batch = db.batch()
        var operationCount = 0

        for student in students {
            // Student sync
            let studentRef = db.collection("students").document(student.id.uuidString)
            let studentData: [String: Any] = [
                "id": student.id.uuidString,
                "firstName": student.firstName,
                "lastName": student.lastName,
                "school": student.school,
                "grade": student.grade,
                "branch": student.branch,
                "notes": student.notes,
                "teacherID": currentTeacherID,
                "createdAt": Timestamp(date: student.createdAt),
                "targets": [
                    "totalScore": student.targetTotalScore,
                    "turkceNet": student.targetTurkceNet,
                    "matematikNet": student.targetMatematikNet,
                    "fenNet": student.targetFenNet,
                    "sosyalNet": student.targetSosyalNet,
                    "dinNet": student.targetDinNet,
                    "ingilizceNet": student.targetIngilizceNet
                ]
            ]
            batch.setData(studentData, forDocument: studentRef, merge: true)
            operationCount += 1

            // Firestore batch limit: 500 operations
            if operationCount >= 500 {
                try await batch.commit()
                operationCount = 0
            }

            // Exam sync
            for exam in student.practiceExams {
                let examRef = db.collection("exams").document(exam.id.uuidString)
                let examData: [String: Any] = [
                    "id": exam.id.uuidString,
                    "studentID": student.id.uuidString,
                    "teacherID": currentTeacherID,
                    "name": exam.name,
                    "date": Timestamp(date: exam.date),
                    "totalScore": exam.totalScore,
                    "notes": exam.notes,
                    "nets": [
                        "turkce": exam.turkceNet,
                        "matematik": exam.matematikNet,
                        "fen": exam.fenNet,
                        "sosyal": exam.sosyalNet,
                        "din": exam.dinNet,
                        "ingilizce": exam.ingilizceNet
                    ]
                ]
                batch.setData(examData, forDocument: examRef, merge: true)
                operationCount += 1

                if operationCount >= 500 {
                    try await batch.commit()
                    operationCount = 0
                }
            }

            // Performance sync
            for performance in student.questionPerformances {
                let perfRef = db.collection("questionPerformances").document(performance.id.uuidString)
                let perfData: [String: Any] = [
                    "id": performance.id.uuidString,
                    "studentID": student.id.uuidString,
                    "teacherID": currentTeacherID,
                    "subject": performance.subject,
                    "topic": performance.topic,
                    "correctCount": performance.correctCount,
                    "wrongCount": performance.wrongCount,
                    "emptyCount": performance.emptyCount,
                    "timeInMinutes": performance.timeInMinutes,
                    "notes": performance.notes,
                    "date": Timestamp(date: performance.date)
                ]
                batch.setData(perfData, forDocument: perfRef, merge: true)
                operationCount += 1

                if operationCount >= 500 {
                    try await batch.commit()
                    operationCount = 0
                }
            }
        }

        // Commit remaining operations
        if operationCount > 0 {
            try await batch.commit()
        }
    }
}
