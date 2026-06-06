import SwiftUI

enum DesignTokens {

    enum ColorTokens {
        static let primary       = Color(red: 0.18, green: 0.32, blue: 0.76)
        static let primaryLight  = Color(red: 0.88, green: 0.92, blue: 1.00)
        static let primaryMuted  = Color(red: 0.39, green: 0.49, blue: 0.78)
        static let accent        = Color(red: 0.00, green: 0.55, blue: 0.53)
        static let accentLight   = Color(red: 0.84, green: 0.96, blue: 0.95)

        static let background    = Color(.systemGroupedBackground)
        static let surface       = Color(.secondarySystemGroupedBackground)
        static let surfaceAlt    = Color(.tertiarySystemGroupedBackground)

        static let textPrimary   = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textMuted     = Color(.tertiaryLabel)
        static let textOnPrimary = Color.white

        static let success       = Color(red: 0.08, green: 0.58, blue: 0.30)
        static let warning       = Color(red: 0.88, green: 0.55, blue: 0.08)
        static let destructive   = Color(red: 0.86, green: 0.22, blue: 0.22)

        static let border        = Color(.separator)
        static let divider       = Color(.opaqueSeparator)
        static let shadowTint    = Color(.sRGBLinear, white: 0, opacity: 0.12)
    }

    enum Gradients {
        static let primaryButton = LinearGradient(
            colors: [ColorTokens.primary, Color(red: 0.15, green: 0.55, blue: 0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accentButton = LinearGradient(
            colors: [ColorTokens.accent, Color(red: 0.18, green: 0.67, blue: 0.46)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let background = LinearGradient(
            stops: [
                .init(color: Color(.systemGroupedBackground), location: 0),
                .init(color: Color(red: 0.95, green: 0.97, blue: 1.00), location: 0.55),
                .init(color: Color(red: 0.94, green: 0.98, blue: 0.97), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let success = LinearGradient(
            colors: [ColorTokens.success, Color(red: 0.18, green: 0.68, blue: 0.42)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let shimmer = LinearGradient(
            colors: [Color.white.opacity(0), Color.white.opacity(0.55), Color.white.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let cardHighlight = LinearGradient(
            colors: [Color.white.opacity(0.48), Color.white.opacity(0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Typography {
        static let largeTitle   = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title        = Font.system(.title, design: .rounded).weight(.bold)
        static let title2       = Font.system(.title2, design: .rounded).weight(.semibold)
        static let title3       = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline     = Font.system(.headline, design: .rounded).weight(.semibold)
        static let body         = Font.system(.body, design: .rounded)
        static let bodyBold     = Font.system(.body, design: .rounded).weight(.semibold)
        static let callout      = Font.system(.callout, design: .rounded)
        static let subheadline  = Font.system(.subheadline, design: .rounded)
        static let caption      = Font.system(.caption, design: .rounded)
        static let caption2     = Font.system(.caption2, design: .rounded)
    }

    enum Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat    = 8
        static let md: CGFloat    = 10
        static let lg: CGFloat    = 12
        static let xl: CGFloat    = 16
        static let xxl: CGFloat   = 20
        static let pill: CGFloat  = 9999
    }

    enum Shadow {
        static let subtle: (Color) -> [ShadowStyle] = { tint in [
            .init(color: tint.opacity(0.05), radius: 8, x: 0, y: 4)
        ]}

        static let medium: (Color) -> [ShadowStyle] = { tint in [
            .init(color: tint.opacity(0.06), radius: 14, x: 0, y: 8)
        ]}

        static let elevated: (Color) -> [ShadowStyle] = { tint in [
            .init(color: tint.opacity(0.08), radius: 22, x: 0, y: 14)
        ]}

        static let innerPressed: (Color) -> [ShadowStyle] = { tint in [
            .init(color: tint.opacity(0.04), radius: 3, x: 0, y: 1)
        ]}

        static let glow: (Color) -> [ShadowStyle] = { tint in [
            .init(color: tint.opacity(0.16), radius: 16, x: 0, y: 0)
        ]}

        static let heroGlow: (Color) -> [ShadowStyle] = { tint in [
            .init(color: tint.opacity(0.12), radius: 28, x: 0, y: 10)
        ]}
    }

    enum AnimationDuration {
        static let instant: Double   = 0.10
        static let micro: Double    = 0.15
        static let fast: Double     = 0.20
        static let normal: Double   = 0.30
        static let slow: Double     = 0.40
        static let entrance: Double = 0.50
        static let staggerDelay: Double = 0.04
    }

    enum Spring {
        static let press = Animation.spring(response: 0.28, dampingFraction: 0.75, blendDuration: 0)
        static let cardEntrance = Animation.spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0)
        static let itemStagger = Animation.spring(response: 0.42, dampingFraction: 0.78, blendDuration: 0)
        static let modal = Animation.spring(response: 0.48, dampingFraction: 0.86, blendDuration: 0)
        static let float = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
        static let pulse = Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true)
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func clayShadow(_ shadows: [ShadowStyle]) -> some View {
        var result = AnyView(self)
        for shadow in shadows {
            result = AnyView(result.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y))
        }
        return result
    }
}

enum DesignMatchedGeometry {
    case systemCard
    case levelBadge
}
