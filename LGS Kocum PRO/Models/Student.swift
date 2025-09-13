import Foundation
import SwiftData

@Model
final class Student: Identifiable, ObservableObject {
    var id: UUID
    var firstName: String
    var lastName: String
    var school: String
    var grade: Int
    var notes: String
    var createdAt: Date

    // Goal tracking fields
    var targetTotalScore: Double = 400  // Default LGS target
    var targetTurkceNet: Double = 15
    var targetMatematikNet: Double = 15
    var targetFenNet: Double = 15
    var targetSosyalNet: Double = 8
    var targetDinNet: Double = 8
    var targetIngilizceNet: Double = 8

    @Relationship(deleteRule: .cascade) var practiceExams = [PracticeExam]() {
        didSet {
            objectWillChange.send()
        }
    }
    @Relationship(deleteRule: .cascade) var questionPerformances = [QuestionPerformance]()

    init(
        firstName: String, lastName: String, school: String = "", grade: Int = 8, notes: String = ""
    ) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.school = school
        self.grade = grade
        self.notes = notes
        self.createdAt = Date()
    }

    var fullName: String {
        let first = firstName.isEmpty ? "Ad" : firstName
        let last = lastName.isEmpty ? "Soyad" : lastName
        return "\(first) \(last)"
    }

    // Goal tracking computed properties
    var currentAverageScore: Double {
        guard !practiceExams.isEmpty else { return 0 }
        let total = practiceExams.map { $0.totalScore }.reduce(0, +)
        let count = Double(practiceExams.count)
        guard count > 0 else { return 0 }
        return total / count
    }

    var scoreProgress: Double {
        guard targetTotalScore > 0, currentAverageScore > 0 else { return 0 }
        let progress = currentAverageScore / targetTotalScore
        guard progress.isFinite else { return 0 }
        return min(1.0, max(0.0, progress))
    }

    var averageTurkceNet: Double {
        guard !practiceExams.isEmpty else { return 0 }
        let total = practiceExams.map { $0.turkceNet }.reduce(0, +)
        let count = Double(practiceExams.count)
        guard count > 0 else { return 0 }
        let average = total / count
        return average.isFinite ? average : 0
    }

    var averageMatematikNet: Double {
        guard !practiceExams.isEmpty else { return 0 }
        let total = practiceExams.map { $0.matematikNet }.reduce(0, +)
        let count = Double(practiceExams.count)
        guard count > 0 else { return 0 }
        let average = total / count
        return average.isFinite ? average : 0
    }

    var averageFenNet: Double {
        guard !practiceExams.isEmpty else { return 0 }
        let total = practiceExams.map { $0.fenNet }.reduce(0, +)
        let count = Double(practiceExams.count)
        guard count > 0 else { return 0 }
        let average = total / count
        return average.isFinite ? average : 0
    }

    var averageSosyalNet: Double {
        guard !practiceExams.isEmpty else { return 0 }
        let total = practiceExams.map { $0.sosyalNet }.reduce(0, +)
        let count = Double(practiceExams.count)
        guard count > 0 else { return 0 }
        let average = total / count
        return average.isFinite ? average : 0
    }

    var averageDinNet: Double {
        guard !practiceExams.isEmpty else { return 0 }
        let total = practiceExams.map { $0.dinNet }.reduce(0, +)
        let count = Double(practiceExams.count)
        guard count > 0 else { return 0 }
        let average = total / count
        return average.isFinite ? average : 0
    }

    var averageIngilizceNet: Double {
        guard !practiceExams.isEmpty else { return 0 }
        let total = practiceExams.map { $0.ingilizceNet }.reduce(0, +)
        let count = Double(practiceExams.count)
        guard count > 0 else { return 0 }
        let average = total / count
        return average.isFinite ? average : 0
    }
}

@Model
final class PracticeExam: Identifiable, ObservableObject {
    var id: UUID
    var date: Date
    var name: String
    var totalScore: Double
    var notes: String

    // Subject net scores
    var turkceNet: Double = 0
    var matematikNet: Double = 0
    var fenNet: Double = 0
    var sosyalNet: Double = 0
    var dinNet: Double = 0
    var ingilizceNet: Double = 0

    @Relationship(inverse: \Student.practiceExams) var student: Student?

    init(name: String, date: Date = Date(), totalScore: Double, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.date = date
        self.totalScore = totalScore
        self.notes = notes
    }

    var totalNet: Double {
        return turkceNet + matematikNet + fenNet + sosyalNet + dinNet + ingilizceNet
    }
}

@Model
final class QuestionPerformance: Identifiable {
    var id: UUID
    var date: Date
    var subject: String
    var topic: String
    var correctCount: Int
    var wrongCount: Int
    var emptyCount: Int
    var timeInMinutes: Int  // Çözüm süresi (dakika)
    var notes: String

    @Relationship(inverse: \Student.questionPerformances) var student: Student?

    init(
        subject: String, topic: String, correct: Int, wrong: Int, empty: Int,
        timeInMinutes: Int = 0, notes: String = ""
    ) {
        self.id = UUID()
        self.date = Date()
        self.subject = subject
        self.topic = topic
        self.correctCount = correct
        self.wrongCount = wrong
        self.emptyCount = empty
        self.timeInMinutes = timeInMinutes
        self.notes = notes
    }

    var totalQuestions: Int {
        return correctCount + wrongCount + emptyCount
    }

    var successRate: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctCount) / Double(totalQuestions) * 100
    }
}
