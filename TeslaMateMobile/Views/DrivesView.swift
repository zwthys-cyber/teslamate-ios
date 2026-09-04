import MapKit
import SwiftUI

struct DrivesView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        List(session.drives) { drive in
            NavigationLink { DriveDetailView(drive: drive) } label: {
                VStack(alignment: .leading, spacing: 7) {
                    HStack { Text(drive.startName).lineLimit(1); Image(systemName: "arrow.right"); Text(drive.endName).lineLimit(1) }
                        .font(.headline)
                    HStack {
                        Label(String(format: "%.1f km", drive.distanceKm ?? 0), systemImage: "road.lanes")
                        Spacer()
                        Label("\(drive.durationMin ?? 0) 分钟", systemImage: "clock")
                    }.font(.subheadline).foregroundStyle(.secondary)
                    Text(DateText.format(drive.startDate)).font(.caption).foregroundStyle(.tertiary)
                }.padding(.vertical, 5)
            }
        }
        .navigationTitle("行程")
        .refreshable { await session.refresh() }
        .overlay { if session.drives.isEmpty { ContentUnavailableView("暂无行程", systemImage: "road.lanes") } }
    }
}

private struct DriveDetailView: View {
    @Environment(AppSession.self) private var session
    let drive: Drive
    @State private var positions: [DrivePosition] = []
    @State private var loading = true
    var body: some View {
        List {
            if !positions.isEmpty {
                Map {
                    MapPolyline(coordinates: positions.map { .init(latitude: $0.latitude, longitude: $0.longitude) })
                        .stroke(.white, lineWidth: 5)
                    if let first = positions.first { Marker("出发", coordinate: .init(latitude: first.latitude, longitude: first.longitude)).tint(.white) }
                    if let last = positions.last { Marker("到达", coordinate: .init(latitude: last.latitude, longitude: last.longitude)).tint(.gray) }
                }
                .frame(height: 280)
                .listRowInsets(.init())
            } else if loading { ProgressView("正在载入轨迹…") }
            Section("路线") { LabeledContent("出发", value: drive.startName); LabeledContent("到达", value: drive.endName) }
            Section("驾驶数据") {
                LabeledContent("距离", value: String(format: "%.2f km", drive.distanceKm ?? 0))
                LabeledContent("用时", value: "\(drive.durationMin ?? 0) 分钟")
                LabeledContent("最高速度", value: "\(drive.speedMax ?? 0) km/h")
                LabeledContent("最高功率", value: "\(drive.powerMax ?? 0) kW")
                LabeledContent("平均外温", value: String(format: "%.1f ℃", drive.outsideTempAvg ?? 0))
            }
            Section("续航变化") { LabeledContent("开始", value: String(format: "%.1f km", drive.startRangeKm ?? 0)); LabeledContent("结束", value: String(format: "%.1f km", drive.endRangeKm ?? 0)) }
        }.navigationTitle("行程详情").task {
            do { positions = try await APIClient(serverURL: session.serverURL, token: session.token).drive(id: drive.id).positions }
            catch { session.errorMessage = error.localizedDescription }
            loading = false
        }
    }
}

enum DateText {
    static func format(_ text: String?) -> String {
        guard let text else { return "进行中" }
        return text.replacingOccurrences(of: "T", with: " ").prefix(16).description
    }
}
