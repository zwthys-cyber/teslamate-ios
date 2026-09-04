import MapKit
import Charts
import SwiftUI

struct DrivesView: View {
    @Environment(AppSession.self) private var session
    @State private var searchText = ""

    private var filteredDrives: [Drive] {
        guard !searchText.isEmpty else { return session.drives }
        return session.drives.filter { $0.startName.localizedCaseInsensitiveContains(searchText) || $0.endName.localizedCaseInsensitiveContains(searchText) }
    }
    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(String(format: "%.0f", session.statistics.driving.distanceKm)).font(.system(size: 44, weight: .semibold, design: .rounded)).tracking(-1.5).monospacedDigit()
                            Text("累计公里").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 5) { Text("\(session.statistics.driving.count)").font(.title2.weight(.semibold).monospacedDigit()); Text("全部行程").font(.caption).foregroundStyle(.secondary) }
                    }
                    if !filteredDrives.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(filteredDrives.indices, id: \.self) { index in
                                let drive = filteredDrives[index]
                                NavigationLink { DriveDetailView(drive: drive) } label: { DriveRow(drive: drive) }.buttonStyle(.plain)
                                if index != filteredDrives.indices.last { Divider().overlay(.white.opacity(0.1)).padding(.leading, 44) }
                            }
                        }.padding(.horizontal, 16).background(TMStyle.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 16).stroke(TMStyle.border, lineWidth: 0.5) }
                    }
                    if filteredDrives.isEmpty { ContentUnavailableView(searchText.isEmpty ? "暂无行程" : "没有匹配行程", systemImage: "road.lanes", description: Text(searchText.isEmpty ? "完成一次驾驶后会自动出现在这里" : "尝试搜索其他地点")) .padding(.top, 80) }
                }.padding(.horizontal, 20).padding(.bottom, 36)
            }
        }
        .navigationTitle("行程")
        .searchable(text: $searchText, prompt: "搜索出发地或目的地")
        .refreshable { await session.refresh() }
    }
}

private struct DriveRow: View {
    let drive: Drive
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "arrow.up.right").font(.caption.weight(.semibold)).frame(width: 30, height: 30).background(TMStyle.elevated, in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(drive.endName).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text("\(drive.startName) · \(drive.durationMin ?? 0) 分钟").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text(DateText.format(drive.startDate)).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 5) { Text(String(format: "%.1f", drive.distanceKm ?? 0)).font(.headline.monospacedDigit()); Text("km").font(.caption2).foregroundStyle(.secondary) }
            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
        }.padding(.vertical, 14).contentShape(Rectangle()).accessibilityElement(children: .combine)
    }
}

struct DriveDetailView: View {
    @Environment(AppSession.self) private var session
    let drive: Drive
    @State private var positions: [DrivePosition] = []
    @State private var loading = true
    @State private var exportURL: URL?
    var body: some View {
        List {
            if !positions.isEmpty {
                Map {
                    MapPolyline(coordinates: positions.map { ChinaCoordinate.display(latitude: $0.latitude, longitude: $0.longitude) })
                        .stroke(.white, lineWidth: 5)
                    if let first = positions.first { Marker("出发", coordinate: ChinaCoordinate.display(latitude: first.latitude, longitude: first.longitude)).tint(.white) }
                    if let last = positions.last { Marker("到达", coordinate: ChinaCoordinate.display(latitude: last.latitude, longitude: last.longitude)).tint(.gray) }
                }
                .frame(height: 280)
                .listRowInsets(.init())
            } else if loading { ProgressView("正在载入轨迹…") }
            if !positions.isEmpty {
                Section("速度曲线") {
                    Chart(Array(positions.enumerated()), id: \.offset) { point in
                        LineMark(x: .value("轨迹点", point.offset), y: .value("速度", point.element.speed ?? 0))
                            .foregroundStyle(.white)
                            .interpolationMethod(.catmullRom)
                    }
                    .chartYScale(domain: 0...max(20, positions.compactMap(\.speed).max() ?? 20))
                    .frame(height: 210)
                }
            }
            Section("路线") { LabeledContent("出发", value: drive.startName); LabeledContent("到达", value: drive.endName) }
            Section("驾驶数据") {
                LabeledContent("距离", value: String(format: "%.2f km", drive.distanceKm ?? 0))
                LabeledContent("用时", value: "\(drive.durationMin ?? 0) 分钟")
                LabeledContent("最高速度", value: "\(drive.speedMax ?? 0) km/h")
                LabeledContent("最高功率", value: "\(drive.powerMax ?? 0) kW")
                LabeledContent("平均外温", value: String(format: "%.1f ℃", drive.outsideTempAvg ?? 0))
                LabeledContent("轨迹点", value: "\(positions.count)")
            }
            Section("续航变化") {
                LabeledContent("开始", value: String(format: "%.1f km", drive.startRangeKm ?? 0))
                LabeledContent("结束", value: String(format: "%.1f km", drive.endRangeKm ?? 0))
                LabeledContent("续航消耗", value: String(format: "%.1f km", max(0, (drive.startRangeKm ?? 0) - (drive.endRangeKm ?? 0))))
            }
        }
        .navigationTitle("行程详情")
        .toolbar {
            if let exportURL { ToolbarItem(placement: .topBarTrailing) { ShareLink(item: exportURL) { Image(systemName: "square.and.arrow.up") } } }
        }
        .task {
            do {
                positions = try await APIClient(serverURL: session.serverURL, token: session.token).drive(id: drive.id).positions
                exportURL = ExportBuilder.gpx(drive: drive, positions: positions)
            }
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
