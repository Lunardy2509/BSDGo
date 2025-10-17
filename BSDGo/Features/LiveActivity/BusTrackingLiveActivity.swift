import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Widget
struct BusTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BusTrackingModel.self) { context in
            // Lock screen/banner UI
            BusTrackingLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Image(systemName: "bus.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("Bus \(context.attributes.busNumber)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.arrivalTimeDisplay)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Arrival")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        HStack {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(context.state.formattedRemainingTime)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        
                        Text(context.attributes.destinationStop)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                                                // Compact progress bar
                        ProgressView(value: context.state.currentProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                Image(systemName: "bus.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .medium))
            } compactTrailing: {
                Text(context.state.arrivalTimeDisplay)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } minimal: {
                Image(systemName: "bus.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
            }
        }
    }
}

// MARK: - Lock Screen View
struct BusTrackingLockScreenView: View {
    let context: ActivityViewContext<BusTrackingModel>
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app branding
            HStack {
                Text("BSDGo")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Main content
            VStack(spacing: 12) {
                // Arrival time section
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You will arrive at")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text(context.state.arrivalTimeDisplay)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                
                // Destination
                HStack {
                    Text(context.attributes.destinationStop)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                
                // Progress bar with icons
                HStack(spacing: 8) {
                    // Start icon (green line)
                    Rectangle()
                        .fill(.green)
                        .frame(width: 4, height: 12)
                        .cornerRadius(2)
                    
                    // Progress track
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            // Progress fill
                            Rectangle()
                                .fill(.green)
                                .frame(width: max(0, CGFloat(context.state.currentProgress) * geometry.size.width), height: 4)
                                .cornerRadius(2)
                                .animation(.easeInOut(duration: 0.5), value: context.state.currentProgress)
                            
                            // Bus icon on progress
                            HStack {
                                Spacer()
                                    .frame(width: max(0, CGFloat(context.state.currentProgress) * geometry.size.width - 12))
                                
                                Circle()
                                    .fill(.white)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(
                                        Image(systemName: "bus.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.orange)
                                    )
                                    .animation(.easeInOut(duration: 0.5), value: context.state.currentProgress)
                                
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 20)
                    
                    // End icon (destination pin)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Helper Functions
private func colorFromHex(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let red, green, blue: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
        (red, green, blue) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
        (red, green, blue) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
    default:
        (red, green, blue) = (255, 165, 0) // Orange fallback
    }
    return Color(
        .sRGB,
        red: Double(red) / 255,
        green: Double(green) / 255,
        blue: Double(blue) / 255,
        opacity: 1
    )
}

// MARK: - Bus Icon View
struct BusIconView: View {
    let busColor: String
    let size: CGFloat
    
    init(busColor: String, size: CGFloat = 28) {
        self.busColor = busColor
        self.size = size
    }
    
    var body: some View {
        Image(systemName: "bus.fill")
            .foregroundColor(colorFromHex(busColor))
            .font(.system(size: size))
    }
}

// MARK: - Custom Progress View Style
struct BusProgressViewStyle: ProgressViewStyle {
    let busColor: String
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 4)
                .cornerRadius(2)
            
            Rectangle()
                .fill(colorFromHex(busColor))
                .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * 200, height: 4)
                .cornerRadius(2)
        }
    }
}
