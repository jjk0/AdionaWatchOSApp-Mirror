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
    static let dataBucket = S3Session(rootBucket: "development-adiona-watch-data")
    static let profileBucket = S3Session(rootBucket: "adiona-user-profile-data")

    let rootBucket: String
    var bucketName: String? {
        get {
            guard let bucketName = UserDefaults.standard.string(forKey: "bucket_name") else { return nil }
            return "\(rootBucket)/\(bucketName)/"
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
    
    init(rootBucket: String) {
        s3 = S3(client: client, region: .useast1)
        self.rootBucket = rootBucket
        super.init()
    }
    
    func lookupBucket(bucketName: String, completion: @escaping (Bool)->Void) {
        let newBucketName = "\(rootBucket)/\(bucketName)"

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

    func createBucket(bucketName: String, completion: @escaping (Error?)->Void) {
        let newBucketName = "\(rootBucket)/\(bucketName)"
        
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
    
    func sendToS3(filename: String, json: String, completion: @escaping ()->Void)  {
        guard let bucket = self.bucketName else {
            track("Bucket not set in sendToS3")
            return
        }
        
        let putObjectRequest = S3.PutObjectRequest(
            body: .string(json),
            bucket: bucket,
            key: filename
        )
        
        let _ = self.s3.putObject(putObjectRequest).always { result in
            switch result {
            case .failure(let error):
                track(error)
            case .success:
                print("Success")
            }
            completion()
        }
    }

    func getFromS3(filename: String, completion: @escaping (String?)->Void)  {
        guard let bucket = self.bucketName else {
            track("Bucket not set in sendToS3")
            return
        }
        
        Task {
            do {
                let getObjectRequest = S3.GetObjectRequest(bucket: bucket, key: filename)
                
                let getResponse = try await s3.getObject(getObjectRequest)
                completion(getResponse.body?.asString())
            } catch {
                track(error)
                completion(nil)
            }
        }
    }
}
