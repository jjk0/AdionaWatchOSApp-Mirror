//: A UIKit based Playground for presenting user interface
  
import CoreMotion
import Foundation
import PlaygroundSupport
import UIKit
// 2022-06-12T07:25:00Z
class AccelerometerData: Encodable {
    let startQueryTime = Date()
    let frequency = 32
    var x_val: [Double] = []
    var y_val: [Double] = []
    var z_val: [Double] = []
}

var acclerometerData = AccelerometerData()

class MyViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

    let acceleration = CMAcceleration(x: 1.234, y: 2.345, z: 3.456)
    
for _ in 0 ... 2 { // (32 * 60) * 5 {
        add(acceleration)
    }
    
//        "acceleration": {
//            "x_val": [0.05, 0.17],
//            "y_val": [0.12, 1.2],
//            "z_val": [-0.41, 1.7],
//            "startQueryTime": "2022-06-12T07:25:00Z",
//            "frequency": 32
//        },

    // 1,324,967
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted

    let data = try! encoder.encode(acclerometerData)
    
    print(ByteCountFormatter().string(fromByteCount: Int64(data.count)))

    let string = String(data: data, encoding: .utf8)!
    
    var JSON = """
    {"menu": {
              "id": "file",
              "value": "File",
              "popup": {
                "menuitem": [
                  {"value": "New", "onclick": "CreateNewDoc()"},
                  {"value": "Close", "onclick": "CloseDoc()"}
                ]
              }
            }}
    """
    
    if let rpos = JSON.range(of:"}", options:.backwards) {
        JSON.removeSubrange(rpos)
    }
    
    print(JSON)


func add(_ acceleration: CMAcceleration) {
    acclerometerData.x_val.append(acceleration.x)
    acclerometerData.y_val.append(acceleration.y)
    acclerometerData.z_val.append(acceleration.z)
}

// Present the view controller in the Live View window
//PlaygroundPage.current.liveView = MyViewController()
