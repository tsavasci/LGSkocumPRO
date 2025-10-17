import SwiftUI

struct PendingRequestsView: View {
    @StateObject private var syncManager = FirestoreSyncManager.shared
    @StateObject private var firestoreService = FirestoreService.shared
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Group {
                if syncManager.pendingRequests.isEmpty {
                    emptyStateView
                } else {
                    requestsList
                }
            }
            .navigationTitle("Bekleyen İstekler")
            .navigationBarTitleDisplayMode(.large)
            .alert("Bildirim", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Bekleyen İstek Yok")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Öğrenciler sizinle bağlantı kurmak için istek gönderdiğinde burada görünecektir.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Requests List
    private var requestsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(syncManager.pendingRequests) { request in
                    PendingRequestCard(
                        request: request,
                        onApprove: {
                            approveRequest(request)
                        },
                        onReject: {
                            rejectRequest(request)
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func approveRequest(_ request: PendingRequest) {
        isProcessing = true

        Task {
            do {
                try await firestoreService.approveStudentRequest(
                    requestID: request.id.uuidString,
                    studentID: request.studentID
                )

                // Not: Öğrenci uygulaması Firestore listener ile otomatik algılayacak

                await MainActor.run {
                    alertMessage = "\(request.studentName) başarıyla onaylandı!"
                    showAlert = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Onaylama hatası: \(error.localizedDescription)"
                    showAlert = true
                    isProcessing = false
                }
            }
        }
    }

    private func rejectRequest(_ request: PendingRequest) {
        isProcessing = true

        Task {
            do {
                try await firestoreService.rejectStudentRequest(
                    requestID: request.id.uuidString,
                    studentID: request.studentID
                )

                // Not: Öğrenci uygulaması Firestore listener ile otomatik algılayacak

                await MainActor.run {
                    alertMessage = "\(request.studentName) isteği reddedildi."
                    showAlert = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Reddetme hatası: \(error.localizedDescription)"
                    showAlert = true
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Pending Request Card
struct PendingRequestCard: View {
    let request: PendingRequest
    let onApprove: () -> Void
    let onReject: () -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.studentName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(request.studentSchool)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Time badge
                Text(timeAgo(from: request.createdAt))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                // Reject button
                Button {
                    isProcessing = true
                    onReject()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reddet")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isProcessing)

                // Approve button
                Button {
                    isProcessing = true
                    onApprove()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Onayla")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helper Functions

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 {
            return day == 1 ? "1 gün önce" : "\(day) gün önce"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 saat önce" : "\(hour) saat önce"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 dakika önce" : "\(minute) dakika önce"
        } else {
            return "Az önce"
        }
    }
}

// MARK: - Preview
#Preview {
    PendingRequestsView()
}
