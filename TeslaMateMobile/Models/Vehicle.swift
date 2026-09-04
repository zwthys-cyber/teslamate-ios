import Foundation

struct VehicleEnvelope: Decodable {
    let data: [Vehicle]
    let generatedAt: String
}

struct Vehicle: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let vinSuffix: String
    let state: String?
    let since: String?
    let healthy: Bool?
    let latitude: Double?
    let longitude: Double?
    let heading: Double?
    let batteryLevel: Int?
    let usableBatteryLevel: Int?
    let idealBatteryRangeKm: Double?
    let estBatteryRangeKm: Double?
    let ratedBatteryRangeKm: Double?
    let chargingState: String?
    let chargeLimitSoc: Int?
    let chargerPower: Double?
    let pluggedIn: Bool?
    let speed: Double?
    let outsideTemp: Double?
    let insideTemp: Double?
    let isClimateOn: Bool?
    let locked: Bool?
    let sentryMode: Bool?
    let odometer: Double?
    let version: String?
    let geofence: String?
    let model: String?
    let trimBadging: String?
    let exteriorColor: String?
    let windowsOpen, doorsOpen: Bool?
    let trunkOpen, frunkOpen: Bool?
    let chargePortDoorOpen: Bool?
    let shiftState: String?
    let timeToFullCharge, chargerActualCurrent, chargerVoltage: Double?
    let chargerPhases: Int?
    let chargeEnergyAdded: Double?
    let updateAvailable: Bool?
    let updateVersion, updateStatus: String?
    let isPreconditioning, isUserPresent: Bool?
    let tpmsPressureFl, tpmsPressureFr, tpmsPressureRl, tpmsPressureRr: Double?
    let tpmsSoftWarningFl, tpmsSoftWarningFr, tpmsSoftWarningRl, tpmsSoftWarningRr: Bool?
}
