import SwiftUI

struct BusIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundStyle(.yellow)
                .shadow(radius: 1)
            Image(systemName: "bus")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.black)
                .frame(width: 25, height: 25)
        }
    }
}
