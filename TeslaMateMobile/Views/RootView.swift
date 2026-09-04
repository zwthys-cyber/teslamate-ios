import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        Group {
            if !session.isConfigured { ConnectionView() }
            else if session.vehicles.isEmpty && session.isLoading { ProgressView("正在载入 TeslaMate…") }
            else if let vehicle = session.selectedVehicle {
                TabView {
                    NavigationStack { VehicleDashboard(vehicle: vehicle).navigationTitle("").navigationBarTitleDisplayMode(.inline) }
                        .tabItem { Label("车辆", systemImage: "car.side.fill") }
                    NavigationStack { DrivesView() }
                        .tabItem { Label("行程", systemImage: "road.lanes") }
                    NavigationStack { ChargingView() }
                        .tabItem { Label("充电", systemImage: "bolt.car.fill") }
                    NavigationStack { InsightsView() }
                        .tabItem { Label("统计", systemImage: "chart.bar.xaxis") }
                    NavigationStack { MoreView() }
                        .tabItem { Label("更多", systemImage: "ellipsis.circle") }
                }
            } else {
                ContentUnavailableView("暂时没有车辆数据", systemImage: "car.side", description: Text(session.errorMessage ?? "请检查 Tailscale 和服务器设置"))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if session.isShowingCachedData {
                HStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                    Text("正在显示缓存数据").font(.caption.weight(.semibold))
                    Spacer()
                    Button("重试") { Task { await session.refresh() } }.font(.caption.bold())
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(.black.opacity(0.94)).overlay(alignment: .bottom) { Divider().overlay(.white.opacity(0.15)) }
            }
        }
        .task {
            await session.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await session.refresh()
            }
        }
    }
}
