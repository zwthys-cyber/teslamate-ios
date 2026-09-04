import MapKit
import SwiftUI
import WebKit

struct MoreView: View {
    @Environment(AppSession.self) private var session
    @State private var settings = false

    var body: some View {
        List {
            Section("地点与围栏") {
                NavigationLink { GeofencesMapView(geofences: session.geofences) } label: { Label("围栏地图", systemImage: "map.fill") }
                ForEach(session.geofences) { place in
                    Label { LabeledContent(place.name, value: "\(place.radius) m") } icon: { Image(systemName: "mappin.circle.fill").foregroundStyle(.red) }
                }
            }
            Section("完整中文仪表盘") {
                NavigationLink { GrafanaView(url: grafanaURL) } label: { Label("浏览全部 Grafana 仪表盘", systemImage: "chart.xyaxis.line") }
                Text("驾驶、充电、效率、电池健康、费用、停车和更新等全部现有仪表盘。").font(.caption).foregroundStyle(.secondary)
            }
            Section("连接与同步") {
                Button { settings = true } label: { Label("服务器设置", systemImage: "gearshape") }
                LabeledContent("自动刷新", value: "每 60 秒")
                LabeledContent("服务器", value: session.serverURL)
            }
            if let error = session.errorMessage { Section("最近错误") { Text(error).foregroundStyle(.red) } }
        }
        .navigationTitle("更多")
        .sheet(isPresented: $settings) { ConnectionView() }
    }

    private var grafanaURL: URL { URL(string: session.serverURL.replacingOccurrences(of: ":4000/", with: ":3000/"))! }
}

private struct GeofencesMapView: View {
    let geofences: [Geofence]
    var body: some View {
        Map {
            ForEach(geofences) { place in
                Marker(place.name, coordinate: .init(latitude: place.latitude, longitude: place.longitude)).tint(.red)
                MapCircle(center: .init(latitude: place.latitude, longitude: place.longitude), radius: CLLocationDistance(place.radius))
                    .foregroundStyle(.red.opacity(0.14)).stroke(.red.opacity(0.7), lineWidth: 1)
            }
        }
        .navigationTitle("地理围栏")
        .overlay { if geofences.isEmpty { ContentUnavailableView("暂无地理围栏", systemImage: "mappin.slash") } }
    }
}

private struct GrafanaView: View {
    let url: URL
    var body: some View {
        GrafanaWebView(url: url).ignoresSafeArea(edges: .bottom).navigationTitle("中文仪表盘").navigationBarTitleDisplayMode(.inline)
    }
}

private struct GrafanaWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.allowsBackForwardNavigationGestures = true
        view.load(URLRequest(url: url))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
