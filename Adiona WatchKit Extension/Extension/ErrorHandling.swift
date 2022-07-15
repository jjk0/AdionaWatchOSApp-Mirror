//
//  ErrorHandling.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/27/22.
//

import Foundation
import Sentry

func track(_ error: Error?, file: String = #file, function: String = #function, line: Int = #line) {
    guard let error = error else { return }
    track(String(describing: error), file: file, function: function, line: line)
}

func track(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    print("\(message) called from \(function) \(file):\(line)")
    SentrySDK.capture(message: "\(message) called from \(function) \(file):\(line)")
}

enum AdionaError: Error {
    case couldNotConnectToDatabase
}
