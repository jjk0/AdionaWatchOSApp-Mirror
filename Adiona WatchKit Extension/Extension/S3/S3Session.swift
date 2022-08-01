//
//  S3Session.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/13/22.
//

import Foundation

class S3: NSObject {
    let rootBucket: String

    #if DEBUG
        static let dataBucket = S3(rootBucket: "development-adiona-watch-data")
    #else
        static let dataBucket = S3(rootBucket: "raw-adiona-watch-app-data")
    #endif
    
    static let profileBucket = S3(rootBucket: "adiona-user-profile-data")
    
    var bucketName: String? {
        get {
            guard let bucketName = UserDefaults.standard.string(forKey: "bucket_name") else { return nil }
            return "\(rootBucket)/\(bucketName)/"
        }
        
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: "bucket_name")
        }
    }
    
    init(rootBucket: String) {
        self.rootBucket = rootBucket
        super.init()
    }
}
