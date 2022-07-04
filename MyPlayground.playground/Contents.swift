import UIKit

class Value<T>: Encodable where T: Encodable {
    var value = [T]()
    let queryTime = Date()
}

class AccelerometerData: Encodable {
    let frequency = 32
    
    func prepareForReuse() {
        print("prepareForReuse()")
        queryTime = Date()
        x_val = Array<Double>()
        y_val = Array<Double>()
        z_val = Array<Double>()
    }
    
    var queryTime = Date()
    var x_val = Array<Double>()
    var y_val = Array<Double>()
    var z_val = Array<Double>()
}

struct MetaData: Encodable {
    let connectivity_status: String
    let device_ID: String
}

struct AdionaData: Encodable {
    let metaData = MetaData(connectivity_status: "wifi", device_ID: UUID().uuidString)
    let acceleration = AccelerometerData()
    let heart_rate = Value<Int>()
    let step_count = Value<Int>()
    let respiratory_rate = Value<Int>()
    let oxygen_saturation = Value<Int>()
}

extension Encodable {
    /// Converting object to postable JSON
    func toJSON(_ encoder: JSONEncoder = JSONEncoder()) throws -> NSString {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        let result = String(decoding: data, as: UTF8.self)
        return NSString(string: result)
    }
}


let data = AdionaData()
data.heart_rate.value.append(43)
data.heart_rate.value.append(44)

data.oxygen_saturation.value.append(99)
data.oxygen_saturation.value.append(98)
data.oxygen_saturation.value.append(102)

data.respiratory_rate.value.append(44)
data.respiratory_rate.value.append(80)

data.acceleration.x_val.append(45.00)
data.acceleration.x_val.append(46.00)

data.acceleration.y_val.append(48.00)
data.acceleration.y_val.append(48.00)

data.acceleration.z_val.append(49.00)
data.acceleration.z_val.append(49.00)


let jsonString = try! data.toJSON()
print(jsonString)


