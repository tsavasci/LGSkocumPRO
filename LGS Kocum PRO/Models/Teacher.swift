import Foundation
import SwiftData

@Model
final class Teacher: Identifiable {
    var id: UUID
    var email: String
    var name: String
    var createdAt: Date

    // Firebase sync için
    var firebaseUID: String?
    var lastSyncDate: Date?

    init(email: String, name: String, firebaseUID: String? = nil) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.firebaseUID = firebaseUID
    }
}
