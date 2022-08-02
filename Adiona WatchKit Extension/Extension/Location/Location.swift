//
//  Location.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/30/22.
//

import CoreLocation
import Foundation

class GeoFence: NSObject {
    let region: CLCircularRegion
    var inFence: Bool
    
    init(region: CLCircularRegion, inFence: Bool) {
        self.region = region
        self.inFence = inFence
    }
}

class Location: NSObject, CLLocationManagerDelegate, ObservableObject {
    var geoFences = [GeoFence]()
    var lastReportedLocation: CLLocation?

    @Published var geoFenceStatus: String = "In Fence"
    
    var manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        requestAuthorization()
    }
    
    func resetGeofence(with geoFenceData: GeofenceData) {
        let fences = geoFenceData.geofences
        HealthDataManager.shared.adionaData.metaData.geofences = geoFenceData

        geoFences.removeAll()
                    
        for (latitude, longitude, radius, identifier) in zip(fences.latitude, fences.longitude, fences.radius, fences.identifier) {
            let radiusInFeet = Measurement(value: radius, unit: UnitLength.feet)
            let radiusInMeters = radiusInFeet.converted(to: UnitLength.meters)

            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = CLCircularRegion(center: center,
                                          radius: radiusInMeters.value, identifier: identifier)
            region.notifyOnExit = true
            region.notifyOnEntry = false
                        
            geoFences.append(GeoFence(region: region, inFence: false))
        }
    }

    func requestAuthorization() {
        let currentStatus = manager.authorizationStatus
        
        switch currentStatus {
            case .denied:
                print("Alert user to change in settings")
            case .authorizedWhenInUse:
                restart()
            case .notDetermined:
                manager.requestAlwaysAuthorization()
            case .restricted:
                print("Alert user to change in settings")
            case .authorizedAlways:
                restart()
            @unknown default:
                print("Unknwon")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
    
    func checkGeoFences(location: CLLocation) {
        let coordinate = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

        for fence in geoFences {
            let distanceInMeters = coordinate.distance(from: CLLocation(latitude: fence.region.center.latitude, longitude: fence.region.center.longitude))

            if fence.region.contains(location.coordinate) {
                fence.inFence = true
                DispatchQueue.main.async {
                    self.geoFenceStatus = "In fence \(fence.region.identifier): \(distanceInMeters)"
                }
            } else {
                if fence.inFence {
                    fence.inFence = false
                    HealthDataManager.shared.adionaData.geofence_breaches.append(fence.region.identifier)
                }
            }
        }
        
        if HealthDataManager.shared.adionaData.geofence_breaches.count > 0 {
            NotificationCenter.default.post(name: NSNotification.Name("geofence_breached"), object: nil)
        }
    }
    
    func restart() {
        manager.stopUpdatingLocation()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastReportedLocation = locations.last
        
        for location in locations {
            HealthDataManager.shared.adionaData.locations.latitude.append(location.coordinate.latitude)
            HealthDataManager.shared.adionaData.locations.longitude.append(location.coordinate.longitude)
            HealthDataManager.shared.adionaData.locations.timestamp.append(location.timestamp)
         
            checkGeoFences(location: location)
        }
    }
}
