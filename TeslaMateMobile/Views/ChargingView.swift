import SwiftUI

struct ChargingView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        List(session.chargingSessions) { item in
            VStack(alignment: .leading, spacing: 7) {
                HStack { Label(item.name, systemImage: "bolt.fill").font(.headline); Spacer(); Text(String(format: "%.1f kWh", item.energyAddedKwh ?? 0)).bold() }
                HStack {
                    Text("\(item.startBatteryLevel ?? 0)% → \(item.endBatteryLevel ?? 0)%")
                    Spacer(); Text("\(item.durationMin ?? 0) 分钟")
                    if let cost = item.cost { Spacer(); Text(String(format: "¥%.2f", cost)) }
                }.font(.subheadline).foregroundStyle(.secondary)
                Text(DateText.format(item.startDate)).font(.caption).foregroundStyle(.tertiary)
            }.padding(.vertical, 5)
        }
        .navigationTitle("充电")
        .refreshable { await session.refresh() }
        .overlay { if session.chargingSessions.isEmpty { ContentUnavailableView("暂无充电记录", systemImage: "bolt.car") } }
    }
}
