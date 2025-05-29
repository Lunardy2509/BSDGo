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
    @Environment(\.widgetFamily) var family

    var snapshotImage: Image? {
        let fileName: String
        switch family {
        case .systemLarge:
            fileName = "mapSnapshot_large.png"
        case .systemMedium:
            fileName = "mapSnapshot_medium.png"
        default:
            return nil
        }

        if let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.lunardy.SwiftRide")?
            .appendingPathComponent(fileName),
           let uiImage = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: uiImage)
        }
        return nil
    }

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                Text("Closest Bus Stops")
                    .font(.caption.bold())
                    .foregroundColor(.primary)

                ForEach(entry.stops.prefix(3), id: \.self) { stop in
                    VStack(alignment: .leading) {
                        Text(stop.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text(stop.distanceText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)

        case .systemMedium:
            ZStack(alignment: .bottomTrailing) {
                if let image = snapshotImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.stops.prefix(2), id: \.self) { stop in
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stop.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text(stop.distanceText)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 20)
                .padding(.trailing, 5
                )
            }
            
        case .systemLarge:
            ZStack {
                if let image = snapshotImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(entry.stops.prefix(2), id: \.self) { stop in
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.primary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(stop.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Text(stop.distanceText)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 10)
                        .padding(.trailing, 110)
                    }
                }
            }
            
        default:
            EmptyView()
        }
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
