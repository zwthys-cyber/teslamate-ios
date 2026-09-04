import MapKit
import SwiftUI

struct DrivesView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) { Text("最近行程").font(.title2.bold()); Text("共 \(session.statistics.driving.count) 次 · \(String(format: "%.0f", session.statistics.driving.distanceKm)) km").font(.subheadline).foregroundStyle(.secondary) }
                        Spacer(); Image(systemName: "road.lanes").font(.title2)
                    }.tmCard()
                    ForEach(session.drives) { drive in
                        NavigationLink { DriveDetailView(drive: drive) } label: { DriveCard(drive: drive) }.buttonStyle(.plain)
                    }
                    if session.drives.isEmpty { ContentUnavailableView("暂无行程", systemImage: "road.lanes", description: Text("完成一次驾驶后会自动出现在这里")) .padding(.top, 80) }
                }.padding(.horizontal, 18).padding(.bottom, 30)
            }
        }
        .navigationTitle("行程")
        .refreshable { await session.refresh() }
    }
}

private struct DriveCard: View {
    let drive: Drive
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(DateText.format(drive.startDate)).font(.caption).foregroundStyle(.secondary)
                Spacer(); Text(String(format: "%.1f km", drive.distanceKm ?? 0)).font(.title3.bold().monospacedDigit())
            }
            HStack(spacing: 12) {
                VStack(spacing: 3) { Circle().fill(.white).frame(width: 7, height: 7); Rectangle().fill(.white.opacity(0.25)).frame(width: 1, height: 24); Circle().stroke(.white, lineWidth: 1.5).frame(width: 7, height: 7) }
                VStack(alignment: .leading, spacing: 15) { Text(drive.startName).lineLimit(1); Text(drive.endName).lineLimit(1) }
                Spacer()
            }.font(.subheadline.weight(.medium))
            HStack { Label("\(drive.durationMin ?? 0) 分钟", systemImage: "clock"); Spacer(); Label("最高 \(drive.speedMax ?? 0) km/h", systemImage: "speedometer") }
                .font(.caption).foregroundStyle(.secondary)
        }.tmCard()
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
