import SwiftUI

struct StopRowView: View {
    let stop: BusSchedule
    let status: StopStatus
    let isBusHere: Bool
    let isUserHere: Bool
    let isUserArrived: Bool
    let showConnector: Bool
    let progress: CGFloat // NEW

    var body: some View {
        HStack(alignment: .top) {
            VStack {
                if isBusHere {
                    ZStack {
                        Color.clear.frame(width: 40, height: 40)
                        BusIcon()
                            .offset(y: 30 * progress)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                } else if isUserHere {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                } else {
                    Circle()
                        .fill(status == .passed ? Color.gray : Color.orange)
                        .frame(width: 40, height: 40)
                }

                if showConnector {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 30)
                }
            }
            .padding(.horizontal, 10)

            Text(stop.busStopName)
                .font(isBusHere ? .title3.bold() : .title3)
                .foregroundColor(isBusHere ? .primary : (status == .passed ? .gray : .primary))
                .frame(height: 40)

            Spacer()

            Text(stop.timeOfArrival)
                .font(.title2.bold())
                .foregroundColor(isBusHere ? .primary : (status == .passed ? .gray : .primary))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .frame(height: 40)
        }
    }
}
