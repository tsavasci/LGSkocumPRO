import Foundation
import SwiftData
import FirebaseFirestore

@Model
final class PendingRequest: Identifiable {
    var id: UUID
    var studentID: String  // UUID string of the student
    var teacherID: String  // 6-character teacher code (ABC123)
    var studentName: String
    var studentSchool: String
    var status: String  // "pending", "approved", "rejected"
    var createdAt: Date
    var respondedAt: Date?

    init(
        studentID: String,
        teacherID: String,
        studentName: String,
        studentSchool: String,
        status: String = "pending"
    ) {
        self.id = UUID()
        self.studentID = studentID
        self.teacherID = teacherID
        self.studentName = studentName
        self.studentSchool = studentSchool
        self.status = status
        self.createdAt = Date()
    }
}

// MARK: - Firestore Codable Extensions
extension PendingRequest {
    /// Convert PendingRequest to Firestore dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "studentID": studentID,
            "teacherID": teacherID,
            "studentName": studentName,
            "studentSchool": studentSchool,
            "status": status,
            "createdAt": Timestamp(date: createdAt)
        ]

        if let respondedAt = respondedAt {
            data["respondedAt"] = Timestamp(date: respondedAt)
        }

        return data
    }

    /// Create PendingRequest from Firestore dictionary
    static func fromFirestoreData(_ data: [String: Any]) -> PendingRequest? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let studentID = data["studentID"] as? String,
              let teacherID = data["teacherID"] as? String,
              let studentName = data["studentName"] as? String,
              let studentSchool = data["studentSchool"] as? String,
              let status = data["status"] as? String else {
            return nil
        }

        let request = PendingRequest(
            studentID: studentID,
            teacherID: teacherID,
            studentName: studentName,
            studentSchool: studentSchool,
            status: status
        )
        request.id = id

        if let createdAtTimestamp = data["createdAt"] as? Timestamp {
            request.createdAt = createdAtTimestamp.dateValue()
        }

        if let respondedAtTimestamp = data["respondedAt"] as? Timestamp {
            request.respondedAt = respondedAtTimestamp.dateValue()
        }

        return request
    }
}
