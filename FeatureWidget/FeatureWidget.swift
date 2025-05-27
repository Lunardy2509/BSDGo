import WidgetKit
import SwiftUI
import CoreLocation

// MARK: - Widget Provider.swift
struct SimpleEntry: TimelineEntry {
    let date: Date
    let stops: [WidgetModel]
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
        let stops: [WidgetModel]
        
        if let data = UserDefaults(suiteName: "group.com.lunardy.SwiftRide")?.data(forKey: "closestStops"),
           let decoded = try? JSONDecoder().decode([WidgetModel].self, from: data) {
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
            Text("Closest Bus Stops")
                .font(.caption.bold())
                .foregroundColor(.primary)
            ForEach(entry.stops.prefix(3), id: \.self) { stop in
                VStack(alignment: .leading) {
                    HStack {
                        Text(stop.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(stop.distanceText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
let previewStops: [WidgetModel] = [
    WidgetModel(name: "Polsek Serpong", distanceText: "100 m"),
    WidgetModel(name: "Santa Ursula 2", distanceText: "300 m")
]

#Preview(as: .systemSmall) {
    FeatureWidget()
} timeline: {
    SimpleEntry(date: .now, stops: previewStops)
}
