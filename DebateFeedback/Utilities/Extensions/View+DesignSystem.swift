//
//  View+DesignSystem.swift
//  DebateFeedback
//
//  Clean, minimal design system with soft colors and pill-shaped buttons
//

import SwiftUI

// MARK: - Pill Button Style (Primary)

struct PillButtonStyle: ButtonStyle {
    let color: Color
    let isEnabled: Bool
    let style: PillStyle

    enum PillStyle {
        case filled
        case outlined
    }

    init(color: Color = Constants.Colors.softCyan, isEnabled: Bool = true, style: PillStyle = .filled) {
        self.color = color
        self.isEnabled = isEnabled
        self.style = style
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
                Group {
                    if style == .filled {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(isEnabled ? color : Color.gray.opacity(0.3))
                    } else {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(isEnabled ? color : Color.gray.opacity(0.3), lineWidth: 2)
                    }
                }
            )
            .foregroundColor(style == .filled ? .white : (isEnabled ? color : Color.gray))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Legacy Gradient Button (for compatibility)

struct GradientButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let isEnabled: Bool

    init(gradient: LinearGradient = Constants.Gradients.primaryButton, isEnabled: Bool = true) {
        self.gradient = gradient
        self.isEnabled = isEnabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        isEnabled
                        ? gradient
                        : LinearGradient(
                            colors: [Constants.Colors.backgroundSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .foregroundColor(isEnabled ? .white : Constants.Colors.primaryBlue)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.9)
    }
}

// MARK: - Soft Card Modifier (Clean, minimal)

struct SoftCardModifier: ViewModifier {
    let backgroundColor: Color
    let borderColor: Color?
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                Group {
                    if let borderColor = borderColor {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1.5)
                    }
                }
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Legacy modifiers (for compatibility)

struct NeonBorderModifier: ViewModifier {
    let color: Color
    let lineWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

struct GlassmorphismModifier: ViewModifier {
    let borderColor: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Constants.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply clean pill button style
    func pillButton(color: Color = Constants.Colors.softCyan, isEnabled: Bool = true, style: PillButtonStyle.PillStyle = .filled) -> some View {
        self.buttonStyle(PillButtonStyle(color: color, isEnabled: isEnabled, style: style))
    }

    /// Apply soft card style with optional border
    func softCard(backgroundColor: Color = Constants.Colors.cardBackground, borderColor: Color? = nil, cornerRadius: CGFloat = 20) -> some View {
        self.modifier(SoftCardModifier(backgroundColor: backgroundColor, borderColor: borderColor, cornerRadius: cornerRadius))
    }

    /// Legacy: gradient button style
    func gradientButtonStyle(gradient: LinearGradient = Constants.Gradients.primaryButton, isEnabled: Bool = true) -> some View {
        self.buttonStyle(GradientButtonStyle(gradient: gradient, isEnabled: isEnabled))
    }

    /// Legacy: neon border
    func neonBorder(color: Color = Constants.Colors.softCyan, lineWidth: CGFloat = 2) -> some View {
        self.modifier(NeonBorderModifier(color: color, lineWidth: lineWidth))
    }

    /// Legacy: glassmorphism
    func glassmorphism(borderColor: Color = Constants.Colors.softCyan) -> some View {
        self.modifier(GlassmorphismModifier(borderColor: borderColor))
    }
}

// MARK: - Gradient Text Modifier

struct GradientText: View {
    let text: String
    let gradient: LinearGradient

    init(_ text: String, gradient: LinearGradient = Constants.Gradients.primaryButton) {
        self.text = text
        self.gradient = gradient
    }

    var body: some View {
        Text(text)
            .foregroundStyle(gradient)
    }
}

// MARK: - Toggle Style with Gradient

struct GradientToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Constants.Gradients.primaryButton : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 51, height: 31)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(3)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
