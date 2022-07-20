import ClockKit
import WatchKit
import HealthKit
import CoreMotion
import Sentry

struct DeviceToken: Encodable {
    let device_token: String
}


final class ExtensionDelegate: NSObject, WKExtensionDelegate, ObservableObject {
    @Published var receivedPN = false

    private let healthDataManager = HealthDataManager.shared
    private let networkConnectivity = NetworkConnectivity()
    private var apnsID: String = "unassigned"
    
    func applicationDidFinishLaunching() {
        SentrySDK.start { options in
            options.dsn = "https://eadde9c57a2542d5a123b338aacd0441@o824011.ingest.sentry.io/6447191"
            options.debug = false // Enabled debug when first installing is always helpful
            options.sessionTrackingIntervalMillis = 6000
        }
        
        getProfileData()
        
        WKExtension.shared().registerForRemoteNotifications()
        
        networkConnectivity.startMonitoring { path in
            switch path.status {
            case .requiresConnection:
                HealthDataManager.shared.adionaData.metaData = MetaData(connectivity_status: "no-connection", device_ID: self.apnsID)
                break
            case .satisfied:
                if path.isExpensive {
                    HealthDataManager.shared.adionaData.metaData = MetaData(connectivity_status: "cellular", device_ID: self.apnsID)
                } else {
                    HealthDataManager.shared.adionaData.metaData = MetaData(connectivity_status: "WiFi", device_ID: self.apnsID)
                }
            case .unsatisfied:
                break
            @unknown default:
                print("Unknown case")
            }
        }
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let deviceToken = DeviceToken(device_token: deviceToken.map { String(format: "%02x", $0) }.joined())
        do {
            let json = try deviceToken.toJSON() as String
                
            apnsID = deviceToken.device_token
            HealthDataManager.shared.adionaData.metaData = MetaData(connectivity_status: HealthDataManager.shared.adionaData.metaData.connectivity_status, device_ID: self.apnsID)

            S3Session.profileBucket.sendToS3(filename: "deviceToken.json", json: json) {
                print("device token sent")
            }
        } catch {
            track(error)
        }
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        track(error)
    }
    
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any],
                                      fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {
        if userInfo["content-available"] as? Int == 1 {
            // Silent notification
            S3Session.profileBucket.sendToS3(filename: "APNS.json", json: Date().description) {
                
            }
        }

        receivedPN = true
        completionHandler(.newData)
    }
    
    
    func applicationDidBecomeActive() {
        if let data = UserDefaults.standard.string(forKey: "JSON") {
            print("Data count: \(data.count)")
        }
    }
        
    func getProfileData() {
        S3Session.profileBucket.getFromS3(filename: "profileData.json") { JSON in
            if let JSON = JSON,
               let jsonData = JSON.data(using: .utf8) {
                do {
                    HealthDataManager.shared.profileData = try JSONDecoder().decode(ProfileData.self, from: jsonData)
                } catch {
                    track(error)
                }
            }
        }
    }
    
    public func schedule(firstTime: Bool = false) {
        let minutes = 15

        let when = Calendar.current.date(
            byAdding: .minute,
            value: firstTime ? 1 : minutes,
            to: Date.now
        )!

        WKExtension
            .shared()
            .scheduleBackgroundRefresh(
                withPreferredDate: when,
                userInfo: nil
            ) { error in
                if let error = error {
                    track("Unable to schedule: \(error.localizedDescription)")
                }
            }
        
        print("Background Schedule for: \(when)")
    }

    func sendHealthData(completion: @escaping () -> Void) {
        do {
            let json = try self.healthDataManager.adionaData.toJSON()
            
            let filename = "\(UUID().uuidString).txt"
            
            S3Session.dataBucket.sendToS3(filename: filename, json: json as String) {
                self.healthDataManager.resetCollectors()
                self.schedule()
                completion()
            }
        } catch {
            track(error)
            completion()
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        backgroundTasks.forEach { task in
            switch task {
            case let task as WKSnapshotRefreshBackgroundTask:
                task.setTaskCompletedWithSnapshot(false)
            case let task as WKApplicationRefreshBackgroundTask:
                sendHealthData() {
                    task.setTaskCompletedWithSnapshot(false)
                }
            case let task as WKURLSessionRefreshBackgroundTask:
                task.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
