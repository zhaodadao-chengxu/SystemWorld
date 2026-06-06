import SwiftUI

// MARK: - Press Effect with Spring Physics (Clay Style)

/// Standard press effect — subtle scale squish with spring animation
/// Use for clay cards and general interactive elements
struct PressEffect: ButtonStyle {
    let bg: Color
    @State private var pressed = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Press Card (for interactive cards)

/// Card-specific press — gentler spring for larger surfaces
struct PressCard: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Scale Feedback Modifier

/// Attach to any view for haptic + scale press feedback
struct ScaleFeedback: ViewModifier {
    @State private var pressed = false
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.92 : 1.0)
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { pressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
                }
                action()
            }
    }
}

// MARK: - Clay Press (adds subtle inner shadow feel via brightness)

/// Clay-specific press — reduces brightness to simulate inner shadow
struct ClayPressModifier: ViewModifier {
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.96 : 1.0)
            .brightness(pressed ? -0.03 : 0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
                    }
            )
    }
}

extension View {
    func clayPress() -> some View {
        modifier(ClayPressModifier())
    }
}
