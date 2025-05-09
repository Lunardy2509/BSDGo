import SwiftUI

enum StopStatus {
    case passed, current, upcoming
}

struct BusRouteView: View {
    private let buses: [Bus] = loadBuses()
    private let busSchedule: [BusSchedule] = loadBusSchedules()

    let name: String
    let busNumber: Int
    let currentStopName: String

    @Binding var currentBusStop: BusStop
    @Binding var showRouteDetailSheet: Bool
    @Binding var selectedSheet: SheetContentType

    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded: Bool = false

    private var selectedBus: Bus? {
        buses.first { $0.name == name }
    }

    private var currentSessionSchedule: [(session: Int, stops: [BusSchedule])] {
        let calendar = Calendar.current
        let now = Date()
        
        // Just For Testing
//        var components = calendar.dateComponents([.year, .month, .day], from: now)
//            components.hour = 12
//            components.minute = 0
//            components.second = 0
//        let constNow = calendar.date(from: components)!
        // Just for Testing
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let filtered = busSchedule.filter { $0.busNumber == busNumber }
        let grouped = Dictionary(grouping: filtered, by: { $0.session })

        for (session, stops) in grouped {
            let arrivalDates: [Date] = stops.compactMap { stop in
                guard let timeOnly = formatter.date(from: stop.timeOfArrival) else { return nil }
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnly)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                return calendar.date(from: components)
            }.sorted()

            guard let first = arrivalDates.first, let last = arrivalDates.last else { continue }

            if now >= first && now <= last {
                let sortedStops = stops.sorted { $0.timeOfArrival < $1.timeOfArrival }
                var seenStops = Set<String>()
                let uniqueUpcomingStops = sortedStops.filter { stop in
                    let status = stopStatus(for: stop.timeOfArrival)
                    let isUpcoming = status == .upcoming
                    let isNew = !seenStops.contains(stop.busStopName)
                    if isUpcoming && isNew {
                        seenStops.insert(stop.busStopName)
                        return true
                    }
                    return status != .upcoming
                }
                return [(session: session, stops: uniqueUpcomingStops)]
            }
        }
        return []
    }

    private func stopStatus(for timeString: String) -> StopStatus {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH.mm"
        let now = formatter.string(from: Date())

        guard let currentTime = formatter.date(from: now),
              let stopTime = formatter.date(from: timeString.replacingOccurrences(of: ":", with: ".")) else {
            return .upcoming
        }

        if stopTime < currentTime {
            return .passed
        } else if Calendar.current.isDate(stopTime, equalTo: currentTime, toGranularity: .minute) {
            return .current
        } else {
            return .upcoming
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    if currentSessionSchedule.isEmpty {
                        HStack {
                            Spacer()
                            Button {
                                selectedSheet = .defaultView
                                currentBusStop = BusStop()
                                showRouteDetailSheet = false
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                        Text("There is no running session currently.")
                            .foregroundStyle(.gray)
                            .padding()
                    } else {
                        ForEach(currentSessionSchedule, id: \.session) { group in
                            let busIndex = group.stops.firstIndex(where: { stopStatus(for: $0.timeOfArrival) == .current }) ?? 0
                            let userIndex = group.stops.firstIndex(where: { $0.busStopName == currentStopName && stopStatus(for: $0.timeOfArrival) == .upcoming }) ?? group.stops.count - 1
                            let hiddenRange = (busIndex + 1)..<userIndex

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(name)
                                        .font(.title2.bold())
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                    Button {
                                        selectedSheet = .defaultView
                                        currentBusStop = BusStop()
                                        showRouteDetailSheet = false
                                        dismiss()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.gray)
                                            .padding()
                                    }
                                }

                                ForEach(Array(group.stops.enumerated()), id: \.offset) { index, stop in
                                    let status = stopStatus(for: stop.timeOfArrival)
                                    let isUserHere = stop.busStopName == currentStopName && status == .upcoming
                                    let isBusHere = index == busIndex
                                    let isHidden = hiddenRange.contains(index) && !isExpanded

                                    if isHidden {
                                        if index == busIndex + 1 {
                                            HStack(alignment: .center) {
                                                Button(action: { isExpanded = true }) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "chevron.down")
                                                        Text("\(userIndex - busIndex - 1) stops remaining")
                                                            .font(.headline)
                                                    }
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 25)
                                                }
                                                Spacer()
                                            }
                                        }
                                    } else {
                                        StopRowView(stop: stop, index: index, isUserHere: isUserHere, isBusHere: isBusHere, status: status, showConnector: index < group.stops.count - 1)

                                        if index == userIndex && isExpanded {
                                            HStack {
                                                Button(action: { isExpanded = false }) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "chevron.up")
                                                        Text("Hide stops")
                                                            .font(.headline)
                                                    }
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 25)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct StopRowView: View {
    let stop: BusSchedule
    let index: Int
    let isUserHere: Bool
    let isBusHere: Bool
    let status: StopStatus
    let showConnector: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack() {
                Group {
                    if isBusHere {
                        BusIcon()
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
                .foregroundColor(status == .passed ? .gray : .primary)
                .frame(height: 40, alignment: .center)

            Spacer()

            Text(stop.timeOfArrival)
                .font(.title2.bold())
                .foregroundColor(status == .passed ? Color.gray : Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .cornerRadius(5)
                .frame(height: 40, alignment: .center)
        }
    }
}

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


#Preview {
    BusRouteView(
        name: "Intermoda - Sektor 1.3",
        busNumber: 2,
        currentStopName: "The Breeze",
        currentBusStop: .constant(BusStop()),
        showRouteDetailSheet: .constant(false),
        selectedSheet: .constant(.defaultView)
    )
}
