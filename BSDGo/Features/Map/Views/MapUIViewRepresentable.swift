import UIKit
import SwiftUI
import MapKit

struct MapUIViewRepresentable: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D
    @Binding var userHeading: CLLocationDirection
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Add the initial user annotation
        let annotation = context.coordinator.userAnnotation
        annotation.coordinate = userLocation
        mapView.addAnnotation(annotation)

        return mapView
    }

    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        let annotation = context.coordinator.userAnnotation

        // Update coordinate
        annotation.coordinate = userLocation
        context.coordinator.updateHeading(userHeading)

        // Find the annotation view and apply rotation
        if let view = uiView.view(for: annotation) {
            UIView.animate(withDuration: 0.1) {
                view.transform = CGAffineTransform(rotationAngle: CGFloat(self.userHeading * .pi / 180))
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        return coordinator
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var userAnnotation = MKPointAnnotation()
        weak var annotationView: MKAnnotationView?

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation === userAnnotation else { return nil }

            let identifier = "UserDirectionAnnotation"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.image = UIImage(systemName: "location.north.line.fill")
                view?.bounds = CGRect(x: 0, y: 0, width: 32, height: 32)
                view?.centerOffset = CGPoint(x: 0, y: 0)
            } else {
                view?.annotation = annotation
            }

            self.annotationView = view
            return view
        }

        func updateHeading(_ heading: CLLocationDirection) {
            guard let view = annotationView else { return }

            UIView.animate(withDuration: 0.1) {
                view.transform = CGAffineTransform(rotationAngle: CGFloat(heading * .pi / 180))
            }
        }
    }
}
