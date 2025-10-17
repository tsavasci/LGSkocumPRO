import Foundation
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications
import UIKit

/// Teacher App - Bildirim Yönetimi Servisi
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var fcmToken: String?
    @Published var isAuthorized = false

    private let db = Firestore.firestore()

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Bildirimleri başlat
    func setup() {
        requestAuthorization()
        Messaging.messaging().delegate = self
    }

    /// Bildirim izni iste
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            Task { @MainActor in
                self.isAuthorized = granted
                if granted {
                    print("✅ [NotificationService] Bildirim izni verildi")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("❌ [NotificationService] Bildirim izni reddedildi")
                }
            }
        }

        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - FCM Token Management

    /// FCM token'ı al ve kaydet (APNS token hazır olana kadar bekle)
    func getFCMToken() async {
        // APNS token için 2 saniye bekle
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        do {
            let token = try await Messaging.messaging().token()
            await MainActor.run {
                self.fcmToken = token
                print("🔑 [NotificationService] FCM Token: \(token)")
            }

            // Teacher'ın Firebase kaydına token'ı ekle
            await saveFCMTokenToFirebase(token)
        } catch {
            print("❌ [NotificationService] FCM Token alınamadı: \(error.localizedDescription)")
            print("ℹ️  APNS token henüz hazır değil olabilir. Push Notifications capability eklendi mi?")
        }
    }

    /// FCM token'ı Firebase'e kaydet
    private func saveFCMTokenToFirebase(_ token: String) async {
        guard let teacherID = TeacherAuthService.shared.currentTeacherID else {
            print("⚠️ [NotificationService] Teacher ID bulunamadı, token kaydedilemedi")
            return
        }

        do {
            try await db.collection("teachers")
                .document(teacherID)
                .updateData([
                    "fcmToken": token,
                    "lastTokenUpdate": Timestamp(date: Date())
                ])

            print("✅ [NotificationService] FCM Token Firebase'e kaydedildi")
        } catch {
            print("❌ [NotificationService] FCM Token Firebase'e kaydedilemedi: \(error)")
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        Task { @MainActor in
            self.fcmToken = token
            print("🔄 [NotificationService] FCM Token güncellendi: \(token)")
            await saveFCMTokenToFirebase(token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Uygulama açıkken bildirim gelirse
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📬 [NotificationService] Bildirim alındı (foreground): \(notification.request.content.title)")

        // Uygulama açıkken de göster
        completionHandler([.banner, .sound, .badge])
    }

    /// Bildirime tıklandığında
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 [NotificationService] Bildirime tıklandı: \(userInfo)")

        completionHandler()
    }
}
