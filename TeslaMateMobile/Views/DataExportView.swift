import SwiftUI

struct DataExportView: View {
    @Environment(AppSession.self) private var session
    @State private var drivesURL: URL?
    @State private var chargingURL: URL?
    @State private var snapshotURL: URL?

    var body: some View {
        List {
            Section("表格数据") {
                if let drivesURL {
                    ShareLink(item: drivesURL) { ExportRow(icon: "road.lanes", title: "导出已同步行程", detail: "CSV · \(session.drives.count) 条") }
                }
                if let chargingURL {
                    ShareLink(item: chargingURL) { ExportRow(icon: "bolt.fill", title: "导出已同步充电记录", detail: "CSV · \(session.chargingSessions.count) 条") }
                }
            }
            Section("完整数据快照") {
                if let snapshotURL {
                    ShareLink(item: snapshotURL) { ExportRow(icon: "archivebox", title: "导出完整快照", detail: "JSON · 当前已同步数据") }
                }
                Text("完整快照包括车辆、行程、充电、统计、地理围栏、软件更新和电池健康记录。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("隐私") {
                Text("导出的文件可能包含车辆位置与行驶轨迹信息。请仅保存到可信位置，不要公开分享。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("数据导出中心")
        .task { prepareExports() }
    }

    private func prepareExports() {
        drivesURL = ExportBuilder.allDrivesCSV(session.drives)
        chargingURL = ExportBuilder.allChargingCSV(session.chargingSessions)
        snapshotURL = ExportBuilder.snapshot(vehicles: session.vehicles, drives: session.drives, charging: session.chargingSessions, statistics: session.statistics, geofences: session.geofences, updates: session.updates, batteryHealth: session.batteryHealth)
    }
}

private struct ExportRow: View {
    let icon, title, detail: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "square.and.arrow.up").foregroundStyle(.secondary)
        }
        .padding(.vertical, 5).contentShape(Rectangle())
    }
}
