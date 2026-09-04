import CoreLocation
import Foundation

enum ChinaCoordinate {
    static func display(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        guard longitude >= 72.004, longitude <= 137.8347, latitude >= 0.8293, latitude <= 55.8271 else {
            return .init(latitude: latitude, longitude: longitude)
        }

        let a = 6_378_245.0
        let ee = 0.00669342162296594323
        let x = longitude - 105
        let y = latitude - 35

        var dLat = -100 + 2 * x + 3 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        dLat += (20 * sin(6 * x * .pi) + 20 * sin(2 * x * .pi)) * 2 / 3
        dLat += (20 * sin(y * .pi) + 40 * sin(y / 3 * .pi)) * 2 / 3
        dLat += (160 * sin(y / 12 * .pi) + 320 * sin(y * .pi / 30)) * 2 / 3

        var dLongitude = 300 + x + 2 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        dLongitude += (20 * sin(6 * x * .pi) + 20 * sin(2 * x * .pi)) * 2 / 3
        dLongitude += (20 * sin(x * .pi) + 40 * sin(x / 3 * .pi)) * 2 / 3
        dLongitude += (150 * sin(x / 12 * .pi) + 300 * sin(x * .pi / 30)) * 2 / 3

        let radians = latitude / 180 * .pi
        var magic = sin(radians)
        magic = 1 - ee * magic * magic
        let root = sqrt(magic)
        dLat = dLat * 180 / ((a * (1 - ee) / (magic * root)) * .pi)
        dLongitude = dLongitude * 180 / ((a / root * cos(radians)) * .pi)
        return .init(latitude: latitude + dLat, longitude: longitude + dLongitude)
    }
}
