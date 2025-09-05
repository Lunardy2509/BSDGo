import Foundation 

struct BusSchedule: Identifiable, Codable { 
    let id: UUID
    let busStopName: String
    let busNumber: Int
    let timeOfArrival: String
    let session: Int
    

    enum CodingKeys: String, CodingKey { 
        case busStopName = "bus_stop_name" 
        case busNumber = "bus_number" 
        case timeOfArrival = "time_of_arrival"
        case session
    }
    
    init(from decoder: Decoder) throws { 
        let container = try decoder.container(keyedBy: CodingKeys.self) 
        id = UUID()
        busStopName = try container.decode(String.self, forKey: .busStopName)
        busNumber = try container.decode(Int.self, forKey: .busNumber)
        timeOfArrival = try container.decode(String.self, forKey: .timeOfArrival)
        session = try container.decode(Int.self, forKey: .session)
    }
} 

func loadBusSchedules() -> [BusSchedule] {
   guard let url = Bundle.main.url(forResource: "Schedule", withExtension: "json") else { 
       print("Bus Schedule JSON file not found")
       return [] 
   } 

   do {
       let data = try Data(contentsOf: url)
       let busSchedules = try JSONDecoder().decode([BusSchedule].self, from: data)
       return busSchedules
   } catch { 
       print("Error decoding Bus Schedule JSON: \(error)")
       return [] 
   }
} 
