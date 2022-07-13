//
//  Uploader.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/24/22.
//

import Foundation
import SotoS3
import NIO

class Uploader: NSObject, URLSessionTaskDelegate, ObservableObject {
    static let shared = Uploader()
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


//        NSString *fileContentTypeStr = @"image/png";
//        AWSS3GetPreSignedURLRequest *urlRequest = [AWSS3GetPreSignedURLRequest new];
//        urlRequest.bucket = @"bounty-app";
//        urlRequest.key =[NSString stringWithFormat:@"submissions/photos/%@",nameOfImage];
//        urlRequest.HTTPMethod = AWSHTTPMethodPUT;
//        urlRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
//        urlRequest.contentType = fileContentTypeStr;
//        [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:urlRequest]
//         continueWithBlock:^id(BFTask *task) {
//
//             if (task.error) {
//                 NSLog(@"Error: %@",task.error);
//             } else {
//                 NSURL *presignedURL = task.result;
//                 NSLog(@"upload presignedURL is: \n%@", presignedURL);
//
//                 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
//                 request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
//                 [request setHTTPMethod:@"PUT"];
//                 [request setValue:fileContentTypeStr forHTTPHeaderField:@"Content-Type"];
//
//                 NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"unique_name_of_tttask"];
//                 NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
//                 NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromFile:savedPath];
//
//                 [uploadTask resume];
//             }
//             return nil;
//         }];
