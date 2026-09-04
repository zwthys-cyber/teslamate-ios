import Foundation

struct DriveEnvelope: Decodable { let data: [Drive] }
struct ChargingEnvelope: Decodable { let data: [ChargingSession] }
struct StatisticsEnvelope: Decodable { let data: Statistics }
struct GeofenceEnvelope: Decodable { let data: [Geofence] }

struct Drive: Decodable, Identifiable, Hashable {
    let id: Int
    let startDate, endDate: String?
    let durationMin: Int?
    let distanceKm: Double?
    let speedMax, powerMax, powerMin: Int?
    let outsideTempAvg, startRangeKm, endRangeKm: Double?
    let startName, endName: String
    let startLatitude, startLongitude, endLatitude, endLongitude: Double?
}

struct ChargingSession: Decodable, Identifiable, Hashable {
    let id: Int
    let startDate, endDate: String?
    let durationMin: Int?
    let energyAddedKwh, energyUsedKwh: Double?
    let startBatteryLevel, endBatteryLevel: Int?
    let cost, outsideTempAvg: Double?
    let name: String
    let latitude, longitude: Double?
}

struct Statistics: Decodable {
    let driving: DrivingStatistics
    let charging: ChargingStatistics
    static let empty = Statistics(driving: .init(count: 0, distanceKm: 0, durationMin: 0), charging: .init(count: 0, energyKwh: 0, cost: 0))
}

struct DrivingStatistics: Decodable { let count: Int; let distanceKm: Double; let durationMin: Int }
struct ChargingStatistics: Decodable { let count: Int; let energyKwh: Double; let cost: Double }

struct Geofence: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let latitude, longitude: Double
    let radius: Int
    let billingType: String?
    let costPerUnit, sessionFee: Double?
}
