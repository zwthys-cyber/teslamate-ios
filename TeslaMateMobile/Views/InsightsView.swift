import Charts
import SwiftUI

struct InsightsView: View {
    @Environment(AppSession.self) private var session
    @State private var mode = InsightMode.driving
    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: "%.0f", session.statistics.driving.distanceKm)).font(.system(size: 48, weight: .semibold, design: .rounded)).tracking(-1.8).monospacedDigit()
                        Text("累计驾驶公里").font(.subheadline).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            InsightMetric(title: "驾驶时间", value: duration)
                            Divider().frame(height: 44)
                            InsightMetric(title: "充电量", value: String(format: "%.1f kWh", session.statistics.charging.energyKwh))
                        }.padding(.vertical, 16)
                        Divider().overlay(.white.opacity(0.1))
                        HStack(spacing: 0) {
                            InsightMetric(title: "充电费用", value: String(format: "¥%.2f", session.statistics.charging.cost))
                            Divider().frame(height: 44)
                            InsightMetric(title: "续航消耗比", value: rangeConsumptionRatio)
                        }.padding(.vertical, 16)
                    }.padding(.horizontal, 10).background(TMStyle.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 16).stroke(TMStyle.border, lineWidth: 0.5) }
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
                    VStack(alignment: .leading, spacing: 0) {
                        TMSectionTitle("平均指标")
                        InsightLine(title: "每次行程", value: averageDrive, icon: "road.lanes").padding(.top, 8)
                        Divider().overlay(.white.opacity(0.1))
                        InsightLine(title: "每次充电", value: averageCharge, icon: "bolt")
                        Divider().overlay(.white.opacity(0.1))
                        InsightLine(title: "充电单价", value: averageUnitCost, icon: "banknote")
                    }.tmCard()
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
                }.padding(.horizontal, 20).padding(.bottom, 36)
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

private struct InsightMetric: View {
    let title, value: String
    var body: some View { VStack(spacing: 6) { Text(value).font(.headline.monospacedDigit()).minimumScaleFactor(0.75); Text(title).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) }
}

private struct InsightLine: View {
    let title, value, icon: String
    var body: some View { HStack(spacing: 13) { Image(systemName: icon).foregroundStyle(.secondary).frame(width: 24); Text(title).font(.subheadline); Spacer(); Text(value).font(.subheadline.weight(.semibold).monospacedDigit()) }.padding(.vertical, 14) }
}
