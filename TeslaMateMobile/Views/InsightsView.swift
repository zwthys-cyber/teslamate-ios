import Charts
import SwiftUI

struct InsightsView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack { StatCard(title: "总里程", value: String(format: "%.0f km", session.statistics.driving.distanceKm), icon: "road.lanes"); StatCard(title: "行程", value: "\(session.statistics.driving.count) 次", icon: "car") }
                HStack { StatCard(title: "充电量", value: String(format: "%.1f kWh", session.statistics.charging.energyKwh), icon: "bolt.fill"); StatCard(title: "充电次数", value: "\(session.statistics.charging.count) 次", icon: "number") }
                Chart(Array(session.drives.prefix(14).reversed())) { drive in
                    BarMark(x: .value("日期", DateText.format(drive.startDate)), y: .value("里程", drive.distanceKm ?? 0)).foregroundStyle(.red.gradient)
                }.frame(height: 240).padding().background(.thinMaterial, in: .rect(cornerRadius: 18))
            }.padding()
        }.navigationTitle("统计").refreshable { await session.refresh() }
    }
}

private struct StatCard: View {
    let title, value, icon: String
    var body: some View { VStack(alignment: .leading, spacing: 10) { Label(title, systemImage: icon).foregroundStyle(.secondary); Text(value).font(.title3.bold()) }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: .rect(cornerRadius: 16)) }
}
