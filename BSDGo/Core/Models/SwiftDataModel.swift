import Foundation
import SwiftData

@Model
final class RecentBusStop {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date

    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double, timestamp: Date = .now) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}
