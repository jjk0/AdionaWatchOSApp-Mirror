//
//  BackgroundService.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import WatchKit

class BackgroundService: NSObject {
    static let shared = BackgroundService()
    let url = URL(string: "api-url")!
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
    
    func updateContent(content: Data) {
        var cachesFolderURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cachesFolderURL.appendPathComponent("content.data")
        
        do {
            try content.write(to: cachesFolderURL)
            let backgroundTask = urlSession.uploadTask(with: URLRequest(url: url), fromFile: cachesFolderURL)
            backgroundTask.earliestBeginDate = Date().addingTimeInterval(Session.fifteenMinutes)
            backgroundTask.resume()
        } catch {
            print(error)
        }
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
