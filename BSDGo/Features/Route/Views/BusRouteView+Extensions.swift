import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#endif

// MARK: - BusRouteView Helper Methods
extension BusRouteView {
    
    @ViewBuilder
    func buildStopRow(
        index idx: Int,
        stop: BusSchedule,
        context: StopRowContext,
        scrollProxy: ScrollViewProxy,
        stops: [BusSchedule]
    ) -> some View {
        let status = viewModel.stopStatus(for: stop.timeOfArrival)
        let isBusHere = idx == context.busIndex
        let isUserHere = stop.busStopName == viewModel.currentStopName
        let isUserArrived = isBusHere && isUserHere
        
        buildExpandCollapseButtons(
            idx: idx,
            context: context,
            scrollProxy: scrollProxy,
            stops: stops
        )
        
        if viewModel.isExpanded || !(idx > context.busIndex && idx < context.userIndex) {
            StopRowView(
                stop: stop,
                status: status,
                isBusHere: isBusHere,
                isUserHere: isUserHere,
                isUserArrived: isUserArrived,
                showConnector: idx < context.totalCount - 1,
                progress: isBusHere ? viewModel.animationProgress : 0
            )
            .id(stop.id)
        }
    }
    
    @ViewBuilder
    func buildExpandCollapseButtons(
        idx: Int,
        context: StopRowContext,
        scrollProxy: ScrollViewProxy,
        stops: [BusSchedule]
    ) -> some View {
        if idx > context.busIndex && idx < context.userIndex && !viewModel.isExpanded {
            if idx == context.busIndex + 1 {
                let targetStopID = stops[context.busIndex].id
                buildExpandButton(targetID: targetStopID, context: context, scrollProxy: scrollProxy)
            }
        }
        
        if idx == context.userIndex && viewModel.isExpanded {
            let targetStopID = stops[context.busIndex].id
            buildCollapseButton(targetID: targetStopID, scrollProxy: scrollProxy)
        }
    }
    
    @ViewBuilder
    func buildExpandButton(
        targetID: AnyHashable,
        context: StopRowContext,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        HStack {
            Button(action: {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                    viewModel.isExpanded = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo(targetID, anchor: .top)
                    }
                }
            }, label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                    Text("\(context.userIndex - context.busIndex - 1) stops remaining")
                }
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal, 25)
            })
            Spacer()
        }
    }
    
    @ViewBuilder
    func buildCollapseButton(
        targetID: AnyHashable,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        HStack {
            Button(action: {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                    viewModel.isExpanded = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo(targetID, anchor: .top)
                    }
                }
            }, label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.up")
                    Text("Hide stops")
                }
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal, 25)
            })
            Spacer()
        }
    }
}

// MARK: - BusRouteView UI Components
extension BusRouteView {
    
    var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(viewModel.name)
                    .font(.title2.bold())
                
                Spacer()
                dismissButton
            }
        }
        .padding(.horizontal)
        .padding(.top, 30)
        .padding(.bottom, 10)
    }
    
    var alertSection: some View {
        VStack(spacing: 0) {
            if viewModel.isTimerRunning {
                // Running Timer Display
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("Bus Alert: \(viewModel.formattedRemainingTime)")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Cancel") {
                        viewModel.stopAlertTimer()
                        if viewModel.isLiveActivityEnabled {
                            viewModel.stopLiveActivity()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                // Set Alert Button
                HStack {
                    Button(action: {
                        viewModel.showAlertPicker.toggle()
                    }, label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.orange)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.orange.opacity(0.4))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                                        )
                                        .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                            Text("Set Bus Alert")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(.leading, 4)
                    })
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $viewModel.showAlertPicker) {
            alertPickerSheet
        }
    }
    
    var dismissButton: some View {
        Button(action: {
            selectedSheet = .defaultView
            currentBusStop = BusStop()
            showRouteDetailSheet = false
            // Don't call dismiss() - let state management handle the sheet content
        }, label: {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
        })
    }
    
    // MARK: - Alert Picker Sheet
    var alertPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Alert Notification")
                    .font(.title2.bold())
                    .padding(.top)
                
                Text("Get notified when it's time for your bus to arrive at \(viewModel.currentStopName)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Time Picker
                VStack(spacing: 16) {
                    Text("Alert me in:")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        // Hours
                        VStack {
                            Text("Hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("Hours", selection: $viewModel.alertHours) {
                                ForEach(0...23, id: \.self) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 100)
                            .clipped()
                        }
                        
                        // Minutes
                        VStack {
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("Minutes", selection: $viewModel.alertMinutes) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 100)
                            .clipped()
                        }
                        
                        // Seconds
                        VStack {
                            Text("Seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("Seconds", selection: $viewModel.alertSeconds) {
                                ForEach(0...59, id: \.self) { second in
                                    Text("\(second)").tag(second)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 100)
                            .clipped()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.startAlertTimer()
                        viewModel.startLiveActivity()
                        viewModel.showAlertPicker = false
                    }, label: {
                        Text("Set Alert")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    })
                    .disabled(viewModel.alertHours == 0 && viewModel.alertMinutes == 0 && viewModel.alertSeconds == 0)
                    
                    Button("Cancel") {
                        viewModel.showAlertPicker = false
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
