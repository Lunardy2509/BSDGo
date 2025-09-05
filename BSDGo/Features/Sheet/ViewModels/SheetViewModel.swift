import Foundation
import CoreLocation
import MapKit
import SwiftUI
import SwiftData

@MainActor
class SheetViewModel: ObservableObject {
    @Published var closestStops: [(stop: BusStop, distance: CLLocationDistance)] = []
    @Published var recentSearches: [RecentBusStop] = []

    func refreshStops(from stops: [BusStop], userLocation: CLLocation?) {
        guard let location = userLocation else {
            closestStops = []
            return
        }
        closestStops = Array(
            stops
                .map { stop in
                    let dist = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
                        .distance(from: location)
                    return (stop, dist)
                }
                .sorted(by: { $0.1 < $1.1 })
                .prefix(5)
        )
    }

    func updateDistances(for stops: [BusStop], from location: CLLocation?) -> [BusStop] {
        guard let loc = location else { return stops }

        return stops.map { stop in
            var copy = stop
            copy.distanceFromUser = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
                .distance(from: loc)
            return copy
        }
    }

    func formatDistance(_ meters: CLLocationDistance) -> String {
        meters >= 1000
        ? String(format: "%.1f km Away From You", meters / 1000)
        : "\(Int(meters)) m Away From You"
    }

    func closestStopsList(action: @escaping (BusStop) -> Void) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(closestStops.enumerated()), id: \.offset) { index, entry in
                Button(action: { action(entry.stop) }) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.primary)
                            .font(.system(size: 30))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.stop.name).font(.body)
                            Text(self.formatDistance(entry.distance))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.gray)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < self.closestStops.count - 1 {
                    Divider().padding(.leading, 58)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 0))
        .padding(.horizontal)
    }
    
    func fetchRecentSearches(_ context: ModelContext) {
        do {
            recentSearches = try context.fetch(FetchDescriptor<RecentBusStop>(sortBy: [.init(\.timestamp, order: .reverse)]))
        } catch {
            print("Failed to fetch: \(error)")
        }
    }

    func recentSearchList(recentSearches: [RecentBusStop], action: @escaping (BusStop) -> Void) -> some View {
        let top3 = recentSearches.sorted(by: { $0.timestamp > $1.timestamp }).prefix(3)

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(top3) { item in
                let busStop = BusStop(
                    id: item.id,
                    name: item.name,
                    coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
                )
                Button { action(busStop) } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath").font(.system(size: 24))
                        Text(busStop.name)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider().padding(.leading, 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    func filteredStops(from busStops: [BusStop], searchText: String) -> [BusStop] {
        searchText.isEmpty
        ? busStops
        : busStops.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func filteredStopsList(filtered: [BusStop], action: @escaping (BusStop) -> Void) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(filtered.enumerated()), id: \.1.id) { index, stop in
                VStack(spacing: 0) {
                    Button(action: { action(stop) }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill").font(.system(size: 20))
                            VStack(alignment: .leading) { Text(stop.name).font(.body) }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
                if index < filtered.count - 1 {
                    Divider().padding(.leading, 46)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        .padding(.horizontal)
    }
}
