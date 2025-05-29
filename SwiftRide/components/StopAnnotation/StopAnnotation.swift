import MapKit
import SwiftUI

struct StopAnnotation: View {
    var isSelected: Bool

    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Image(systemName: "mappin.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(.teal)
                    .frame(width: 25, height: 25)
                    .scaleEffect(isSelected ? 1.5 : 1.0)
                    .animation(.interpolatingSpring(stiffness: 300, damping: 10), value: isSelected)

            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10, weight: .black))
                .offset(x: 0, y: -5)
        }
        .compositingGroup()
        .scaleEffect(self.isSelected ? 1.5 : 1, anchor: .bottom)
    }
}

#Preview {
    StopAnnotation(isSelected: false)
}
