//
//  AnimatedBackgroundView.swift
//  DebateFeedback
//
//  Animated background with floating particles and chat bubbles
//

import SwiftUI

struct AnimatedBackgroundView: View {
    @State private var particles: [Particle] = []
    @State private var chatBubbles: [ChatBubble] = []

    var body: some View {
        ZStack {
            // Base gradient background
            Constants.Gradients.background
                .ignoresSafeArea()

            // Animated particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color.opacity(0.15))
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: particle.blur)
                    .position(particle.position)
                    .animation(
                        .linear(duration: particle.duration)
                        .repeatForever(autoreverses: false),
                        value: particle.position
                    )
            }

            // Animated chat bubbles
            ForEach(chatBubbles) { bubble in
                ChatBubbleShape()
                    .stroke(bubble.color.opacity(0.3), lineWidth: 2)
                    .frame(width: bubble.size.width, height: bubble.size.height)
                    .position(bubble.position)
                    .rotationEffect(.degrees(bubble.rotation))
                    .animation(
                        .easeInOut(duration: bubble.duration)
                        .repeatForever(autoreverses: true),
                        value: bubble.position
                    )
            }
        }
        .onAppear {
            generateParticles()
            generateChatBubbles()
        }
    }

    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for _ in 0..<15 {
            let particle = Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                size: CGFloat.random(in: 20...80),
                color: [Constants.Colors.softCyan, Constants.Colors.softPink, Constants.Colors.softPurple].randomElement()!,
                duration: Double.random(in: 8...15),
                blur: CGFloat.random(in: 10...20)
            )
            particles.append(particle)
        }

        // Animate particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for i in 0..<particles.count {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: -100...screenWidth + 100),
                    y: CGFloat.random(in: -100...screenHeight + 100)
                )
            }
        }
    }

    private func generateChatBubbles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for _ in 0..<8 {
            let bubble = ChatBubble(
                position: CGPoint(
                    x: CGFloat.random(in: 50...screenWidth - 50),
                    y: CGFloat.random(in: 50...screenHeight - 50)
                ),
                size: CGSize(
                    width: CGFloat.random(in: 60...120),
                    height: CGFloat.random(in: 50...100)
                ),
                color: [Constants.Colors.softCyan, Constants.Colors.softPink].randomElement()!,
                duration: Double.random(in: 6...12),
                rotation: Double.random(in: -15...15)
            )
            chatBubbles.append(bubble)
        }

        // Animate bubbles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for i in 0..<chatBubbles.count {
                let offsetX = CGFloat.random(in: -50...50)
                let offsetY = CGFloat.random(in: -80...80)
                chatBubbles[i].position = CGPoint(
                    x: chatBubbles[i].position.x + offsetX,
                    y: chatBubbles[i].position.y + offsetY
                )
            }
        }
    }
}

// MARK: - Particle Model

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let duration: Double
    let blur: CGFloat
}

// MARK: - Chat Bubble Model

struct ChatBubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGSize
    let color: Color
    let duration: Double
    let rotation: Double
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Main bubble body (rounded rectangle)
        let bubbleRect = CGRect(x: 0, y: 0, width: width * 0.85, height: height * 0.75)
        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: height * 0.25, height: height * 0.25))

        // Tail pointing down-right
        let tailStart = CGPoint(x: width * 0.2, y: height * 0.75)
        let tailTip = CGPoint(x: width * 0.15, y: height * 0.95)
        let tailEnd = CGPoint(x: width * 0.35, y: height * 0.75)

        path.move(to: tailStart)
        path.addQuadCurve(to: tailEnd, control: tailTip)

        return path
    }
}

#Preview {
    AnimatedBackgroundView()
}
