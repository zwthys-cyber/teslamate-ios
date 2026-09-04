import Charts
import SwiftUI

struct ChargingView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        List(session.chargingSessions) { item in
            NavigationLink { ChargingDetailView(item: item) } label: {
                VStack(alignment: .leading, spacing: 7) {
                    HStack { Label(item.name, systemImage: "bolt.fill").font(.headline); Spacer(); Text(String(format: "%.1f kWh", item.energyAddedKwh ?? 0)).bold() }
                    HStack { Text("\(item.startBatteryLevel ?? 0)% → \(item.endBatteryLevel ?? 0)%"); Spacer(); Text("\(item.durationMin ?? 0) 分钟"); if let cost = item.cost { Spacer(); Text(String(format: "¥%.2f", cost)) } }.font(.subheadline).foregroundStyle(.secondary)
                    Text(DateText.format(item.startDate)).font(.caption).foregroundStyle(.tertiary)
                }.padding(.vertical, 5)
            }
        }
        .navigationTitle("充电")
        .refreshable { await session.refresh() }
        .overlay { if session.chargingSessions.isEmpty { ContentUnavailableView("暂无充电记录", systemImage: "bolt.car") } }
    }
}

private struct ChargingDetailView: View {
    @Environment(AppSession.self) private var session
    let item: ChargingSession
    @State private var samples: [ChargingSample] = []
    var body: some View {
        List {
            if !samples.isEmpty {
                Section("充电功率") {
                    Chart(samples) { sample in LineMark(x: .value("时间", sample.date), y: .value("kW", sample.chargerPower ?? 0)).foregroundStyle(.white) }
                        .frame(height: 220)
                }
            }
            Section("充电详情") {
                LabeledContent("地点", value: item.name)
                LabeledContent("电量", value: "\(item.startBatteryLevel ?? 0)% → \(item.endBatteryLevel ?? 0)%")
                LabeledContent("充入", value: String(format: "%.2f kWh", item.energyAddedKwh ?? 0))
                LabeledContent("耗用", value: String(format: "%.2f kWh", item.energyUsedKwh ?? 0))
                LabeledContent("时长", value: "\(item.durationMin ?? 0) 分钟")
                if let cost = item.cost { LabeledContent("费用", value: String(format: "¥%.2f", cost)) }
            }
        }.navigationTitle("充电详情").task {
            do { samples = try await APIClient(serverURL: session.serverURL, token: session.token).charging(id: item.id).samples }
            catch { session.errorMessage = error.localizedDescription }
        }
    }
}
