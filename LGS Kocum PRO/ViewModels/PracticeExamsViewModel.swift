import SwiftData
import SwiftUI

@MainActor
class PracticeExamsViewModel: ObservableObject {
    let student: Student
    private var modelContext: ModelContext?

    @Published private(set) var sortedExams: [PracticeExam] = []

    init(student: Student) {
        self.student = student
        updateExams()
    }

    func setModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
        updateExams()
    }

    func updateExams() {
        // Sort exams by date, newest first
        sortedExams = student.practiceExams.sorted { $0.date > $1.date }
    }

    func refreshExams() {
        // Force refresh by clearing and reloading
        DispatchQueue.main.async {
            self.updateExams()
        }
    }

    func deleteExams(at offsets: IndexSet, modelContext: ModelContext) {
        withAnimation {
            for index in offsets {
                if index < sortedExams.count {
                    let exam = sortedExams[index]
                    // Remove from student's exams
                    if let index = student.practiceExams.firstIndex(where: { $0.id == exam.id }) {
                        student.practiceExams.remove(at: index)
                    }
                    // Delete from context
                    modelContext.delete(exam)
                }
            }
            // Save changes and update the list
            try? modelContext.save()
            updateExams()
        }
    }
}
