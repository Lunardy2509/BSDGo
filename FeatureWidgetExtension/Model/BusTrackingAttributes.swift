import ActivityKit
import Foundation

// MARK: - Live Activity Attributes
struct BusTrackingModel: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic content that updates
        var estimatedArrival: Date
        var currentProgress: Double // 0.0 to 1.0
        var remainingTime: TimeInterval
        var busStatus: BusStatus
        var isOnTheWay: Bool
        
        enum BusStatus: String, Codable, CaseIterable {
            case approaching = "Approaching"
            case onTheWay = "On the way"
            case arriving = "Arriving"
            case arrived = "Arrived"
            
            var emoji: String {
                switch self {
                case .approaching: return "🚌"
                case .onTheWay: return "🛣️"
                case .arriving: return "⏰"
                case .arrived: return "✅"
                }
            }
            
            var color: String {
                switch self {
                case .approaching: return "#FF6B35"
                case .onTheWay: return "#4CAF50"
                case .arriving: return "#FF9800"
                case .arrived: return "#2196F3"
                }
            }
        }
    }
    
    // Static content (doesn't change during the activity)
    var busName: String
    var busNumber: Int
    var licensePlate: String
    var destinationStop: String
    var busColor: String // Hex color
    var startTime: Date
}

extension BusTrackingModel.ContentState {
    var formattedRemainingTime: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    var formattedArrivalTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: estimatedArrival)
    }
    
    var arrivalTimeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: estimatedArrival)
    }
}
