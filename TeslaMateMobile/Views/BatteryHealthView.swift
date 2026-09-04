import Charts
import SwiftUI

struct BatteryHealthView: View {
    let samples: [BatteryHealthSample]

    private var latest: BatteryHealthSample? { samples.first }
    private var oldest: BatteryHealthSample? { samples.last }
    private var change: Double? {
        guard let latest = latest?.fullRangeKm, let oldest = oldest?.fullRangeKm, oldest > 0 else { return nil }
        return (latest - oldest) / oldest * 100
    }

    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 12) {
                        BatteryMetric(title: "当前等效满电续航", value: latest?.fullRangeKm.map { String(format: "%.0f km", $0) } ?? "--")
                        BatteryMetric(title: "记录期变化", value: change.map { String(format: "%+.1f%%", $0) } ?? "--")
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        TMSectionTitle("满电等效续航趋势", detail: "共 \(samples.count) 天")
                        if samples.isEmpty {
                            ContentUnavailableView("暂无足够数据", systemImage: "battery.75percent", description: Text("车辆电量达到 80% 后会逐步形成趋势"))
                                .frame(minHeight: 220)
                        } else {
                            Chart(Array(samples.reversed())) { sample in
                                LineMark(x: .value("日期", sample.date), y: .value("续航", sample.fullRangeKm ?? 0))
                                    .foregroundStyle(.white)
                                    .interpolationMethod(.catmullRom)
                                PointMark(x: .value("日期", sample.date), y: .value("续航", sample.fullRangeKm ?? 0))
                                    .foregroundStyle(.white)
                            }
                            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisGridLine().foregroundStyle(.white.opacity(0.08)); AxisValueLabel().foregroundStyle(.secondary) } }
                            .chartYAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(.white.opacity(0.08)); AxisValueLabel().foregroundStyle(.secondary) } }
                            .frame(height: 250)
                        }
                    }.tmCard()

                    VStack(alignment: .leading, spacing: 14) {
                        TMSectionTitle("记录摘要")
                        BatteryRow(title: "最早样本", value: oldest?.date ?? "--")
                        Divider().overlay(.white.opacity(0.1))
                        BatteryRow(title: "最新样本", value: latest?.date ?? "--")
                        Divider().overlay(.white.opacity(0.1))
                        BatteryRow(title: "最新里程表", value: latest?.odometer.map { String(format: "%.0f km", $0) } ?? "--")
                        Divider().overlay(.white.opacity(0.1))
                        BatteryRow(title: "最新样本点", value: latest.map { "\($0.samples) 个" } ?? "--")
                    }.tmCard()

                    Text("等效满电续航依据电量不低于 80% 时的表显额定续航换算，用于观察长期趋势。温度、轮胎和车辆校准都会影响结果，它不是电池容量检测报告。")
                        .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).tmCard()
                }
                .padding(.horizontal, 18).padding(.bottom, 30)
            }
        }
        .navigationTitle("电池健康")
    }
}

private struct BatteryMetric: View {
    let title, value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold().monospacedDigit()).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading).tmCard()
    }
}

private struct BatteryRow: View {
    let title, value: String
    var body: some View { HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value).font(.body.monospacedDigit()) } }
}
