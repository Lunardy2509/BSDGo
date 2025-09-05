import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tip = CGPoint(x: rect.midX, y: rect.minY) // top center
        let left = CGPoint(x: rect.minX, y: rect.maxY) // bottom left
        let right = CGPoint(x: rect.maxX, y: rect.maxY) // bottom right

        path.move(to: tip)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()

        return path
    }
}
