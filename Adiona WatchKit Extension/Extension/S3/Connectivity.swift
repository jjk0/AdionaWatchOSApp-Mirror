//
//  Connectivity.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/20/22.
//

import Network

struct NetworkConnectivity {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")

    func startMonitoring(callback: @escaping (NWPath)->Void) {
        monitor.pathUpdateHandler = { path in
            callback(path)
        }
        monitor.start(queue: queue)
    }
}
