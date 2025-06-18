import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var scaleUp = false
    @State private var glow = false
    
    let AppIcon = Image("SWRD Icon")

    var body: some View {
        if isActive {
            MapView()
        } else {
            VStack {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 220, height: 220)
                        .blur(radius: glow ? 30 : 10)
                        .opacity(glow ? 1 : 0.5)
                        .scaleEffect(glow ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glow)

                    AppIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .scaleEffect(scaleUp ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: scaleUp)
                }

                Text("SwiftRide")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 16)

                Spacer()
            }
            .onAppear {
                scaleUp = true
                glow = true

                // Transition delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}


#Preview {
    SplashView()
}
