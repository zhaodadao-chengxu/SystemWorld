import SwiftUI

struct AppScreen<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            DesignTokens.Gradients.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    PageHeader(title: title, subtitle: subtitle)
                    content
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.sm)
                .padding(.bottom, 104)
            }
        }
    }
}

struct PageHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.largeTitle)
                .foregroundColor(DesignTokens.ColorTokens.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DesignTokens.Spacing.md)
    }
}

struct ClayCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = DesignTokens.Radius.xl
    var padding: CGFloat = DesignTokens.Spacing.lg

    init(cornerRadius: CGFloat = DesignTokens.Radius.xl, padding: CGFloat = DesignTokens.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignTokens.ColorTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(DesignTokens.ColorTokens.border.opacity(0.28), lineWidth: 0.5)
            )
            .clayShadow(DesignTokens.Shadow.subtle(DesignTokens.ColorTokens.shadowTint))
    }
}

struct SummaryBand<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Gradients.primaryButton)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl))
            .clayShadow(DesignTokens.Shadow.heroGlow(DesignTokens.ColorTokens.primary))
    }
}

struct ClayButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var variant: ButtonVariant = .primary
    var isLoading: Bool = false
    var disabled: Bool = false

    enum ButtonVariant {
        case primary, secondary, accent, ghost

        var fg: Color {
            switch self {
            case .primary, .accent: return .white
            case .secondary: return DesignTokens.ColorTokens.primary
            case .ghost: return DesignTokens.ColorTokens.textSecondary
            }
        }
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: variant.fg))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(isLoading ? "处理中..." : title)
                    .font(DesignTokens.Typography.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(variant.fg)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .disabled(disabled || isLoading)
        .buttonStyle(ClayPressStyle())
        .opacity((disabled || isLoading) ? 0.5 : 1)
    }

    private var buttonBackground: some View {
        Group {
            switch variant {
            case .primary:
                DesignTokens.Gradients.primaryButton
            case .accent:
                DesignTokens.Gradients.accentButton
            case .secondary:
                DesignTokens.ColorTokens.primaryLight
            case .ghost:
                Color.clear
            }
        }
    }
}

struct ClaySmallButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var variant: ClayButton.ButtonVariant = .primary

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(title).font(DesignTokens.Typography.caption.weight(.semibold))
            }
            .foregroundColor(variant == .primary || variant == .accent ? .white : DesignTokens.ColorTokens.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(height: 34)
            .background(
                Group {
                    if variant == .accent {
                        DesignTokens.Gradients.accentButton
                    } else if variant == .primary {
                        DesignTokens.Gradients.primaryButton
                    } else {
                        DesignTokens.ColorTokens.primaryLight
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(ClayPressStyle())
    }
}

struct ClayPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignTokens.Spring.press, value: configuration.isPressed)
    }
}

struct LevelBadge: View {
    let level: Int
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill").font(.system(size: 10))
            Text("Lv.\(level)").font(DesignTokens.Typography.caption.weight(.bold))
            Text(name).font(DesignTokens.Typography.caption2.weight(.semibold))
        }
        .foregroundColor(DesignTokens.ColorTokens.success)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .frame(height: 28)
        .background(DesignTokens.ColorTokens.success.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

struct CoinBadge: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bitcoinsign.circle.fill")
            Text("\(amount)").font(DesignTokens.Typography.subheadline.monospacedDigit().weight(.semibold))
        }
        .foregroundColor(DesignTokens.ColorTokens.warning)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .frame(height: 30)
        .background(DesignTokens.ColorTokens.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

struct StarRating: View {
    let rating: Int
    let maxStars: Int
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxStars, id: \.self) { i in
                Image(systemName: i < rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(i < rating ? DesignTokens.ColorTokens.warning : DesignTokens.ColorTokens.border)
            }
        }
    }
}

struct AnimatedProgressBar: View {
    let progress: Double
    var tint: Color = DesignTokens.ColorTokens.success
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(tint.opacity(0.14))
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(tint)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))))
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: progress)
    }
}

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.ColorTokens.textPrimary)
            Spacer()
            if let action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignTokens.ColorTokens.textMuted)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(ClayPressStyle())
            }
        }
    }
}

struct FunEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionLabel: String = ""

    var body: some View {
        ClayCard {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(DesignTokens.ColorTokens.primaryMuted)
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let action, !actionLabel.isEmpty {
                    ClaySmallButton(title: actionLabel, icon: "plus", action: action)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
    }
}

struct StatusChip: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(text).font(DesignTokens.Typography.caption2.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .frame(height: 24)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}

struct MetricTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(DesignTokens.Typography.headline.monospacedDigit())
                .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(DesignTokens.Typography.caption2)
                .foregroundColor(DesignTokens.ColorTokens.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.ColorTokens.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var tint: Color = DesignTokens.ColorTokens.primary
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.subheadline.weight(.semibold))
                    .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(DesignTokens.Typography.caption.weight(.semibold))
                    .foregroundColor(tint)
            }
        }
    }
}

struct FloatingBlob: View {
    let color: Color
    let size: CGFloat
    let offset: CGPoint

    var body: some View {
        Circle()
            .fill(color.opacity(0.08))
            .frame(width: size, height: size)
            .blur(radius: size * 0.28)
            .offset(x: offset.x, y: offset.y)
            .allowsHitTesting(false)
    }
}

struct FloatingSparkles: View {
    var body: some View { EmptyView() }
}

struct ShimmerSkeleton: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
            .fill(DesignTokens.ColorTokens.border.opacity(0.25))
            .overlay(
                GeometryReader { geo in
                    DesignTokens.Gradients.shimmer
                        .frame(width: geo.size.width)
                        .offset(x: phase * geo.size.width)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct BouncyIcon: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(color)
            .frame(width: size * 1.8, height: size * 1.8)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl))
    }
}

extension View {
    func staggerEntrance(index: Int) -> some View {
        self
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(DesignTokens.Spring.itemStagger.delay(Double(index) * DesignTokens.AnimationDuration.staggerDelay), value: index)
    }
}
