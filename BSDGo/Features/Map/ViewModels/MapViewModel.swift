import Foundation
import SwiftUI
import MapKit
import UIKit
import WidgetKit

@MainActor
class MapViewModel: ObservableObject {
    func generateMapSnapshot(userLocation: CLLocation, stops: [BusStop], size: CGSize, fileName: String) {
        let options = MKMapSnapshotter.Options()
        
        // Apply offset only for medium widget
        let isMediumWidget = fileName.contains("medium")
        let offset: Double = isMediumWidget ? -0.004 : 0.0

        let offsetCoordinate = CLLocationCoordinate2D(
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude + offset
        )

        options.region = MKCoordinateRegion(
            center: offsetCoordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        options.size = size
        options.scale = UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot else {
                return
            }

            UIGraphicsBeginImageContextWithOptions(options.size, false, 0)
            snapshot.image.draw(at: .zero)

            guard UIGraphicsGetCurrentContext() != nil else {
                return
            }

            let userPoint = snapshot.point(for: userLocation.coordinate)
            let userImage = UserAnnotationRenderer.generateImage(size: 30)
            let userRect = CGRect(
                x: userPoint.x - 15,
                y: userPoint.y - 15,
                width: 30,
                height: 30
            )
            userImage.draw(in: userRect)

            for stop in stops.prefix(2) {
                let point = snapshot.point(for: stop.coordinate)
                let stopIcon = UIImage(systemName: "mappin.circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                if let icon = stopIcon {
                    Self.drawStyledPin(
                        at: point,
                        icon: icon,
                        backgroundColor: UIColor(red: 239/255, green: 140/255, blue: 0/255, alpha: 1),
                        label: stop.name
                    )
                }
            }

            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let data = finalImage?.pngData(),
               let url = FileManager.default
                   .containerURL(forSecurityApplicationGroupIdentifier: "group.com.lunardy.BSDGo")?
                   .appendingPathComponent(fileName) {
                do {
                    try data.write(to: url)
                } catch {
                }
            } else {
            }
        }
    }

    func getClosestStops(from widgetStops: [WidgetModel], using allStops: [BusStop]) -> [BusStop] {
        widgetStops.compactMap { widgetStop in
            allStops.first(where: { $0.name == widgetStop.name })
        }
    }

    func handleLocationUpdate(location: CLLocation, allStops: [BusStop], locationManager: LocationManager) {
        // Trigger the widget to reload its timeline
        WidgetCenter.shared.reloadAllTimelines()
        
        let widgetModel = locationManager.convertToWidgetModel(from: allStops, userLocation: location)
        let closestStops = getClosestStops(from: widgetModel, using: allStops)
        
        // Save closestStops (WidgetModel) to App Group
        if let data = try? JSONEncoder().encode(widgetModel) {
            let defaults = UserDefaults(suiteName: "group.com.lunardy.BSDGo")
            defaults?.set(data, forKey: "closestStops")
        }
        
        // Save snapshot images
        generateMapSnapshot(userLocation: location, stops: closestStops, size: CGSize(width: 350, height: 210), fileName: "mapSnapshot_medium.png")
        generateMapSnapshot(userLocation: location, stops: closestStops, size: CGSize(width: 430, height: 400), fileName: "mapSnapshot_large.png")
    }
    
    
    func handleAnnotationTap(on stop: BusStop, currentSelection: BusStop?) -> (BusStop, SheetType, Bool, PresentationDetent) {
        if currentSelection?.id == stop.id {
            return (BusStop(), .defaultView, true, .fraction(0.10))
        } else {
            return (stop, .busStopDetailView, false, .medium)
        }
    }
    
    func handleTapGesture(on stop: BusStop, currentSelection: BusStop?) -> (MKCoordinateRegion, Bool, Bool, SheetType, PresentationDetent) {
        let unwrappedSelection = currentSelection ?? stop
        let (_, newSheet, newDefaultSheet, newDetent) = handleAnnotationTap(on: stop, currentSelection: unwrappedSelection)
        
        let newRegion = MKCoordinateRegion(
            center: stop.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        let showDetailSheet = newSheet == .busStopDetailView
        
        return (newRegion, showDetailSheet, newDefaultSheet, newSheet, newDetent)
    }
    
    private static func drawStyledPin(
        at point: CGPoint,
        icon: UIImage,
        backgroundColor: UIColor,
        label: String? = nil
    ) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let pinSize: CGFloat = 24
        let iconSize: CGFloat = 18
        let labelOffset: CGFloat = 6

        let iconRect = CGRect(
            x: point.x - iconSize / 2,
            y: point.y - iconSize / 2,
            width: iconSize,
            height: iconSize
        )

        let pinRect = CGRect(
            x: point.x - pinSize / 2,
            y: point.y - pinSize / 2,
            width: pinSize,
            height: pinSize
        )

        // Shadow/glow
        context.setShadow(offset: .zero, blur: 6, color: backgroundColor.withAlphaComponent(0.5).cgColor)

        // Glowing pin circle
        let pinPath = UIBezierPath(ovalIn: pinRect)
        backgroundColor.setFill()
        pinPath.fill()

        // Icon
        icon.draw(in: iconRect)

        // Label below pin (truncated)
        if let label = label {
            let truncatedLabel = label.count > 20 ? String(label.prefix(17)) + "…" : label
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            let textSize = truncatedLabel.size(withAttributes: attributes)
            let textRect = CGRect(
                x: point.x - textSize.width / 2,
                y: point.y + labelOffset,
                width: textSize.width,
                height: textSize.height
            )

            truncatedLabel.draw(in: textRect, withAttributes: attributes)
        }
    }
}
