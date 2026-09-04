import Foundation

enum APIError: LocalizedError {
    case invalidURL, invalidResponse, unauthorized, server(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "服务器地址无效"
        case .invalidResponse: "服务器返回了无效数据"
        case .unauthorized: "访问令牌不正确"
        case .server(let code): "服务器错误（\(code)）"
        }
    }
}

struct APIClient {
    let serverURL: String
    let token: String

    func vehicles() async throws -> [Vehicle] {
        try await request("api/mobile/v1/vehicles", as: VehicleEnvelope.self).data
    }

    func drives(carID: Int) async throws -> [Drive] {
        try await request("api/mobile/v1/drives?car_id=\(carID)&limit=200", as: DriveEnvelope.self).data
    }

    func drive(id: Int) async throws -> DriveDetail {
        try await request("api/mobile/v1/drives/\(id)", as: DriveDetailEnvelope.self).data
    }

    func charging(carID: Int) async throws -> [ChargingSession] {
        try await request("api/mobile/v1/charging?car_id=\(carID)&limit=200", as: ChargingEnvelope.self).data
    }

    func charging(id: Int) async throws -> ChargingDetail {
        try await request("api/mobile/v1/charging/\(id)", as: ChargingDetailEnvelope.self).data
    }

    func statistics(carID: Int) async throws -> Statistics {
        try await request("api/mobile/v1/statistics?car_id=\(carID)", as: StatisticsEnvelope.self).data
    }

    func geofences() async throws -> [Geofence] {
        try await request("api/mobile/v1/geofences", as: GeofenceEnvelope.self).data
    }

    func updates(carID: Int) async throws -> [SoftwareUpdate] {
        try await request("api/mobile/v1/updates?car_id=\(carID)", as: SoftwareUpdateEnvelope.self).data
    }

    func batteryHealth(carID: Int) async throws -> [BatteryHealthSample] {
        try await request("api/mobile/v1/battery_health?car_id=\(carID)", as: BatteryHealthEnvelope.self).data
    }

    private func request<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        guard let base = URL(string: serverURL), let url = URL(string: path, relativeTo: base) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else { throw APIError.server(http.statusCode) }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: data)
    }
}
