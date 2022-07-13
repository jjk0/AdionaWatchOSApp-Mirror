//
//  Notifications.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/27/22.
//

import Foundation

public extension NSNotification.Name {
    static let healthKitPermissionsChanged = NSNotification.Name("healthkit.permissions.changed")
    static let bucketNameEstablished = NSNotification.Name("bucket.name.established")
}
