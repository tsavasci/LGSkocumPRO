import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var authService = TeacherAuthService.shared
    @State private var currentStep: OnboardingStep = .welcome

    var body: some View {
        ZStack {
            // Ekranlar arası geçiş
            Group {
                switch currentStep {
                case .welcome:
                    TeacherWelcomeView(currentStep: $currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                case .registration:
                    TeacherRegistrationView(currentStep: $currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                case .login:
                    TeacherLoginView(currentStep: $currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                case .complete:
                    // Bu durum ana uygulamaya geçişi tetikler
                    // LGS_Kocum_PROApp.swift'te kontrol edilecek
                    Color.clear
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView()
}
