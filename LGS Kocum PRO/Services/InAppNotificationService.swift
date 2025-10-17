import Foundation
import SwiftUI

/// In-app notification banner servisi (Push notification olmadan)
@MainActor
class InAppNotificationService: ObservableObject {
    static let shared = InAppNotificationService()

    @Published var showNotification = false
    @Published var notificationTitle = ""
    @Published var notificationMessage = ""
    @Published var notificationType: NotificationType = .info

    enum NotificationType {
        case success
        case info
        case warning

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return .green
            case .info: return .blue
            case .warning: return .orange
            }
        }
    }

    private init() {}

    func show(title: String, message: String, type: NotificationType = .info) {
        notificationTitle = title
        notificationMessage = message
        notificationType = type
        showNotification = true

        // 3 saniye sonra otomatik kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showNotification = false
        }
    }
}

// MARK: - In-App Notification Banner View

struct InAppNotificationBanner: View {
    @ObservedObject var service = InAppNotificationService.shared

    var body: some View {
        VStack {
            if service.showNotification {
                HStack(spacing: 12) {
                    Image(systemName: service.notificationType.icon)
                        .font(.title2)
                        .foregroundStyle(service.notificationType.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.notificationTitle)
                            .font(.headline)

                        Text(service.notificationMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        service.showNotification = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .animation(.spring(), value: service.showNotification)
    }
}
