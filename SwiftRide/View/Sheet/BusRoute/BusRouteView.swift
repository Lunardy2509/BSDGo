import SwiftUI

// Enhanced BusRouteView: Picker shows next/upcoming sessions, icons only in main session, others show full route
enum StopStatus { case passed, current, upcoming }

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
    @State private var selectedSessionIndex: Int = 0

    // Precompute session details: only upcoming or ongoing sessions
    private var sessionInfo: [(session: Int, stops: [BusSchedule], firstDate: Date, lastDate: Date)] {
        let calendar = Calendar.current
        let now = Date()
        let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()

        return Dictionary(grouping: busSchedule.filter { $0.busNumber == busNumber }, by: { $0.session })
            .compactMap { session, stops in
                let sorted = stops.sorted { $0.timeOfArrival < $1.timeOfArrival }
                let dates = sorted.compactMap { stop -> Date? in
                    guard let t = formatter.date(from: stop.timeOfArrival) else { return nil }
                    var comps = calendar.dateComponents([.year, .month, .day], from: now)
                    let timeComps = calendar.dateComponents([.hour, .minute], from: t)
                    comps.hour = timeComps.hour; comps.minute = timeComps.minute
                    return calendar.date(from: comps)
                }
                guard let first = dates.first, let last = dates.last, last >= now else {
                    return nil // skip sessions that ended
                }
                return (session: session, stops: sorted, firstDate: first, lastDate: last)
            }
            .sorted { $0.firstDate < $1.firstDate }
    }

    private var upcomingSessions: [(session: Int, stops: [BusSchedule])] {
        sessionInfo.map { ($0.session, $0.stops) }
    }

    private var mainSessionIndex: Int {
        let now = Date()
        return sessionInfo.firstIndex(where: { now >= $0.firstDate && now <= $0.lastDate }) ?? 0
    }

    private func stopStatus(for timeString: String) -> StopStatus {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard let t = formatter.date(from: timeString) else { return .upcoming }
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        let tc = calendar.dateComponents([.hour, .minute], from: t)
        comps.hour = tc.hour; comps.minute = tc.minute
        guard let stopDate = calendar.date(from: comps) else { return .upcoming }

        if calendar.isDate(stopDate, equalTo: now, toGranularity: .minute) {
            return .current
        } else if stopDate < now {
            return .passed
        } else {
            return .upcoming
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            headerView

            // Picker under the title
            if upcomingSessions.count > 1 {
                Text("Sessions")
                    .font(.headline)
                Picker("Session", selection: $selectedSessionIndex) {
                    ForEach(upcomingSessions.indices, id: \.self) { idx in
                        Text("\(upcomingSessions[idx].session)")
                            .fontWeight(idx == mainSessionIndex ? .bold : .regular)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .tint(.orange)
                .padding(.horizontal)
                .onAppear { selectedSessionIndex = mainSessionIndex }
            }

            if upcomingSessions.isEmpty {
                VStack(spacing: 16) {
                    Text("No upcoming or active sessions.")
                        .foregroundColor(.gray)
                    dismissButton
                }
                .padding()
            }

            let stops = upcomingSessions[selectedSessionIndex].stops

            if selectedSessionIndex == mainSessionIndex {
                let busIndex = stops.lastIndex(where: { stopStatus(for: $0.timeOfArrival) != .upcoming }) ?? 0
                let userIndex = stops.firstIndex(where: { $0.busStopName == currentStopName && stopStatus(for: $0.timeOfArrival) == .upcoming }) ?? stops.count - 1
                let startIndex = max(busIndex - 3, 0)
                let endIndex = min(userIndex + 3, stops.count - 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(startIndex...endIndex, id: \.self) { idx in
                            let stop = stops[idx]
                            let status = stopStatus(for: stop.timeOfArrival)
                            let isBusHere = idx == busIndex
                            let isUserHere = stop.busStopName == currentStopName

                            if idx > busIndex && idx < userIndex && !isExpanded {
                                if idx == busIndex + 1 {
                                    HStack {
                                        Button(action: {
                                            withAnimation(.interpolatingSpring(stiffness: 120, damping: 12)) {
                                                isExpanded = true
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "chevron.down")
                                                Text("\(userIndex - busIndex - 1) stops remaining")
                                            }
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 25)
                                        }
                                        Spacer()
                                    }
                                }
                            } else {
                                StopRowView(
                                    stop: stop,
                                    status: status,
                                    isBusHere: isBusHere,
                                    isUserHere: isUserHere,
                                    isUserArrived: isBusHere && isUserHere,
                                    showConnector: idx < endIndex
                                )

                                if idx == userIndex && isExpanded {
                                    HStack {
                                        Button(action: {
                                            withAnimation(.interpolatingSpring(stiffness: 120, damping: 12)) {
                                                isExpanded = false
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "chevron.up")
                                                Text("Hide stops")
                                            }
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 25)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                            HStack {
                                Text(stop.busStopName)
                                Spacer()
                                Text(stop.timeOfArrival)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text(name)
                .font(.title2.bold())
            Spacer()
            dismissButton
        }
        .padding(.horizontal)
        .padding(.top, 30)
        .padding(.bottom, 10)
    }

    private var dismissButton: some View {
        Button(action: closeView) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
        }
    }

    private func closeView() {
        selectedSheet = .defaultView
        currentBusStop = BusStop()
        showRouteDetailSheet = false
        dismiss()
    }
}


struct StopRowView: View {
    let stop: BusSchedule
    let status: StopStatus
    let isBusHere: Bool
    let isUserHere: Bool
    let isUserArrived: Bool
    let showConnector: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack {
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
