import Foundation

enum ExportBuilder {
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

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
}
