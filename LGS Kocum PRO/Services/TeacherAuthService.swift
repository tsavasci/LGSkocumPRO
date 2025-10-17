import Foundation
import FirebaseFirestore
import SwiftUI

/// Teacher authentication and ID management service
@MainActor
class TeacherAuthService: ObservableObject {
    static let shared = TeacherAuthService()

    private let db = Firestore.firestore()
    private let teacherIDKey = "currentTeacherID"

    @Published var currentTeacherID: String? {
        didSet {
            if let id = currentTeacherID {
                UserDefaults.standard.set(id, forKey: teacherIDKey)
                // Update FirestoreService
                FirestoreService.shared.currentTeacherID = id
            } else {
                UserDefaults.standard.removeObject(forKey: teacherIDKey)
            }
        }
    }

    @Published var currentTeacher: Teacher?
    @Published var isAuthenticated: Bool = false

    private init() {
        // Load teacher ID from UserDefaults
        if let savedID = UserDefaults.standard.string(forKey: teacherIDKey) {
            self.currentTeacherID = savedID
            self.isAuthenticated = true
            // Update FirestoreService
            FirestoreService.shared.currentTeacherID = savedID
        }
    }

    // MARK: - Teacher ID Generation

    /// Generate a unique 6-character teacher ID (3 letters + 3 numbers, excluding I/O)
    func generateTeacherID() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ" // Excluding I and O
        let numbers = "0123456789"

        let randomLetters = (0..<3).map { _ in
            letters.randomElement()!
        }
        let randomNumbers = (0..<3).map { _ in
            numbers.randomElement()!
        }

        return String(randomLetters) + String(randomNumbers)
    }

    /// Create a new teacher in Firestore and set as current
    func createTeacher(firstName: String, lastName: String, school: String, email: String = "") async throws -> String {
        // Generate unique ID
        var teacherID = generateTeacherID()

        // Check if ID already exists, regenerate if needed
        var attempts = 0
        while try await teacherIDExists(teacherID) && attempts < 10 {
            teacherID = generateTeacherID()
            attempts += 1
        }

        if attempts >= 10 {
            throw NSError(domain: "TeacherAuth", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Benzersiz öğretmen ID'si oluşturulamadı. Lütfen tekrar deneyin."
            ])
        }

        // Create teacher document in Firestore
        let teacherData: [String: Any] = [
            "id": teacherID,
            "firstName": firstName,
            "lastName": lastName,
            "school": school,
            "email": email,
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("teachers")
            .document(teacherID)
            .setData(teacherData)

        // Set as current teacher
        self.currentTeacherID = teacherID
        self.isAuthenticated = true

        print("✅ Yeni öğretmen oluşturuldu: \(teacherID)")
        return teacherID
    }

    /// Check if teacher ID already exists in Firestore
    private func teacherIDExists(_ teacherID: String) async throws -> Bool {
        let doc = try await db.collection("teachers")
            .document(teacherID)
            .getDocument()

        return doc.exists
    }

    /// Validate and login with existing teacher ID
    func loginWithTeacherID(_ teacherID: String) async throws {
        // Normalize ID (uppercase, trim)
        let normalizedID = teacherID.uppercased().trimmingCharacters(in: .whitespaces)

        // Validate format (3 letters + 3 numbers)
        guard normalizedID.count == 6 else {
            throw NSError(domain: "TeacherAuth", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Öğretmen ID'si 6 karakter olmalıdır."
            ])
        }

        // Check if exists in Firestore
        let doc = try await db.collection("teachers")
            .document(normalizedID)
            .getDocument()

        guard doc.exists else {
            throw NSError(domain: "TeacherAuth", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Bu öğretmen ID'si bulunamadı."
            ])
        }

        // Set as current teacher
        self.currentTeacherID = normalizedID
        self.isAuthenticated = true

        print("✅ Öğretmen giriş yaptı: \(normalizedID)")
    }

    /// Logout current teacher
    func logout() {
        self.currentTeacherID = nil
        self.currentTeacher = nil
        self.isAuthenticated = false
        print("👋 Öğretmen çıkış yaptı")
    }

    /// Fetch current teacher details from Firestore
    func fetchTeacherDetails() async throws {
        guard let teacherID = currentTeacherID else {
            throw NSError(domain: "TeacherAuth", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Öğretmen ID'si bulunamadı."
            ])
        }

        let doc = try await db.collection("teachers")
            .document(teacherID)
            .getDocument()

        guard let data = doc.data() else {
            throw NSError(domain: "TeacherAuth", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "Öğretmen bilgileri yüklenemedi."
            ])
        }

        // Parse teacher data (simplified, can be improved)
        let firstName = data["firstName"] as? String ?? ""
        let lastName = data["lastName"] as? String ?? ""
        let email = data["email"] as? String ?? ""

        let teacher = Teacher(
            email: email,
            name: "\(firstName) \(lastName)",
            firebaseUID: teacherID
        )

        self.currentTeacher = teacher
    }

    // MARK: - Helper Functions

    /// Generate QR code for teacher ID
    func generateQRCode(for teacherID: String) -> UIImage? {
        let data = teacherID.data(using: .utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")

        guard let ciImage = filter?.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    /// Share teacher ID text
    func shareTeacherID() -> String {
        guard let teacherID = currentTeacherID else {
            return "Öğretmen ID'si bulunamadı"
        }

        return """
        🎓 LGS Kocum PRO - Öğretmen Kodu

        Benim öğretmen kodum: \(teacherID)

        Bu kodu öğrenci uygulamasında girerek bana bağlanabilirsiniz.

        📱 LGS Kocum uygulamasını indirin ve "Öğretmenim Var" seçeneğini seçerek bu kodu girin.
        """
    }
}
