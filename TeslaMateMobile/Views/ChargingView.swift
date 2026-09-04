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
                LazyVStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) { Text("充电历史").font(.title2.bold()); Text("累计 \(String(format: "%.1f", session.statistics.charging.energyKwh)) kWh · \(session.statistics.charging.count) 次").font(.subheadline).foregroundStyle(.secondary) }
                        Spacer(); Image(systemName: "bolt.fill").font(.title2)
                    }.tmCard()
                    ForEach(filteredSessions) { item in
                        NavigationLink { ChargingDetailView(item: item) } label: { ChargeCard(item: item) }.buttonStyle(.plain)
                    }
                    if filteredSessions.isEmpty { ContentUnavailableView(searchText.isEmpty ? "暂无充电记录" : "没有匹配记录", systemImage: "bolt.car", description: Text(searchText.isEmpty ? "完成一次充电后会自动出现在这里" : "尝试搜索其他地点")).padding(.top, 80) }
                }.padding(.horizontal, 18).padding(.bottom, 30)
            }
        }
        .navigationTitle("充电")
        .searchable(text: $searchText, prompt: "搜索充电地点")
        .refreshable { await session.refresh() }
    }
}

private struct ChargeCard: View {
    let item: ChargingSession
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Label(item.name, systemImage: "mappin.and.ellipse").font(.headline).lineLimit(1); Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary) }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", item.energyAddedKwh ?? 0)).font(.system(.largeTitle, design: .rounded, weight: .bold)).monospacedDigit()
                Text("kWh").foregroundStyle(.secondary); Spacer()
                Text("\(item.startBatteryLevel ?? 0)%").foregroundStyle(.secondary); Image(systemName: "arrow.right").font(.caption); Text("\(item.endBatteryLevel ?? 0)%").font(.headline)
            }
            HStack { Label("\(item.durationMin ?? 0) 分钟", systemImage: "clock"); Spacer(); if let cost = item.cost { Label(String(format: "¥%.2f", cost), systemImage: "yensign.circle") } }
                .font(.caption).foregroundStyle(.secondary)
            Text(DateText.format(item.startDate)).font(.caption2).foregroundStyle(.tertiary)
        }.tmCard()
    }
}

private struct ChargingDetailView: View {
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
