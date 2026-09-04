import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        Group {
            if !session.isConfigured { ConnectionView() }
            else if session.vehicles.isEmpty && session.isLoading { ProgressView("正在载入 TeslaMate…") }
            else if let vehicle = session.selectedVehicle {
                TabView {
                    NavigationStack { VehicleDashboard(vehicle: vehicle).navigationTitle("车辆") }
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
        .task {
            await session.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await session.refresh()
            }
        }
    }
}
