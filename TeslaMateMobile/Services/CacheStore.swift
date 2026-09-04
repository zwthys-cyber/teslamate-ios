import Foundation

struct AppCache: Codable {
    let vehicles: [Vehicle]
    let drives: [Drive]
    let chargingSessions: [ChargingSession]
    let statistics: Statistics
    let geofences: [Geofence]
    let lastUpdated: Date
}

enum CacheStore {
    private static var fileURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("teslamate-cache.json")
    }

    static func load() -> AppCache? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(AppCache.self, from: data)
    }

    static func save(_ cache: AppCache) {
        guard let fileURL, let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
