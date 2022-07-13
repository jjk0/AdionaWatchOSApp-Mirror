//
//  S3Session.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/13/22.
//

import Foundation
import SotoS3
import NIO

class S3Session: NSObject {
    static let rootBucket = "development-adiona-watch-raw-data"
    
    var bucketName: String? {
        get {
            guard let bucketName = UserDefaults.standard.string(forKey: "bucket_name") else { return nil }
            return "\(Uploader.rootBucket)/\(bucketName)/"
        }
        
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: "bucket_name")
        }
    }
    
    let client = AWSClient(
        credentialProvider: .static(accessKeyId: "AKIA3LD2DR65C72R2ZVW", secretAccessKey: "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"),
        httpClientProvider: .createNew
    )
    var s3: S3
    
    override init() {
        s3 = S3(client: client, region: .useast2)
        super.init()
    }
    
    func lookupBucket(bucketName: String, completion: @escaping (Bool)->Void) { // Bool becomes error later
        let newBucketName = "\(Uploader.rootBucket)/\(bucketName)"

        let lookupRequest = S3.HeadBucketRequest(bucket: newBucketName)
        let lookupFuture = s3.headBucket(lookupRequest)
        lookupFuture.whenFailure { error in
            track(error)
            completion(false)
        }

        lookupFuture.whenSuccess({ output in
            completion(true)
        })
    }

    func createBucket(bucketName: String, completion: @escaping (Error?)->Void) { // Bool becomes error later
        let newBucketName = "\(Uploader.rootBucket)/\(bucketName)"
        
        let createBucketRequest = S3.CreateBucketRequest(bucket: newBucketName)
        let createBucketFuture = s3.createBucket(createBucketRequest)
        createBucketFuture.whenFailure({ error in
            track(error)
            completion(error)
        })
        
        createBucketFuture.whenSuccess({ output in
            self.bucketName = bucketName
            completion(nil)
        })
    }
}
