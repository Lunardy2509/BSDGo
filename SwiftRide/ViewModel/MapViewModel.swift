import Foundation
import SwiftUI
import MapKit
import UIKit

@MainActor
class MapViewModel: ObservableObject {
    func generateMapSnapshot(userLocation: CLLocation, stops: [BusStop], size: CGSize, fileName: String) {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        options.size = size
        options.scale = UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot else {
                print("❌ Failed to create snapshot: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            UIGraphicsBeginImageContextWithOptions(options.size, true, 0)
            snapshot.image.draw(at: .zero)

            let context = UIGraphicsGetCurrentContext()

            let userPoint = snapshot.point(for: userLocation.coordinate)
            Self.drawPin(context: context, at: userPoint, color: .systemBlue)

            for stop in stops.prefix(2) {
                let point = snapshot.point(for: stop.coordinate)
                Self.drawPin(context: context, at: point, color: .black)
            }

            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let data = finalImage?.pngData() {
                let url = FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.lunardy.SwiftRide")?
                    .appendingPathComponent(fileName)

                do {
                    try data.write(to: url!)
                    print("✅ Snapshot saved to App Group as \(fileName)")
                } catch {
                    print("❌ Failed to save snapshot: \(error.localizedDescription)")
                }
            }
        }
    }

    func getClosestStops(from widgetStops: [WidgetModel], using allStops: [BusStop]) -> [BusStop] {
        widgetStops.compactMap { widgetStop in
            allStops.first(where: { $0.name == widgetStop.name })
        }
    }

    func handleLocationUpdate(location: CLLocation, allStops: [BusStop], locationManager: LocationManager) {
        let widgetModel = locationManager.convertToWidgetModel(from: allStops, userLocation: location)
        let closestStops = getClosestStops(from: widgetModel, using: allStops)

        generateMapSnapshot(userLocation: location, stops: closestStops, size: CGSize(width: 300, height: 180), fileName: "mapSnapshot_medium.png") // Medium Widget
        generateMapSnapshot(userLocation: location, stops: closestStops, size: CGSize(width: 400, height: 300), fileName: "mapSnapshot_large.png") // Large Widget
    }

    func handleAnnotationTap(on stop: BusStop, currentSelection: BusStop) -> (BusStop, SheetContentType, Bool, PresentationDetent) {
        if currentSelection.id == stop.id {
            return (BusStop(), .defaultView, true, .fraction(0.1))
        } else {
            return (stop, .busStopDetailView, false, .medium)
        }
    }

    private static func drawPin(context: CGContext?, at point: CGPoint, color: UIColor) {
        context?.setFillColor(color.cgColor)
        context?.fillEllipse(in: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12))
    }
}
