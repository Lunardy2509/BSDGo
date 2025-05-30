import UIKit
import CoreGraphics

struct UserAnnotationRenderer {
    static func generateImage(size: CGFloat = 40) -> UIImage {
        let glowRadius = size / 2
        let whiteCircleRadius = glowRadius * 0.6
        let blueDotRadius = glowRadius * 0.35

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            let ctx = context.cgContext
            ctx.saveGState()

            let center = CGPoint(x: size / 2, y: size / 2)

            // Outer glow (soft blue)
            ctx.setFillColor(UIColor.systemBlue.withAlphaComponent(0.4).cgColor)
            ctx.addArc(center: center, radius: glowRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ctx.fillPath()

            // Middle solid white circle
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.addArc(center: center, radius: whiteCircleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ctx.fillPath()

            // Inner blue dot (slightly larger)
            ctx.setFillColor(UIColor.systemBlue.cgColor)
            ctx.addArc(center: center, radius: blueDotRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ctx.fillPath()

            ctx.restoreGState()
        }
    }
}
