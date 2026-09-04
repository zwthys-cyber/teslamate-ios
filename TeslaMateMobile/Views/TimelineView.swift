import SwiftUI

struct TimelineView: View {
    @Environment(AppSession.self) private var session
    @State private var range = TimelineRange.month

    private var events: [TimelineEvent] {
        let drives = session.drives.map(TimelineEvent.drive)
        let charging = session.chargingSessions.map(TimelineEvent.charging)
        let updates = session.updates.map(TimelineEvent.update)
        return (drives + charging + updates)
            .filter { range.includes($0.date) }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private var drives: [Drive] { events.compactMap { if case .drive(let value) = $0 { value } else { nil } } }
    private var charging: [ChargingSession] { events.compactMap { if case .charging(let value) = $0 { value } else { nil } } }

    var body: some View {
        List {
            Section {
                Picker("时间范围", selection: $range) {
                    ForEach(TimelineRange.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section {
                HStack {
                    TimelineMetric(title: "行程", value: "\(drives.count) 次")
                    Divider()
                    TimelineMetric(title: "里程", value: String(format: "%.0f km", drives.reduce(0) { $0 + ($1.distanceKm ?? 0) }))
                    Divider()
                    TimelineMetric(title: "充电", value: String(format: "%.1f kWh", charging.reduce(0) { $0 + ($1.energyAddedKwh ?? 0) }))
                }
                .padding(.vertical, 8)
            }

            Section("动态记录") {
                ForEach(events) { event in
                    switch event {
                    case .drive(let drive):
                        NavigationLink { DriveDetailView(drive: drive) } label: { TimelineRow(event: event) }
                    case .charging(let item):
                        NavigationLink { ChargingDetailView(item: item) } label: { TimelineRow(event: event) }
                    case .update:
                        TimelineRow(event: event)
                    }
                }
            }
        }
        .navigationTitle("车辆时间轴")
        .overlay { if events.isEmpty { ContentUnavailableView("该时段没有记录", systemImage: "clock") } }
        .refreshable { await session.refresh() }
    }
}

private struct TimelineMetric: View {
    let title, value: String
    var body: some View {
        VStack(spacing: 5) {
            Text(value).font(.headline.monospacedDigit())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TimelineRow: View {
    let event: TimelineEvent
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: event.icon).font(.headline).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(event.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(event.dateText).font(.caption2.monospacedDigit()).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}

private enum TimelineRange: String, CaseIterable, Identifiable {
    case week, month, all
    var id: Self { self }
    var title: String { switch self { case .week: "7 天"; case .month: "30 天"; case .all: "全部" } }
    func includes(_ date: Date?) -> Bool {
        guard self != .all else { return true }
        guard let date else { return false }
        let days = self == .week ? 7 : 30
        return date >= Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }
}

private enum TimelineEvent: Identifiable {
    case drive(Drive), charging(ChargingSession), update(SoftwareUpdate)
    var id: String {
        switch self { case .drive(let item): "drive-\(item.id)"; case .charging(let item): "charge-\(item.id)"; case .update(let item): "update-\(item.id)" }
    }
    var rawDate: String? {
        switch self { case .drive(let item): item.startDate; case .charging(let item): item.startDate; case .update(let item): item.startDate }
    }
    var date: Date? { rawDate.flatMap(ISODate.parse) }
    var dateText: String { date?.formatted(.dateTime.month().day()) ?? "--" }
    var icon: String { switch self { case .drive: "car.fill"; case .charging: "bolt.fill"; case .update: "gearshape.2" } }
    var title: String {
        switch self {
        case .drive(let item): item.endName
        case .charging(let item): item.name
        case .update(let item): "车辆软件 \(item.version ?? "未知版本")"
        }
    }
    var subtitle: String {
        switch self {
        case .drive(let item): String(format: "%@ · %.1f km · %d 分钟", item.startName, item.distanceKm ?? 0, item.durationMin ?? 0)
        case .charging(let item): String(format: "充入 %.1f kWh · %d%% → %d%%", item.energyAddedKwh ?? 0, item.startBatteryLevel ?? 0, item.endBatteryLevel ?? 0)
        case .update(let item): item.endDate == nil ? "更新记录中" : "软件更新完成"
        }
    }
}

private enum ISODate {
    static let fractional: ISO8601DateFormatter = { let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return formatter }()
    static let standard = ISO8601DateFormatter()
    static func parse(_ value: String) -> Date? { fractional.date(from: value) ?? standard.date(from: value) }
}
