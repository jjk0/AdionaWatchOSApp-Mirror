//
//  BackgroundService.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import WatchKit
import SotoS3

class BackgroundService: NSObject {
    static let shared = BackgroundService()
    let uploader = Uploader()

    lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "adiona_bgtask_session")
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        return URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: nil)
    }()
    
    // Store tasks in order to complete them when finished
    var pendingBackgroundTasks = [WKURLSessionRefreshBackgroundTask]()
    
    func updateContent(content: String, identifier: String) {
        uploader.sendToS3(filename: "\(identifier).txt", json: content)
//        var cachesFolderURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
//        let filename = "\(identifier).json"
//        cachesFolderURL.appendPathComponent(filename)
//
//        do {
//            try content.write(to: cachesFolderURL)
//            let url = URL(string: "http://localhost:3000/multiupload") // or upload
//
//            let fileInfo = Uploader.FileInfo(withFileURL: cachesFolderURL, filename: filename, name: "uploadedFile", mimetype: "application/json")
//
//            uploader.upload(file: fileInfo, toURL: url!, withHttpMethod: .post) { (results, failedFilesList) in
//                print("HTTP status code:", results.response?.httpStatusCode ?? 0)
//
//                if let error = results.error {
//                    print(error)
//                }
//
//                if let data = results.data {
//                    if let toDictionary = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) {
//                        print(toDictionary)
//                    }
//                }
//
//                if let failedFiles = failedFilesList {
//                    for file in failedFiles {
//                        print(file)
//                    }
//                }
//            }
//        } catch {
//            print(error)
//        }
    }
    
    func handleUpload(_ backgroundTask: WKURLSessionRefreshBackgroundTask) {
        let configuration = URLSessionConfiguration
            .background(withIdentifier: backgroundTask.sessionIdentifier)
        
        let _ = URLSession(configuration: configuration,
                           delegate: self, delegateQueue: nil)
    }
}

extension BackgroundService : URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        self.pendingBackgroundTasks.forEach {
//            $0.setTaskCompletedWithSnapshot(false)
//        }
    }
}
