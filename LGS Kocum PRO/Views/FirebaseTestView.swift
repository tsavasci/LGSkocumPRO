import SwiftUI
import FirebaseCore
import FirebaseFirestore
import SwiftData

@MainActor
class FirebaseTestViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var message = ""
    @Published var showAlert = false
    @Published var connectionStatus = "Bekliyor..."
    @Published var syncStatus = ""
    @Published var fetchStatus = ""

    private let firestoreService = FirestoreService.shared
    private let syncManager = FirestoreSyncManager.shared

    func testFirestoreConnection() async {
        isLoading = true
        connectionStatus = "Bağlanıyor..."

        do {
            let db = Firestore.firestore()

            // Test verisi oluştur
            let testData: [String: Any] = [
                "timestamp": Timestamp(date: Date()),
                "message": "Test - Firestore Bağlantısı",
                "appVersion": "1.0.0"
            ]

            // Firestore'a test verisi gönder
            let docRef = try await db.collection("tests").addDocument(data: testData)

            connectionStatus = "Bağlantı başarılı!"
            message = "Firestore bağlantısı çalışıyor!\n\nTest verisi ID: \(docRef.documentID)"
            showAlert = true
        } catch {
            connectionStatus = "Bağlantı başarısız"
            message = "Hata: \(error.localizedDescription)"
            showAlert = true
        }

        isLoading = false
    }

    func syncAllStudentsToFirestore(students: [Student]) async {
        guard !students.isEmpty else {
            syncStatus = "Senkronize edilecek öğrenci yok"
            return
        }

        isLoading = true
        syncStatus = "Senkronize ediliyor..."

        do {
            try await firestoreService.syncAllDataToFirestore(students: students)

            syncStatus = "Senkronizasyon başarılı!"
            message = "\(students.count) öğrenci ve tüm verileri Firestore'a senkronize edildi."
            showAlert = true
        } catch {
            syncStatus = "Senkronizasyon başarısız"
            message = "Hata: \(error.localizedDescription)"
            showAlert = true
        }

        isLoading = false
    }

    func fetchAllDataFromFirestore(modelContext: ModelContext) async {
        isLoading = true
        fetchStatus = "Veriler çekiliyor..."

        do {
            try await syncManager.fetchAndImportAllData(modelContext: modelContext)

            fetchStatus = "Veri çekme başarılı!"
            message = "Firestore'dan tüm öğrenci verileri başarıyla alındı ve lokal veritabanına kaydedildi."
            showAlert = true
        } catch {
            fetchStatus = "Veri çekme başarısız"
            message = "Hata: \(error.localizedDescription)"
            showAlert = true
        }

        isLoading = false
    }
}

struct FirebaseTestView: View {
    @StateObject private var viewModel = FirebaseTestViewModel()
    @Query(sort: \Student.lastName) private var students: [Student]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Modern Gradient Background
            LinearGradient(
                colors: [
                    Color(hex: "667eea").opacity(0.05),
                    Color(hex: "764ba2").opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status Card
                    VStack(spacing: 12) {
                        Image(systemName: viewModel.connectionStatus == "Bağlantı başarılı!" ? "checkmark.circle.fill" : "circle.dashed")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                viewModel.connectionStatus == "Bağlantı başarılı!" ? .green : .secondary
                            )

                        Text(viewModel.connectionStatus)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

                    // Test Connection Button
                    Button {
                        Task {
                            await viewModel.testFirestoreConnection()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading && viewModel.syncStatus.isEmpty {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "network")
                            }
                            Text("Firestore Bağlantısını Test Et")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)

                    // Divider
                    Divider()
                        .padding(.vertical, 10)

                    // Fetch Data from Firestore Button
                    Button {
                        Task {
                            await viewModel.fetchAllDataFromFirestore(modelContext: modelContext)
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading && !viewModel.fetchStatus.isEmpty {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "icloud.and.arrow.down.fill")
                            }
                            Text("Firestore'dan Verileri Çek")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)

                    // Fetch Status Card
                    if !viewModel.fetchStatus.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: viewModel.fetchStatus == "Veri çekme başarılı!" ? "checkmark.circle.fill" : "arrow.down.circle")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    viewModel.fetchStatus == "Veri çekme başarılı!" ? .green : .orange
                                )

                            Text(viewModel.fetchStatus)
                                .font(.callout.bold())
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                    }

                    // Divider
                    Divider()
                        .padding(.vertical, 10)

                    // Sync Status Card
                    if !viewModel.syncStatus.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: viewModel.syncStatus == "Senkronizasyon başarılı!" ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    viewModel.syncStatus == "Senkronizasyon başarılı!" ? .green : .blue
                                )

                            Text(viewModel.syncStatus)
                                .font(.callout.bold())
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                    }

                    // Student Count Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lokal Veriler")
                            .font(.headline)
                            .foregroundStyle(Color.primaryGradient)

                        HStack {
                            Label("\(students.count) Öğrenci", systemImage: "person.2.fill")
                            Spacer()
                            Label("\(students.reduce(0) { $0 + $1.practiceExams.count }) Sınav", systemImage: "doc.text.fill")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)

                    // Sync All Data Button
                    Button {
                        Task {
                            await viewModel.syncAllStudentsToFirestore(students: students)
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading && !viewModel.syncStatus.isEmpty {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "icloud.and.arrow.up.fill")
                            }
                            Text("Tüm Verileri Firestore'a Senkronize Et")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading || students.isEmpty)

                    if students.isEmpty {
                        Text("Senkronize edilecek öğrenci yok. Önce öğrenci ekleyin.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Firestore Test")
        .alert("Sonuç", isPresented: $viewModel.showAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.message)
        }
    }
}

#Preview {
    NavigationView {
        FirebaseTestView()
    }
}