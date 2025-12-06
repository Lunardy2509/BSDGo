import UIKit
import SwiftUI
import MapKit

struct MapUIViewRepresentable: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D
    @Binding var userHeading: CLLocationDirection
    @Binding var shouldRecenter: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.isRotateEnabled = false
        mapView.pointOfInterestFilter = .excludingAll

        mapView.showsCompass = true
        mapView.showsScale = true

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if shouldRecenter {
            let region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            uiView.setRegion(region, animated: true)

            DispatchQueue.main.async {
                self.shouldRecenter = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MKMapViewDelegate { }
}
