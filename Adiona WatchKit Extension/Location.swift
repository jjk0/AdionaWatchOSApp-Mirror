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
    static var shared = Location()
    
    var geoFences = [GeoFence]()
    
    @Published var geoFenceStatus: String = "In Fence"
    
    let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        requestAuthorization()
    }
    
    func resetGeofence() {
        Downloader.shared.getFromS3(filename: "geofences.json") { JSON in
            if let JSON = JSON,
               let jsonData = JSON.data(using: .utf8) {
                do {
                    let geoFenceData: GeofenceData = try JSONDecoder().decode(GeofenceData.self, from: jsonData)
                    let fences = geoFenceData.geofences
                    self.geoFences.removeAll()
                    
                    for (latitude, longitude, radius, identifier) in zip(fences.latitude, fences.longitude, fences.radius, fences.identifier) {
                        
                        let radiusInFeet = Measurement(value: radius, unit: UnitLength.feet)
                        let radiusInMeters = radiusInFeet.converted(to: UnitLength.meters)

                        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let region = CLCircularRegion(center: center,
                                                      radius: radiusInMeters.value, identifier: identifier)
                        region.notifyOnExit = true
                        region.notifyOnEntry = false
                        
                        self.geoFences.append(GeoFence(region: region, inFence: false))
                    }
                } catch {
                    track(error)
                }
            }
        }
    }

    func requestAuthorization() {
        let currentStatus = manager.authorizationStatus
        
        switch currentStatus {
            case .denied:
                print("Alert user to change in settings")
            case .authorizedWhenInUse:
                print("Alert user to change in settings")
            case .notDetermined:
                manager.requestAlwaysAuthorization()
            case .restricted:
                print("Alert user to change in settings")
            case .authorizedAlways:
                manager.startUpdatingLocation()
            @unknown default:
                print("Unknwon")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            HealthDataManager.shared.adionaData.locations.latitude.append(location.coordinate.latitude)
            HealthDataManager.shared.adionaData.locations.longitude.append(location.coordinate.longitude)
            HealthDataManager.shared.adionaData.locations.timestamp.append(location.timestamp)
            
            let coordinate = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

            let locationData = LocationData()
            locationData.longitude.append(location.coordinate.longitude)
            locationData.latitude.append(location.coordinate.latitude)
            locationData.timestamp.append(Date())

            do {
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
                            Uploader.shared.sendToS3(filename: "Geofence \(fence.region.identifier) Exit at \(Date().description).txt", json: try locationData.toJSON() as String) {
                                DispatchQueue.main.async {
                                    self.geoFenceStatus = "Out of fence \(fence.region.identifier): \(distanceInMeters)"
                                }
                            }
                        }
                    }
                }
            } catch {
                track(error)
            }
        }
    }
}
