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
        return "\(firstName) \(lastName)"
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
