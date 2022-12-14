//
//  NetworkTools.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/25/22.
//

import UIKit

class NetworkTools {
    /// A Boolean value indicating whether the device has cellular data capabilities (true) or not (false).
    class func hasCellularCapabilites() -> Bool {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        var cursor: UnsafeMutablePointer<ifaddrs>?

        defer { freeifaddrs(addrs) }

        guard getifaddrs(&addrs) == 0 else { return false }
        cursor = addrs

        while cursor != nil {
            guard
                let utf8String = cursor?.pointee.ifa_name,
                let name = NSString(utf8String: utf8String),
                name == "pdp_ip0"
                else {
                    cursor = cursor?.pointee.ifa_next
                    continue
            }
            return true
        }
        return false
    }
}
