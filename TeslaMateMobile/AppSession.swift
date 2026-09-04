import Foundation
import Observation

@MainActor @Observable
final class AppSession {
    var serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "http://100.88.30.82:4000/"
    var token = KeychainStore.read(account: "apiToken") ?? ""
    var vehicles: [Vehicle] = []
    var selectedVehicleID = UserDefaults.standard.integer(forKey: "selectedVehicleID")
    var drives: [Drive] = []
    var chargingSessions: [ChargingSession] = []
    var statistics = Statistics.empty
    var geofences: [Geofence] = []
    var updates: [SoftwareUpdate] = []
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    var isConfigured: Bool { !serverURL.isEmpty && !token.isEmpty }
    var selectedVehicle: Vehicle? { vehicles.first(where: { $0.id == selectedVehicleID }) ?? vehicles.first }
    var isShowingCachedData: Bool { errorMessage != nil && !vehicles.isEmpty }

    init() {
        guard let cache = CacheStore.load() else { return }
        vehicles = cache.vehicles
        drives = cache.drives
        chargingSessions = cache.chargingSessions
        statistics = cache.statistics
        geofences = cache.geofences
        updates = cache.updates ?? []
        lastUpdated = cache.lastUpdated
    }

    func save(serverURL: String, token: String) {
        var normalized = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.hasSuffix("/") { normalized += "/" }
        self.serverURL = normalized
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(normalized, forKey: "serverURL")
        KeychainStore.save(self.token, account: "apiToken")
    }

    func refresh() async {
        guard isConfigured, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let client = APIClient(serverURL: serverURL, token: token)
            vehicles = try await client.vehicles()
            if selectedVehicleID == 0 || !vehicles.contains(where: { $0.id == selectedVehicleID }) {
                selectedVehicleID = vehicles.first?.id ?? 0
            }
            if let carID = selectedVehicle?.id {
                async let newDrives = client.drives(carID: carID)
                async let newCharging = client.charging(carID: carID)
                async let newStatistics = client.statistics(carID: carID)
                async let newGeofences = client.geofences()
                async let newUpdates = client.updates(carID: carID)
                (drives, chargingSessions, statistics, geofences, updates) = try await (newDrives, newCharging, newStatistics, newGeofences, newUpdates)
            }
            lastUpdated = Date()
            errorMessage = nil
            persistCache()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectVehicle(_ id: Int) async {
        selectedVehicleID = id
        UserDefaults.standard.set(id, forKey: "selectedVehicleID")
        await refreshContent(carID: id)
    }

    private func refreshContent(carID: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let client = APIClient(serverURL: serverURL, token: token)
            async let newDrives = client.drives(carID: carID)
            async let newCharging = client.charging(carID: carID)
            async let newStatistics = client.statistics(carID: carID)
            async let newGeofences = client.geofences()
            async let newUpdates = client.updates(carID: carID)
            (drives, chargingSessions, statistics, geofences, updates) = try await (newDrives, newCharging, newStatistics, newGeofences, newUpdates)
            lastUpdated = Date()
            errorMessage = nil
            persistCache()
        } catch { errorMessage = error.localizedDescription }
    }

    private func persistCache() {
        guard let lastUpdated else { return }
        CacheStore.save(.init(vehicles: vehicles, drives: drives, chargingSessions: chargingSessions, statistics: statistics, geofences: geofences, updates: updates, lastUpdated: lastUpdated))
    }
}
