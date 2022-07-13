//
//  Geofences.model.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/13/22.
//

import CoreLocation

struct Geofences: Decodable {
    let latitude: Array<CLLocationDegrees>
    let longitude: Array<CLLocationDegrees>
    let radius: Array<Double>
    let identifier: Array<String>
}

struct GeofenceData: Decodable {
    let geofences: Geofences
}

