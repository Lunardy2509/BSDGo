import WidgetKit
import SwiftUI
import CoreLocation

// MARK: - Widget Provider.swift
struct SimpleEntry: TimelineEntry {
    let date: Date
    let stops: [WidgetBusStop]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), stops: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), stops: previewStops))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let stops: [WidgetBusStop]
        

        if let data = UserDefaults(suiteName: "group.com.lunardy.SwiftRide")?.data(forKey: "closestStops"),
           let decoded = try? JSONDecoder().decode([WidgetBusStop].self, from: data) {
            stops = decoded
        } else {
            stops = []
        }

        let entry = SimpleEntry(date: currentDate, stops: stops)
        completion(Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(15 * 60))))
    }
}

// MARK: - Widget View
struct FeatureWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Closest Bus Stops (\(entry.stops.count))")
                .font(.caption.bold())
                .foregroundColor(.primary)
            ForEach(entry.stops.prefix(3), id: \.self) { stop in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundColor(.primary)
                        Text(stop.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text(stop.distanceText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(8)
    }
}

// MARK: - Widget Declaration
struct FeatureWidget: Widget {
    let kind: String = "FeatureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FeatureWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

// MARK: - Preview Data
let previewStops: [WidgetBusStop] = [
    WidgetBusStop(name: "Central Station", distanceText: "250 m"),
    WidgetBusStop(name: "Green Park", distanceText: "400 m"),
    WidgetBusStop(name: "Museum Stop", distanceText: "700 m")
]

#Preview(as: .systemSmall) {
    FeatureWidget()
} timeline: {
    SimpleEntry(date: .now, stops: previewStops)
}
