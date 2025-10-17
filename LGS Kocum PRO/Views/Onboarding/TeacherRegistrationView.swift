import SwiftUI

struct TeacherRegistrationView: View {
    @Binding var currentStep: OnboardingStep
    @StateObject private var authService = TeacherAuthService.shared

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var school: String = ""
    @State private var email: String = ""

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var generatedID: String?

    var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !school.isEmpty
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

            VStack(spacing: 0) {
                // ScrollView içeriği
                ScrollView {
                    VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Yeni Öğretmen Kaydı")
                            .font(.title.bold())
                            .foregroundStyle(.primary)

                        Text("Bilgilerinizi girerek öğretmen hesabı oluşturun")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 20) {
                        // İsim
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Ad", systemImage: "person.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("Örn: Ahmet", text: $firstName)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.givenName)
                                .autocorrectionDisabled()
                        }

                        // Soyisim
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Soyad", systemImage: "person.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("Örn: Yılmaz", text: $lastName)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.familyName)
                                .autocorrectionDisabled()
                        }

                        // Okul
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Okul", systemImage: "building.2.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("Örn: Atatürk Ortaokulu", text: $school)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocorrectionDisabled()
                        }

                        // Email (Opsiyonel)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("E-posta (Opsiyonel)", systemImage: "envelope.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("İsteğe bağlı")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }

                            TextField("ornek@okul.edu.tr", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        // Info Box
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)

                            Text("Size özel bir öğretmen kodu oluşturulacak. Öğrencileriniz bu kodu kullanarak size bağlanabilir.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)

                    // Generated ID Display (if created)
                    if let generatedID = generatedID {
                        VStack(spacing: 12) {
                            Text("Öğretmen Kodunuz Oluşturuldu!")
                                .font(.headline)
                                .foregroundStyle(.green)

                            Text(generatedID)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text("Bu kodu öğrencilerinizle paylaşabilirsiniz")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button {
                                withAnimation(.spring()) {
                                    currentStep = .complete
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Başlayalım")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical)
                    }

                        Spacer(minLength: 20)
                    }
                }

                // Bottom Buttons (ScrollView dışında, her zaman görünsün)
                if generatedID == nil {
                    VStack(spacing: 12) {
                        // Kayıt Ol Butonu
                        Button {
                            createTeacher()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "person.badge.plus")
                                    Text("Kayıt Ol")
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
                            .padding(.vertical, 8)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        Color(.systemBackground)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                    )
                }
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Functions

    private func createTeacher() {
        isLoading = true

        Task {
            do {
                let teacherID = try await authService.createTeacher(
                    firstName: firstName,
                    lastName: lastName,
                    school: school,
                    email: email
                )

                await MainActor.run {
                    withAnimation(.spring()) {
                        generatedID = teacherID
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

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview
#Preview {
    TeacherRegistrationView(currentStep: .constant(.registration))
}
