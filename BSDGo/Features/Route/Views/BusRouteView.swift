import SwiftUI
import Foundation
import UserNotifications

#if os(iOS)
import UIKit
#endif

// MARK: - Helper Structures
struct StopRowContext {
    let busIndex: Int
    let userIndex: Int
    let totalCount: Int
}

struct BusRouteView: View {
    @StateObject var viewModel: BusRouteViewModel
    
    @Binding var currentBusStop: BusStop
    @Binding var showRouteDetailSheet: Bool
    @Binding var selectedSheet: SheetType
    
    @State private var showAllSessions: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var isIpad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    var body: some View {
        VStack(spacing: 12) {
            headerView
            
            alertSection
            
            let sessionsToShow = showAllSessions ? viewModel.allSessions : viewModel.upcomingSessions
            
            // Ensure selectedSessionIndex is within bounds
            let safeSessionIndex = min(max(viewModel.selectedSessionIndex, 0), max(sessionsToShow.count - 1, 0))
            let safeMainSessionIndex = min(max(viewModel.mainSessionIndex, 0), max(viewModel.sessionInfo.count - 1, 0))
            let isMainSession = sessionsToShow.isEmpty || viewModel.sessionInfo.isEmpty
                ? false
                : sessionsToShow[safeSessionIndex].session == viewModel.sessionInfo[safeMainSessionIndex].session
            
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
                    .background(Color(.secondarySystemBackground))
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
                let stops = sessionsToShow.isEmpty ? [] : sessionsToShow[safeSessionIndex].stops
                
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
                                    context: StopRowContext(
                                        busIndex: busIndex,
                                        userIndex: userIndex,
                                        totalCount: stops.count
                                    ),
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
            // Use the ViewModel's safe method to update session index
            let sessionsToShow = showAllSessions ? viewModel.allSessions : viewModel.upcomingSessions
            viewModel.updateSessionIndexForArrayChange(newArrayCount: sessionsToShow.count, showingAllSessions: showAllSessions)
        }
    }
}
