import SwiftUI

struct BusRouteView: View {
    @StateObject var viewModel: BusRouteViewModel
    
    @Binding var currentBusStop: BusStop
    @Binding var showRouteDetailSheet: Bool
    @Binding var selectedSheet: SheetType
    
    @State private var showAllSessions: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            headerView
            
            let sessionsToShow = showAllSessions ? viewModel.allSessions : viewModel.upcomingSessions
            let isMainSession = sessionsToShow[viewModel.selectedSessionIndex].session == viewModel.sessionInfo[viewModel.mainSessionIndex].session
            
            if sessionsToShow.count > 1 {
                HStack {
                    Spacer()
                    
                    Picker("Select Session", selection: $viewModel.selectedSessionIndex) {
                        ForEach(sessionsToShow.indices, id: \.self) { idx in
                            Text("Session \(sessionsToShow[idx].session)")
                                .tag(idx)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .tint(.orange)
                    .foregroundColor(.orange)
                    .accentColor(.orange)
                    
                    Spacer()
                }
                .padding(.top, 4)
                
                Toggle("Show All Sessions", isOn: $showAllSessions)
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                    .padding(.horizontal)
            }
            
            if sessionsToShow.isEmpty {
                VStack(spacing: 16) {
                    Text("No sessions found.")
                        .foregroundColor(.gray)
                    dismissButton
                }
                .padding()
            } else {
                let stops = sessionsToShow[viewModel.selectedSessionIndex].stops
                
                if isMainSession {
                    let busIndex = stops.lastIndex(where: {
                        viewModel.stopStatus(for: $0.timeOfArrival) != .upcoming
                    }) ?? 0
                    
                    let userIndex = stops.firstIndex(where: {
                        $0.busStopName == viewModel.currentStopName && viewModel.stopStatus(for: $0.timeOfArrival) == .upcoming
                    }) ?? stops.count - 1
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(stops.enumerated()), id: \.offset) { idx, stop in
                                    buildStopRow(
                                        index: idx,
                                        stop: stop,
                                        busIndex: busIndex,
                                        userIndex: userIndex,
                                        totalCount: stops.count,
                                        scrollProxy: proxy
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                } else {
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
        .onChange(of: showAllSessions) {
            viewModel.selectedSessionIndex = 0
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
    
    @ViewBuilder
    private func buildStopRow(index idx: Int, stop: BusSchedule, busIndex: Int, userIndex: Int, totalCount: Int, scrollProxy: ScrollViewProxy) -> some View {
        let status = viewModel.stopStatus(for: stop.timeOfArrival)
        let isBusHere = idx == busIndex
        let isUserHere = stop.busStopName == viewModel.currentStopName
        let isUserArrived = isBusHere && isUserHere
        
        if idx > busIndex && idx < userIndex && !viewModel.isExpanded {
            if idx == busIndex + 1 {
                HStack {
                    Button(action: {
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                            viewModel.isExpanded = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                scrollProxy.scrollTo(busIndex, anchor: .top)
                            }
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
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                        viewModel.isExpanded = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollProxy.scrollTo(busIndex, anchor: .top)
                        }
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
                isUserArrived: isUserArrived,
                showConnector: idx < totalCount - 1,
                progress: isBusHere ? viewModel.animationProgress : 0
            )
            .id(idx)
        }
    }
}
