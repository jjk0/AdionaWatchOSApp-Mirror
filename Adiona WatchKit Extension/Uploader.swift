//
//  Uploader.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/24/22.
//

import Foundation
import SotoS3
import NIO

final class Uploader: S3Session {
    static let shared = Uploader()
    
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
}
