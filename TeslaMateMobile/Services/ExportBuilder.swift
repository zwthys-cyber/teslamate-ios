import Foundation

enum ExportBuilder {
    static func allDrivesCSV(_ drives: [Drive]) -> URL? {
        let header = "id,start_time,end_time,start_location,end_location,distance_km,duration_min,max_speed_kmh,start_range_km,end_range_km"
        let rows = drives.map { drive in
            [String(drive.id), drive.startDate ?? "", drive.endDate ?? "", drive.startName, drive.endName,
             number(drive.distanceKm), drive.durationMin.map { String($0) } ?? "", drive.speedMax.map { String($0) } ?? "",
             number(drive.startRangeKm), number(drive.endRangeKm)].map(csvEscape).joined(separator: ",")
        }
        return write(([header] + rows).joined(separator: "\n"), name: "TeslaMate-All-Drives-\(dateStamp).csv")
    }

    static func allChargingCSV(_ sessions: [ChargingSession]) -> URL? {
        let header = "id,start_time,end_time,location,duration_min,energy_added_kwh,energy_used_kwh,start_battery_percent,end_battery_percent,cost"
        let rows = sessions.map { item in
            [String(item.id), item.startDate ?? "", item.endDate ?? "", item.name, item.durationMin.map { String($0) } ?? "",
             number(item.energyAddedKwh), number(item.energyUsedKwh), item.startBatteryLevel.map { String($0) } ?? "",
             item.endBatteryLevel.map { String($0) } ?? "", number(item.cost)].map(csvEscape).joined(separator: ",")
        }
        return write(([header] + rows).joined(separator: "\n"), name: "TeslaMate-All-Charging-\(dateStamp).csv")
    }

    static func snapshot(vehicles: [Vehicle], drives: [Drive], charging: [ChargingSession], statistics: Statistics, geofences: [Geofence], updates: [SoftwareUpdate], batteryHealth: [BatteryHealthSample]) -> URL? {
        let snapshot = ExportSnapshot(generatedAt: Date(), vehicles: vehicles, drives: drives, charging: charging, statistics: statistics, geofences: geofences, updates: updates, batteryHealth: batteryHealth)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return nil }
        return write(data, name: "TeslaMate-Backup-\(dateStamp).json")
    }

    static func gpx(drive: Drive, positions: [DrivePosition]) -> URL? {
        let points = positions.map {
            "<trkpt lat=\"\($0.latitude)\" lon=\"\($0.longitude)\"><time>\(escape($0.date))</time></trkpt>"
        }.joined(separator: "\n")
        let text = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="TeslaMate iOS" xmlns="http://www.topografix.com/GPX/1/1">
          <trk><name>\(escape(drive.startName)) - \(escape(drive.endName))</name><trkseg>
        \(points)
          </trkseg></trk>
        </gpx>
        """
        return write(text, name: "TeslaMate-Drive-\(drive.id).gpx")
    }

    static func csv(session: ChargingSession, samples: [ChargingSample]) -> URL? {
        let header = "time,battery_percent,power_kw,energy_added_kwh,outside_temp_c"
        let rows = samples.map { sample in
            "\(sample.date),\(sample.batteryLevel.map { String($0) } ?? ""),\(sample.chargerPower.map { String($0) } ?? ""),\(sample.energyAddedKwh.map { String($0) } ?? ""),\(sample.outsideTemp.map { String($0) } ?? "")"
        }
        return write(([header] + rows).joined(separator: "\n"), name: "TeslaMate-Charge-\(session.id).csv")
    }

    private static func write(_ content: String, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do { try content.write(to: url, atomically: true, encoding: .utf8); return url } catch { return nil }
    }

    private static func write(_ content: Data, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do { try content.write(to: url, options: .atomic); return url } catch { return nil }
    }

    private static var dateStamp: String {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyyMMdd"; return formatter.string(from: Date())
    }

    private static func number(_ value: Double?) -> String { value.map { String(format: "%.4f", $0) } ?? "" }
    private static func csvEscape(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
}

private struct ExportSnapshot: Encodable {
    let generatedAt: Date
    let vehicles: [Vehicle]
    let drives: [Drive]
    let charging: [ChargingSession]
    let statistics: Statistics
    let geofences: [Geofence]
    let updates: [SoftwareUpdate]
    let batteryHealth: [BatteryHealthSample]
}
