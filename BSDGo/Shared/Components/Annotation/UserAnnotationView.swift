import SwiftUI
import CoreLocation

struct UserAnnotationView: View {
    var heading: CLLocationDirection

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 44, height: 44)

            // Middle ring
            Circle()
                .fill(Color.blue.opacity(0.5))
                .frame(width: 30, height: 30)

            // Inner circle
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)

            // Direction triangle
            Triangle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .offset(y: -15)
                .rotationEffect(.degrees(heading))
                .shadow(radius: 1)
        }
    }
}
