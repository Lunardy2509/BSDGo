import SwiftUI

enum StopStatus { case passed, current, upcoming }

struct BusRouteView: View {
    @StateObject var viewModel: BusRouteViewModel

    @Binding var currentBusStop: BusStop
    @Binding var showRouteDetailSheet: Bool
    @Binding var selectedSheet: SheetContentType

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            headerView

            // Session Picker
            if viewModel.upcomingSessions.count > 1 {
                Text("Sessions")
                    .font(.headline)
                Picker("Session", selection: $viewModel.selectedSessionIndex) {
                    ForEach(viewModel.upcomingSessions.indices, id: \.self) { idx in
                        Text("\(viewModel.upcomingSessions[idx].session)")
                            .fontWeight(idx == viewModel.mainSessionIndex ? .bold : .regular)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .tint(.orange)
                .padding(.horizontal)
                .onAppear {
                    viewModel.selectedSessionIndex = viewModel.mainSessionIndex
                }
            }

            // No sessions fallback
            if viewModel.upcomingSessions.isEmpty {
                VStack(spacing: 16) {
                    Text("No upcoming or active sessions.")
                        .foregroundColor(.gray)
                    dismissButton
                }
                .padding()
            } else {
                let stops = viewModel.upcomingSessions[viewModel.selectedSessionIndex].stops

                if viewModel.selectedSessionIndex == viewModel.mainSessionIndex {
                    let busIndex = stops.lastIndex(where: {
                        viewModel.stopStatus(for: $0.timeOfArrival) != .upcoming
                    }) ?? 0

                    let userIndex = stops.firstIndex(where: {
                        $0.busStopName == viewModel.currentStopName && viewModel.stopStatus(for: $0.timeOfArrival) == .upcoming
                    }) ?? stops.count - 1

                    let startIndex = max(busIndex - 3, 0)
                    let endIndex = min(userIndex + 3, stops.count - 1)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(startIndex...endIndex, id: \.self) { idx in
                                let stop = stops[idx]
                                let status = viewModel.stopStatus(for: stop.timeOfArrival)
                                let isBusHere = idx == busIndex
                                let isUserHere = stop.busStopName == viewModel.currentStopName

                                if idx > busIndex && idx < userIndex && !viewModel.isExpanded {
                                    if idx == busIndex + 1 {
                                        HStack {
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.isExpanded = true
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
                                }

                                if idx == userIndex && viewModel.isExpanded {
                                    HStack {
                                        Button(action: {
                                            withAnimation {
                                                viewModel.isExpanded = false
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

                                if viewModel.isExpanded || !(idx > busIndex && idx < userIndex) {
                                    StopRowView(
                                        stop: stop,
                                        status: status,
                                        isBusHere: isBusHere,
                                        isUserHere: isUserHere,
                                        isUserArrived: isBusHere && isUserHere,
                                        showConnector: idx < endIndex
                                    )
                                }
                            }
                        }
                        .padding()
                    }

                } else {
                    // Session is not the main session: show all stops
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(stops.enumerated()), id: \.offset) { _, stop in
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
    }

    private var headerView: some View {
        HStack {
            Text(viewModel.name)
                .font(.title2.bold())
            Spacer()
            dismissButton
        }
        .padding(.horizontal)
        .padding(.top, 30)
        .padding(.bottom, 10)
    }

    private var dismissButton: some View {
        Button(action: {
            selectedSheet = .defaultView
            currentBusStop = BusStop()
            showRouteDetailSheet = false
            dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
        }
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
