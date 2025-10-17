import SwiftUI

struct TeacherWelcomeView: View {
    @Binding var currentStep: OnboardingStep

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(hex: "667eea"),
                    Color(hex: "764ba2")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 120, height: 120)

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                // Title
                VStack(spacing: 12) {
                    Text("LGS Koçum PRO")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Öğretmen Uygulaması")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }

                // Description
                VStack(spacing: 16) {
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Öğrencilerinizin performansını takip edin"
                    )

                    FeatureRow(
                        icon: "person.badge.clock",
                        text: "Bağlantı isteklerini yönetin"
                    )

                    FeatureRow(
                        icon: "doc.text.magnifyingglass",
                        text: "Detaylı analiz raporları oluşturun"
                    )
                }
                .padding(.horizontal, 30)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    // Yeni Kayıt
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            currentStep = .registration
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Yeni Öğretmen Kaydı")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundStyle(Color(hex: "667eea"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }

                    // Mevcut Giriş
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            currentStep = .login
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("Mevcut Hesabımla Giriş")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 30)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

// MARK: - Onboarding Steps
enum OnboardingStep {
    case welcome
    case registration
    case login
    case complete
}

// MARK: - Preview
#Preview {
    TeacherWelcomeView(currentStep: .constant(.welcome))
}
