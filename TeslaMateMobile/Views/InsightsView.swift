import Charts
import SwiftUI

struct InsightsView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 12) { StatCard(title: "总里程", value: String(format: "%.0f km", session.statistics.driving.distanceKm), icon: "road.lanes"); StatCard(title: "驾驶时间", value: duration, icon: "clock") }
                    HStack(spacing: 12) { StatCard(title: "充电量", value: String(format: "%.1f kWh", session.statistics.charging.energyKwh), icon: "bolt.fill"); StatCard(title: "充电费用", value: String(format: "¥%.2f", session.statistics.charging.cost), icon: "yensign.circle") }
                    VStack(alignment: .leading, spacing: 18) {
                        TMSectionTitle("最近行程", detail: "最近 14 次")
                        Chart(Array(session.drives.prefix(14).reversed())) { drive in
                            BarMark(x: .value("日期", DateText.format(drive.startDate)), y: .value("里程", drive.distanceKm ?? 0)).foregroundStyle(.white)
                        }.chartXAxis(.hidden).frame(height: 220)
                    }.tmCard()
                    HStack { SummaryLine(icon: "car.fill", title: "行程次数", value: "\(session.statistics.driving.count)"); Divider(); SummaryLine(icon: "bolt.fill", title: "充电次数", value: "\(session.statistics.charging.count)") }.tmCard()
                }.padding(.horizontal, 18).padding(.bottom, 30)
            }.refreshable { await session.refresh() }
        }.navigationTitle("统计")
    }

    private var duration: String { let minutes = session.statistics.driving.durationMin; return minutes >= 60 ? "\(minutes / 60) 小时" : "\(minutes) 分钟" }
}

private struct StatCard: View {
    let title, value, icon: String
    var body: some View { VStack(alignment: .leading, spacing: 14) { Image(systemName: icon).font(.title3); Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.bold().monospacedDigit()) }.frame(maxWidth: .infinity, minHeight: 105, alignment: .leading).tmCard() }
}

private struct SummaryLine: View {
    let icon, title, value: String
    var body: some View { VStack(spacing: 8) { Image(systemName: icon); Text(value).font(.title2.bold().monospacedDigit()); Text(title).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) }
}
