import SwiftUI

struct TeacherLoginView: View {
    @Binding var currentStep: OnboardingStep
    @StateObject private var authService = TeacherAuthService.shared

    @State private var teacherID: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var isFormValid: Bool {
        teacherID.count == 6
    }

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(hex: "667eea").opacity(0.1),
                    Color(hex: "764ba2").opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Mevcut Hesapla Giriş")
                        .font(.title.bold())
                        .foregroundStyle(.primary)

                    Text("Daha önce oluşturduğunuz öğretmen kodunuzu girin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // ID Input
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Öğretmen Kodu", systemImage: "key.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("ABC123", text: $teacherID)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .textCase(.uppercase)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                            .onChange(of: teacherID) { oldValue, newValue in
                                // Limit to 6 characters
                                if newValue.count > 6 {
                                    teacherID = String(newValue.prefix(6))
                                }
                            }

                        HStack(spacing: 4) {
                            Image(systemName: teacherID.count == 6 ? "checkmark.circle.fill" : "info.circle")
                                .foregroundStyle(teacherID.count == 6 ? .green : .secondary)
                                .font(.caption)

                            Text("6 karakter (3 harf + 3 rakam)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Info Box
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kodunuzu unuttuysanız?")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text("Öğretmen kodunuz e-posta veya SMS ile size gönderilmiş olabilir. Bulamadıysanız yeni kayıt oluşturabilirsiniz.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    // Giriş Yap Butonu
                    Button {
                        loginTeacher()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Giriş Yap")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isFormValid
                                ? LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: isFormValid ? .blue.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!isFormValid || isLoading)

                    // Geri Butonu
                    Button {
                        withAnimation(.spring()) {
                            currentStep = .welcome
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Geri Dön")
                        }
                        .foregroundStyle(.secondary)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Functions

    private func loginTeacher() {
        isLoading = true

        Task {
            do {
                try await authService.loginWithTeacherID(teacherID)

                await MainActor.run {
                    withAnimation(.spring()) {
                        currentStep = .complete
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TeacherLoginView(currentStep: .constant(.login))
}
