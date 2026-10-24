import Foundation
import CoreLocation
import Combine

public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()

    // MARK: - Published Properties
    @Published public private(set) var userLocation: CLLocation?
    @Published public private(set) var cityName: String = "Detecting Location..."
    @Published public private(set) var countryName: String = ""
    @Published public private(set) var currentHeading: CLLocationDegrees = 0.0
    @Published public private(set) var qiblaBearing: Double = 0.0
    @Published public private(set) var relativeQiblaAngle: Double = 0.0
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var locationError: String?

    // Kaaba Coordinates (Makkah Al-Mukarramah)
    private static let kaabaLatitude: Double = 21.422487
    private static let kaabaLongitude: Double = 39.826206

    private let clManager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var isGeocoding = false
    private var smoothedHeading: Double = 0.0

    override public init() {
        self.clManager = CLLocationManager()
        super.init()
        self.clManager.delegate = self
        self.clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.clManager.distanceFilter = 500 // meters
        self.clManager.headingFilter = 1 // degrees
        self.authorizationStatus = clManager.authorizationStatus
    }

    // MARK: - Permission Controls

    public func requestLocationAuthorization() {
        switch clManager.authorizationStatus {
        case .notDetermined:
            clManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            clManager.startUpdatingLocation()
            startHeadingUpdates()
        case .authorizedAlways:
            clManager.startUpdatingLocation()
            startHeadingUpdates()
        case .denied, .restricted:
            locationError = "Location permission was denied. Please enable in iOS Settings for precise prayer times."
        @unknown default:
            break
        }
    }

    public func startHeadingUpdates() {
        if CLLocationManager.headingAvailable() {
            clManager.startUpdatingHeading()
        }
    }

    public func stopHeadingUpdates() {
        clManager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                self.clManager.startUpdatingLocation()
                self.startHeadingUpdates()
            case .denied, .restricted:
                self.locationError = "Location access denied. Prayer times will use cached or manual coordinates."
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out cached stale fixes older than 60 seconds
        if abs(location.timestamp.timeIntervalSinceNow) > 60 {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.userLocation = location
            self.recalculateQibla(for: location)
            self.reverseGeocode(location: location)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }

        // Prefer true heading if available, else magnetic heading
        let rawHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading

        // Low-pass filter for smooth compass animation
        let alpha = 0.2
        var diff = rawHeading - smoothedHeading
        while diff < -180.0 { diff += 360.0 }
        while diff > 180.0 { diff -= 360.0 }
        smoothedHeading = (smoothedHeading + alpha * diff).truncatingRemainder(dividingBy: 360.0)
        if smoothedHeading < 0 { smoothedHeading += 360.0 }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentHeading = self.smoothedHeading
            // Relative angle: how much the compass needle must rotate
            var relative = self.qiblaBearing - self.smoothedHeading
            while relative < 0 { relative += 360 }
            while relative >= 360 { relative -= 360 }
            self.relativeQiblaAngle = relative
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.locationError = error.localizedDescription
        }
    }

    // MARK: - Qibla Astronomical Calculations

    private func recalculateQibla(for location: CLLocation) {
        let lat1 = location.coordinate.latitude * .pi / 180.0
        let lon1 = location.coordinate.longitude * .pi / 180.0
        let lat2 = Self.kaabaLatitude * .pi / 180.0
        let lon2 = Self.kaabaLongitude * .pi / 180.0

        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let radians = atan2(y, x)
        var degrees = radians * 180.0 / .pi
        degrees = (degrees + 360.0).truncatingRemainder(dividingBy: 360.0)

        self.qiblaBearing = degrees
        var relative = degrees - self.currentHeading
        while relative < 0 { relative += 360 }
        while relative >= 360 { relative -= 360 }
        self.relativeQiblaAngle = relative
    }

    // MARK: - Reverse Geocoding

    private func reverseGeocode(location: CLLocation) {
        guard !isGeocoding else { return }
        isGeocoding = true

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isGeocoding = false
                if let placemark = placemarks?.first {
                    self.cityName = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea ?? "Unknown City"
                    self.countryName = placemark.country ?? ""
                }
            }
        }
    }
}
