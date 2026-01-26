import Foundation
import SwiftUI
import MapKit
import UIKit
import WidgetKit

@MainActor
final class MapViewModel: ObservableObject {
    private var isGeneratingSnapshots = false
    private var lastSnapshotTime: Date?
    
    func generateMapSnapshot(userLocation: CLLocation, stops: [BusStop], size: CGSize, fileName: String, completion: (() -> Void)? = nil) {
        let options = configureMapOptions(userLocation: userLocation, size: size, fileName: fileName)
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start { [weak self] snapshot, error in
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    print("Snapshot failed: \(error.localizedDescription)")
                    completion?()
                    return
                }
                
                if let snapshot = snapshot {
                    let finalImage = self.renderSnapshotImage(snapshot, userLocation: userLocation, stops: stops, size: size)
                    Task.detached(priority: .background) {
                        await self.saveSnapshotImage(image: finalImage, fileName: fileName)
                        await MainActor.run {
                            completion?()
                        }
                    }
                } else {
                    completion?()
                }
            }
        }
    }
    
    private func configureMapOptions(userLocation: CLLocation, size: CGSize, fileName: String) -> MKMapSnapshotter.Options {
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
        
        return options
    }
    
//    private func processSnapshot(_ snapshot: MKMapSnapshotter.Snapshot, userLocation: CLLocation, stops: [BusStop], options: MKMapSnapshotter.Options, fileName: String) {
//        UIGraphicsBeginImageContextWithOptions(options.size, false, 0)
//        snapshot.image.draw(at: .zero)
//
//        guard UIGraphicsGetCurrentContext() != nil else { return }
//
//        drawUserAnnotation(snapshot: snapshot, userLocation: userLocation)
//        drawStopAnnotations(snapshot: snapshot, stops: stops)
//    }
//    
    private func renderSnapshotImage(_ snapshot: MKMapSnapshotter.Snapshot, userLocation: CLLocation, stops: [BusStop], size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { _ in
            // 1. Draw Map
            snapshot.image.draw(at: .zero)
            
            // 2. Draw User
            drawUserAnnotation(snapshot: snapshot, userLocation: userLocation)
            
            // 3. Draw Stops
            drawStopAnnotations(snapshot: snapshot, stops: stops)
        }
    }
    
    private func drawUserAnnotation(snapshot: MKMapSnapshotter.Snapshot, userLocation: CLLocation) {
        let userPoint = snapshot.point(for: userLocation.coordinate)
        let userImage = UserAnnotationRenderer.generateImage(size: 30)
        let userRect = CGRect(x: userPoint.x - 15, y: userPoint.y - 15, width: 30, height: 30)
        userImage.draw(in: userRect)
    }
    
    private func drawStopAnnotations(snapshot: MKMapSnapshotter.Snapshot, stops: [BusStop]) {
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
    }
    
    nonisolated private func saveSnapshotImage(image: UIImage, fileName: String) async {
        guard let data = image.pngData(),
              let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.lunardy.BSDGo")?
            .appendingPathComponent(fileName) else { return }
        
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save snapshot: \(error)")
        }
    }

    func getClosestStops(from widgetStops: [WidgetModel], using allStops: [BusStop]) -> [BusStop] {
        widgetStops.compactMap { widgetStop in
            allStops.first(where: { $0.name == widgetStop.name })
        }
    }

    func handleLocationUpdate(location: CLLocation, allStops: [BusStop], locationManager: LocationManager) {
        
        // 1. Calculate and save closest stops immediately
        let widgetModel = locationManager.convertToWidgetModel(from: allStops, userLocation: location)
        if let data = try? JSONEncoder().encode(widgetModel) {
            let defaults = UserDefaults(suiteName: "group.com.lunardy.BSDGo")
            defaults?.set(data, forKey: "closestStops")
        }
        
        // 2. CHECK: Is the GPU busy?
        if isGeneratingSnapshots {
            print("⚠️ Skipping snapshot: GPU is busy.")
            return
        }
        
        // 3. CHECK: Is it too soon? (15 second Throttle)
        if let lastTime = lastSnapshotTime, Date().timeIntervalSince(lastTime) < 15 {
            return
        }
        
        // 4. Start the Sequence
        isGeneratingSnapshots = true
        lastSnapshotTime = Date()
        
        let closestStops = getClosestStops(from: widgetModel, using: allStops)
        
        // Step A: Medium Widget
        generateMapSnapshot(
            userLocation: location,
            stops: closestStops,
            size: CGSize(width: 350, height: 210),
            fileName: "mapSnapshot_medium.png"
        ) { [weak self] in
            
            // Step B: Large Widget (Only starts after Medium finishes)
            self?.generateMapSnapshot(
                userLocation: location,
                stops: closestStops,
                size: CGSize(width: 430, height: 400),
                fileName: "mapSnapshot_large.png"
            ) { [weak self] in
                
                // Step C: Finish
                WidgetCenter.shared.reloadAllTimelines()
                self?.isGeneratingSnapshots = false
            }
        }
    }
    
    struct AnnotationTapResult {
        let selectedStop: BusStop
        let sheetType: SheetType
        let showDefaultSheet: Bool
        let detent: PresentationDetent
    }
    
    func handleAnnotationTap(on stop: BusStop, currentSelection: BusStop?) -> AnnotationTapResult {
        if currentSelection?.id == stop.id {
            return AnnotationTapResult(
                selectedStop: BusStop(),
                sheetType: .defaultView,
                showDefaultSheet: true,
                detent: .fraction(0.10)
            )
        } else {
            return AnnotationTapResult(
                selectedStop: stop,
                sheetType: .busStopDetailView,
                showDefaultSheet: false,
                detent: .medium
            )
        }
    }
    
    struct TapGestureResult {
        let region: MKCoordinateRegion
        let showDetailSheet: Bool
        let showDefaultSheet: Bool
        let sheetType: SheetType
        let detent: PresentationDetent
    }
    
    func handleTapGesture(on stop: BusStop, currentSelection: BusStop?) -> TapGestureResult {
        let unwrappedSelection = currentSelection ?? stop
        let annotationResult = handleAnnotationTap(on: stop, currentSelection: unwrappedSelection)
        
        let newRegion = MKCoordinateRegion(
            center: stop.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        let showDetailSheet = annotationResult.sheetType == .busStopDetailView
        
        return TapGestureResult(
            region: newRegion,
            showDetailSheet: showDetailSheet,
            showDefaultSheet: annotationResult.showDefaultSheet,
            sheetType: annotationResult.sheetType,
            detent: annotationResult.detent
        )
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
