import Foundation

struct DriveEnvelope: Decodable { let data: [Drive] }
struct ChargingEnvelope: Decodable { let data: [ChargingSession] }
struct StatisticsEnvelope: Decodable { let data: Statistics }
struct GeofenceEnvelope: Decodable { let data: [Geofence] }

struct Drive: Codable, Identifiable, Hashable {
    let id: Int
    let startDate, endDate: String?
    let durationMin: Int?
    let distanceKm: Double?
    let speedMax, powerMax, powerMin: Int?
    let outsideTempAvg, startRangeKm, endRangeKm: Double?
    let startName, endName: String
    let startLatitude, startLongitude, endLatitude, endLongitude: Double?
}

struct DriveDetailEnvelope: Decodable { let data: DriveDetail }
struct DriveDetail: Decodable {
    let id: Int
    let positions: [DrivePosition]
}
struct DrivePosition: Decodable, Hashable {
    let latitude, longitude: Double
    let speed: Int?
    let date: String
}

struct ChargingSession: Codable, Identifiable, Hashable {
    let id: Int
    let startDate, endDate: String?
    let durationMin: Int?
    let energyAddedKwh, energyUsedKwh: Double?
    let startBatteryLevel, endBatteryLevel: Int?
    let cost, outsideTempAvg: Double?
    let name: String
    let latitude, longitude: Double?
}

struct ChargingDetailEnvelope: Decodable { let data: ChargingDetail }
struct ChargingDetail: Decodable {
    let id: Int
    let samples: [ChargingSample]
}
struct ChargingSample: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let batteryLevel, chargerPower: Int?
    let energyAddedKwh, outsideTemp: Double?
}

struct Statistics: Codable {
    let driving: DrivingStatistics
    let charging: ChargingStatistics
    let monthlyDriving: [MonthlyDriving]
    let monthlyCharging: [MonthlyCharging]
    static let empty = Statistics(driving: .init(count: 0, distanceKm: 0, durationMin: 0), charging: .init(count: 0, energyKwh: 0, cost: 0), monthlyDriving: [], monthlyCharging: [])
}

struct DrivingStatistics: Codable { let count: Int; let distanceKm: Double; let durationMin: Int }
struct ChargingStatistics: Codable { let count: Int; let energyKwh: Double; let cost: Double }
struct MonthlyDriving: Codable, Identifiable { var id: String { month }; let month: String; let count: Int; let distanceKm: Double; let durationMin: Int }
struct MonthlyCharging: Codable, Identifiable { var id: String { month }; let month: String; let count: Int; let energyKwh: Double; let cost: Double }

struct Geofence: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let latitude, longitude: Double
    let radius: Int
    let billingType: String?
    let costPerUnit, sessionFee: Double?
}
