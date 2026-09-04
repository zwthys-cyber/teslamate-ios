import Charts
import SwiftUI

struct InsightsView: View {
    @Environment(AppSession.self) private var session
    @State private var mode = InsightMode.driving
    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 12) { StatCard(title: "总里程", value: String(format: "%.0f km", session.statistics.driving.distanceKm), icon: "road.lanes"); StatCard(title: "驾驶时间", value: duration, icon: "clock") }
                    HStack(spacing: 12) { StatCard(title: "充电量", value: String(format: "%.1f kWh", session.statistics.charging.energyKwh), icon: "bolt.fill"); StatCard(title: "充电费用", value: String(format: "¥%.2f", session.statistics.charging.cost), icon: "yensign.circle") }
                    Picker("统计类型", selection: $mode) { ForEach(InsightMode.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented)
                    VStack(alignment: .leading, spacing: 18) {
                        TMSectionTitle(chartTitle, detail: "近 12 个月")
                        switch mode {
                        case .driving:
                            Chart(session.statistics.monthlyDriving) { item in
                                BarMark(x: .value("月份", item.month), y: .value("里程", item.distanceKm)).foregroundStyle(.white)
                            }
                        case .charging:
                            Chart(session.statistics.monthlyCharging) { item in
                                BarMark(x: .value("月份", item.month), y: .value("电量", item.energyKwh)).foregroundStyle(.white)
                            }
                        case .cost:
                            Chart(session.statistics.monthlyCharging) { item in
                                BarMark(x: .value("月份", item.month), y: .value("费用", item.cost)).foregroundStyle(.white)
                            }
                        }
                    }.chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisGridLine().foregroundStyle(.white.opacity(0.08)); AxisValueLabel().foregroundStyle(.secondary) } }.frame(height: 280).tmCard()
                    HStack(spacing: 12) {
                        StatCard(title: "平均每次行程", value: averageDrive, icon: "point.topleft.down.to.point.bottomright.curvepath")
                        StatCard(title: "平均每次充电", value: averageCharge, icon: "bolt.badge.clock")
                    }
                    HStack(spacing: 12) {
                        StatCard(title: "平均充电单价", value: averageUnitCost, icon: "banknote")
                        StatCard(title: "续航消耗比", value: rangeConsumptionRatio, icon: "gauge.with.dots.needle.50percent")
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        TMSectionTitle("续航消耗比趋势", detail: "1.0 表示表显续航与实际里程相同")
                        if rangeRatioDrives.isEmpty {
                            Text("暂无足够的行程续航数据").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            Chart {
                                ForEach(Array(rangeRatioDrives.prefix(30).reversed())) { drive in
                                    LineMark(x: .value("日期", DateText.format(drive.startDate)), y: .value("消耗比", ratio(for: drive)))
                                        .foregroundStyle(.white).interpolationMethod(.catmullRom)
                                }
                                RuleMark(y: .value("基准", 1)).foregroundStyle(.secondary).lineStyle(.init(dash: [4, 5]))
                            }
                            .chartXAxis(.hidden).frame(height: 180)
                        }
                    }.tmCard()
                    VStack(alignment: .leading, spacing: 18) {
                        TMSectionTitle("最近充电单价", detail: "费用 ÷ 充入电量")
                        if pricedCharging.isEmpty {
                            Text("为充电记录填写费用后会显示单价趋势").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            Chart(Array(pricedCharging.prefix(30).reversed())) { item in
                                LineMark(x: .value("日期", DateText.format(item.startDate)), y: .value("单价", unitCost(for: item)))
                                    .foregroundStyle(.white).interpolationMethod(.catmullRom)
                            }
                            .chartXAxis(.hidden).frame(height: 180)
                        }
                    }.tmCard()
                    VStack(alignment: .leading, spacing: 18) {
                        TMSectionTitle("最近行程", detail: "最近 14 次")
                        Chart(Array(session.drives.prefix(14).reversed())) { drive in BarMark(x: .value("日期", DateText.format(drive.startDate)), y: .value("里程", drive.distanceKm ?? 0)).foregroundStyle(.white) }
                            .chartXAxis(.hidden).frame(height: 180)
                    }.tmCard()
                    HStack { SummaryLine(icon: "car.fill", title: "行程次数", value: "\(session.statistics.driving.count)"); Divider(); SummaryLine(icon: "bolt.fill", title: "充电次数", value: "\(session.statistics.charging.count)") }.tmCard()
                }.padding(.horizontal, 18).padding(.bottom, 30)
            }.refreshable { await session.refresh() }
        }.navigationTitle("统计")
    }

    private var duration: String { let minutes = session.statistics.driving.durationMin; return minutes >= 60 ? "\(minutes / 60) 小时" : "\(minutes) 分钟" }
    private var chartTitle: String { switch mode { case .driving: "月度驾驶里程"; case .charging: "月度充电量"; case .cost: "月度充电费用" } }
    private var averageDrive: String { session.statistics.driving.count > 0 ? String(format: "%.1f km", session.statistics.driving.distanceKm / Double(session.statistics.driving.count)) : "--" }
    private var averageCharge: String { session.statistics.charging.count > 0 ? String(format: "%.1f kWh", session.statistics.charging.energyKwh / Double(session.statistics.charging.count)) : "--" }
    private var pricedCharging: [ChargingSession] { session.chargingSessions.filter { ($0.cost ?? 0) > 0 && ($0.energyAddedKwh ?? 0) > 0 } }
    private var averageUnitCost: String {
        let energy = pricedCharging.reduce(0) { $0 + ($1.energyAddedKwh ?? 0) }
        let cost = pricedCharging.reduce(0) { $0 + ($1.cost ?? 0) }
        return energy > 0 ? String(format: "¥%.2f/kWh", cost / energy) : "--"
    }
    private var rangeRatioDrives: [Drive] { session.drives.filter { ($0.distanceKm ?? 0) > 0 && (($0.startRangeKm ?? 0) - ($0.endRangeKm ?? 0)) > 0 } }
    private var rangeConsumptionRatio: String {
        guard !rangeRatioDrives.isEmpty else { return "--" }
        return String(format: "%.2f", rangeRatioDrives.reduce(0) { $0 + ratio(for: $1) } / Double(rangeRatioDrives.count))
    }
    private func ratio(for drive: Drive) -> Double { max(0, (drive.startRangeKm ?? 0) - (drive.endRangeKm ?? 0)) / max(0.1, drive.distanceKm ?? 0) }
    private func unitCost(for item: ChargingSession) -> Double { (item.cost ?? 0) / max(0.01, item.energyAddedKwh ?? 0) }
}

private enum InsightMode: String, CaseIterable, Identifiable {
    case driving, charging, cost
    var id: Self { self }
    var title: String { switch self { case .driving: "驾驶"; case .charging: "充电"; case .cost: "费用" } }
}

private struct StatCard: View {
    let title, value, icon: String
    var body: some View { VStack(alignment: .leading, spacing: 14) { Image(systemName: icon).font(.title3); Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.bold().monospacedDigit()) }.frame(maxWidth: .infinity, minHeight: 105, alignment: .leading).tmCard() }
}

private struct SummaryLine: View {
    let icon, title, value: String
    var body: some View { VStack(spacing: 8) { Image(systemName: icon); Text(value).font(.title2.bold().monospacedDigit()); Text(title).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) }
}
