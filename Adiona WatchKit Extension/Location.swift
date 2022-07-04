//
//  Location.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/30/22.
//

import CoreLocation
import Foundation

class Location: NSObject, CLLocationManagerDelegate, ObservableObject {
    static var shared = Location()
    
    var geoFence: CLCircularRegion?
    var inFence = true
    
    @Published var geoFenceStatus: String = "In Fence"
    
    let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        requestAuthorization()
    }

    func monitorRegionAtLocation(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) -> CLCircularRegion {
        let region = CLCircularRegion(center: center,
                                      radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        return region
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
            if geoFence == nil {
                geoFence = monitorRegionAtLocation(center: location.coordinate, radius: 10, identifier: "Ken")
            }
            
            HealthDataManager.shared.adionaData.locations.latitude.append(location.coordinate.latitude)
            HealthDataManager.shared.adionaData.locations.longitude.append(location.coordinate.longitude)
            HealthDataManager.shared.adionaData.locations.timestamp.append(location.timestamp)
            
            if let geoFence = geoFence {
                let coordinate = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                let distanceInMeters = coordinate.distance(from: CLLocation(latitude: geoFence.center.latitude, longitude: geoFence.center.longitude))

                let locationData = LocationData()
                locationData.longitude.append(location.coordinate.longitude)
                locationData.latitude.append(location.coordinate.latitude)
                locationData.timestamp.append(Date())

                do {
                    if geoFence.contains(location.coordinate) {
                        if !inFence {
                            Uploader.shared.sendToS3(filename: "In Fence-\(UUID().uuidString).txt", json: try locationData.toJSON() as String) {
                                self.inFence = true
                                DispatchQueue.main.async {
                                    self.geoFenceStatus = "In fence: \(distanceInMeters)"
                                }
                            }
                        }
                    } else {
                        if inFence {
                            Uploader.shared.sendToS3(filename: "Out of fence-\(UUID().uuidString).txt", json: try locationData.toJSON() as String) {
                                self.inFence = false
                                DispatchQueue.main.async {
                                    self.geoFenceStatus = "Out of fence: \(distanceInMeters)"
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
}
