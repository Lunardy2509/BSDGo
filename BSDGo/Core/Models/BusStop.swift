import Foundation
import CoreLocation
import SwiftUI

struct BusStop: Identifiable, Decodable {
    let id: UUID
    var name: String
    let coordinate: CLLocationCoordinate2D
    let color: Color?
    
    var distanceFromUser: CLLocationDistance?
    
    enum CodingKeys: String, CodingKey {
        case name
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        name = try container.decode(String.self, forKey: .name)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        color = nil
    }
    
    init() {
        self.id = UUID()
        self.name = ""
        self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self.color = nil
    }
}

func loadBusStops() -> [BusStop] {
    guard let url = Bundle.main.url(forResource: "Stops", withExtension: "json") else {
        print("Bus Stop JSON file not found")
            return []
    }

    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let stops = try decoder.decode([BusStop].self, from: data)
        return stops
    } catch {
        print("Error decoding Bus Stop JSON: \(error)")
            return []
    }
}

extension BusStop {
    init(id: UUID, name: String, coordinate: CLLocationCoordinate2D, color: Color? = nil, distanceFromUser: CLLocationDistance? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.color = color
        self.distanceFromUser = distanceFromUser
    }
}
