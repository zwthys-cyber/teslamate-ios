import Charts
import SwiftUI

struct ChargingView: View {
    @Environment(AppSession.self) private var session
    @State private var searchText = ""

    private var filteredSessions: [ChargingSession] {
        guard !searchText.isEmpty else { return session.chargingSessions }
        return session.chargingSessions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 5) { Text(String(format: "%.1f", session.statistics.charging.energyKwh)).font(.system(size: 44, weight: .semibold, design: .rounded)).tracking(-1.5).monospacedDigit(); Text("累计 kWh").font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 5) { Text("\(session.statistics.charging.count)").font(.title2.weight(.semibold).monospacedDigit()); Text("充电记录").font(.caption).foregroundStyle(.secondary) }
                    }
                    if !filteredSessions.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(filteredSessions.indices, id: \.self) { index in
                                let item = filteredSessions[index]
                                NavigationLink { ChargingDetailView(item: item) } label: { ChargeRow(item: item) }.buttonStyle(.plain)
                                if index != filteredSessions.indices.last { Divider().overlay(.white.opacity(0.1)).padding(.leading, 44) }
                            }
                        }.padding(.horizontal, 16).background(TMStyle.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 16).stroke(TMStyle.border, lineWidth: 0.5) }
                    }
                    if filteredSessions.isEmpty { ContentUnavailableView(searchText.isEmpty ? "暂无充电记录" : "没有匹配记录", systemImage: "bolt.car", description: Text(searchText.isEmpty ? "完成一次充电后会自动出现在这里" : "尝试搜索其他地点")).padding(.top, 80) }
                }.padding(.horizontal, 20).padding(.bottom, 36)
            }
        }
        .navigationTitle("充电")
        .searchable(text: $searchText, prompt: "搜索充电地点")
        .refreshable { await session.refresh() }
    }
}

private struct ChargeRow: View {
    let item: ChargingSession
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "bolt.fill").font(.caption.weight(.semibold)).frame(width: 30, height: 30).background(TMStyle.elevated, in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text("\(item.startBatteryLevel ?? 0)% → \(item.endBatteryLevel ?? 0)% · \(item.durationMin ?? 0) 分钟").font(.caption).foregroundStyle(.secondary)
                Text(DateText.format(item.startDate)).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 5) { Text(String(format: "%.1f", item.energyAddedKwh ?? 0)).font(.headline.monospacedDigit()); Text("kWh").font(.caption2).foregroundStyle(.secondary) }
            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
        }.padding(.vertical, 14).contentShape(Rectangle()).accessibilityElement(children: .combine)
    }
}

struct ChargingDetailView: View {
    @Environment(AppSession.self) private var session
    let item: ChargingSession
    @State private var samples: [ChargingSample] = []
    @State private var exportURL: URL?
    var body: some View {
        List {
            if !samples.isEmpty {
                Section("充电功率") {
                    Chart(samples) { sample in
                        LineMark(x: .value("时间", sample.date), y: .value("kW", sample.chargerPower ?? 0))
                            .foregroundStyle(.white).interpolationMethod(.catmullRom)
                    }
                        .frame(height: 220)
                }
                Section("电量变化") {
                    Chart(samples) { sample in
                        LineMark(x: .value("时间", sample.date), y: .value("电量", sample.batteryLevel ?? 0))
                            .foregroundStyle(.white).interpolationMethod(.catmullRom)
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 220)
                }
            }
            Section("充电详情") {
                LabeledContent("地点", value: item.name)
                LabeledContent("电量", value: "\(item.startBatteryLevel ?? 0)% → \(item.endBatteryLevel ?? 0)%")
                LabeledContent("充入", value: String(format: "%.2f kWh", item.energyAddedKwh ?? 0))
                LabeledContent("耗用", value: String(format: "%.2f kWh", item.energyUsedKwh ?? 0))
                LabeledContent("峰值功率", value: "\(samples.compactMap(\.chargerPower).max() ?? 0) kW")
                if let used = item.energyUsedKwh, used > 0 {
                    LabeledContent("充电效率", value: String(format: "%.1f%%", (item.energyAddedKwh ?? 0) / used * 100))
                }
                LabeledContent("时长", value: "\(item.durationMin ?? 0) 分钟")
                if let cost = item.cost { LabeledContent("费用", value: String(format: "¥%.2f", cost)) }
            }
        }
        .navigationTitle("充电详情")
        .toolbar {
            if let exportURL { ToolbarItem(placement: .topBarTrailing) { ShareLink(item: exportURL) { Image(systemName: "square.and.arrow.up") } } }
        }
        .task {
            do {
                samples = try await APIClient(serverURL: session.serverURL, token: session.token).charging(id: item.id).samples
                exportURL = ExportBuilder.csv(session: item, samples: samples)
            }
            catch { session.errorMessage = error.localizedDescription }
        }
    }
}
