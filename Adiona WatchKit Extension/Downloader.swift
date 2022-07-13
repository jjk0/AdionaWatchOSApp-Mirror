//
//  Downloader.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/13/22.
//

import Foundation
import SotoS3

final class Downloader: S3Session {
    static let shared = Downloader()
    
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

//                let getResponse = self.s3.getObject(getObjectRequest).always { result in
//                    switch result {
//                    case .failure(let error):
//                        track(error)
//                    case .success:
//                        let data = result.map { success in
//                            let x = success.
//                        }
//                        print("Success")
//                    }
//                    completion()
//                }
            } catch {
                track(error)
                completion(nil)
            }
        }
    }
}
