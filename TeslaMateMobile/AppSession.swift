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
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    var isConfigured: Bool { !serverURL.isEmpty && !token.isEmpty }
    var selectedVehicle: Vehicle? { vehicles.first(where: { $0.id == selectedVehicleID }) ?? vehicles.first }

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
                (drives, chargingSessions, statistics, geofences) = try await (newDrives, newCharging, newStatistics, newGeofences)
            }
            lastUpdated = Date()
            errorMessage = nil
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
            (drives, chargingSessions, statistics, geofences) = try await (newDrives, newCharging, newStatistics, newGeofences)
            lastUpdated = Date()
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}
