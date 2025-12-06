import Foundation
import SwiftUI

struct Bus: Identifiable, Decodable {
    let id: UUID
    let name: String
    let number: Int
    let licensePlate: String
    let color: AdaptiveColor
    var schedule: [BusSchedule]
    
    enum Codnames: String, CodingKey {
        case name = "bus_name"
        case number = "bus_number"
        case licensePlate = "license_plate"
        case color = "bus_color"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Codnames.self)
        id = UUID()
        name = try container.decode(String.self, forKey: .name)
        number = try container.decode(Int.self, forKey: .number)
        licensePlate = try container.decode(String.self, forKey: .licensePlate)
        let hexString = try container.decode(String.self, forKey: .color)
        color = AdaptiveColor.fromHex(light: hexString)
        schedule = []
    }
    
    init() {
        self.id = UUID()
        self.name = ""
        self.number = 0
        self.licensePlate = ""
        self.color = AdaptiveColor(light: .gray, dark: .gray)
        self.schedule = []
    }
    
    func assignSchedule(schedules: [BusSchedule]) -> Bus {
        var updatedSelf = self
        
        for schedule in schedules {
            if schedule.busNumber != self.number { continue }
            updatedSelf.schedule.append(schedule)
        }
        return updatedSelf
    }
    
    func getClosestArrivalTime(from timestring: String) -> TimeInterval? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let today = Date()
        let calendar = Calendar.current
        
        guard let timeDate = formatter.date(from: timestring) else { return nil }
        
        let components = calendar.dateComponents([.hour, .minute], from: timeDate)
        
        guard let todayWithTime = calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: today
        ) else { return nil }
        
        // returns time interval in seconds
        return todayWithTime.timeIntervalSinceNow
    }
}

struct AdaptiveColor {
    let light: Color
    let dark: Color
    
    func resolvedColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? dark : light
    }
    
    static func fromHex(light: String, dark: String? = nil) -> AdaptiveColor {
        let lightColor = Color(hex: light) ?? .gray
        let darkColor: Color
        if let darkHex = dark {
            darkColor = Color(hex: darkHex) ?? .gray
        } else {
            darkColor = lightColor.darker()
        }
        return AdaptiveColor(light: lightColor, dark: darkColor)
    }
}

extension Color {
    init?(hex: String) {
        guard hex.count == 6,
              let int = UInt64(hex, radix: 16) else {
            return nil
        }
        
        let red = Double((int >> 16) & 0xFF) / 255.0
        let green = Double((int >> 8) & 0xFF) / 255.0
        let blue = Double(int & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    func darker(amount: Double = 0.2) -> Color {
        return self.opacity(1.0 - amount)
    }
}

func loadBuses() -> [Bus] {
    guard let url = Bundle.main.url(forResource: "Bus", withExtension: "json") else {
        print("Bus.json not found")
        return []
    }
    
    do {
        let data = try Data(contentsOf: url)
        let buses = try JSONDecoder().decode([Bus].self, from: data)
        return buses
    } catch {
        print("Error reading Bus.json: \(error)")
        return[]
    }
}
