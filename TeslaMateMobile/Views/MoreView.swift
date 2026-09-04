import MapKit
import SwiftUI
import WebKit

struct MoreView: View {
    @Environment(AppSession.self) private var session
    @State private var settings = false

    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: session.errorMessage == nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill").font(.title2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.errorMessage == nil ? "服务器已连接" : "连接需要检查").font(.headline)
                            Text(syncDescription).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if session.isLoading { ProgressView().tint(.white) }
                    }.tmCard()

                    VStack(alignment: .leading, spacing: 12) {
                        TMSectionTitle("数据与地点")
                        NavigationLink { TimelineView() } label: { MenuRow(icon: "clock.arrow.circlepath", title: "车辆时间轴", subtitle: "行程、充电与软件更新") }
                        Divider().overlay(.white.opacity(0.1))
                        NavigationLink { BatteryHealthView(samples: session.batteryHealth) } label: { MenuRow(icon: "battery.75percent", title: "电池健康", subtitle: "满电等效续航与长期趋势") }
                        Divider().overlay(.white.opacity(0.1))
                        NavigationLink { GeofencesMapView(geofences: session.geofences) } label: { MenuRow(icon: "map.fill", title: "地理围栏", subtitle: "\(session.geofences.count) 个已保存地点") }
                        Divider().overlay(.white.opacity(0.1))
                        NavigationLink { SoftwareUpdatesView(updates: session.updates) } label: { MenuRow(icon: "gearshape.2", title: "软件更新历史", subtitle: "\(session.updates.count) 条车辆固件记录") }
                        Divider().overlay(.white.opacity(0.1))
                        NavigationLink { GrafanaView(url: grafanaURL) } label: { MenuRow(icon: "chart.xyaxis.line", title: "完整中文仪表盘", subtitle: "驾驶、充电、效率、电池与费用") }
                    }.buttonStyle(.plain).tmCard()

                    VStack(alignment: .leading, spacing: 12) {
                        TMSectionTitle("连接与应用")
                        Button { settings = true } label: { MenuRow(icon: "server.rack", title: "服务器设置", subtitle: displayServer) }
                        Divider().overlay(.white.opacity(0.1))
                        MenuRow(icon: "arrow.clockwise", title: "自动同步", subtitle: "每 60 秒")
                        Divider().overlay(.white.opacity(0.1))
                        MenuRow(icon: "info.circle", title: "TeslaMate iOS", subtitle: "版本 2.0.1 · 黑白专业版")
                    }.buttonStyle(.plain).tmCard()

                    if let error = session.errorMessage {
                        VStack(alignment: .leading, spacing: 8) { Label("最近错误", systemImage: "exclamationmark.triangle").font(.headline); Text(error).font(.subheadline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).tmCard()
                    }
                }.padding(.horizontal, 18).padding(.bottom, 30)
            }.refreshable { await session.refresh() }
        }
        .navigationTitle("更多")
        .sheet(isPresented: $settings) { ConnectionView() }
    }

    private var grafanaURL: URL { URL(string: session.serverURL.replacingOccurrences(of: ":4000/", with: ":3000/"))! }
    private var displayServer: String { URL(string: session.serverURL)?.host ?? session.serverURL }
    private var syncDescription: String {
        if let error = session.errorMessage { return error }
        if let date = session.lastUpdated { return "上次同步 " + date.formatted(date: .omitted, time: .shortened) }
        return "等待首次同步"
    }
}

private struct SoftwareUpdatesView: View {
    let updates: [SoftwareUpdate]
    var body: some View {
        List {
            ForEach(updates) { update in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle().fill(.white).frame(width: 9, height: 9)
                        Rectangle().fill(.white.opacity(0.18)).frame(width: 1, height: 48)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(update.version ?? "未知版本").font(.headline.monospaced())
                        Text(DateText.format(update.startDate)).font(.caption).foregroundStyle(.secondary)
                        Text(update.endDate == nil ? "记录中" : "已完成").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("软件更新历史")
        .overlay { if updates.isEmpty { ContentUnavailableView("暂无更新记录", systemImage: "gearshape.2") } }
    }
}

private struct MenuRow: View {
    let icon, title, subtitle: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).frame(width: 32)
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.subheadline.weight(.semibold)); Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }.contentShape(Rectangle())
    }
}

private struct GeofencesMapView: View {
    let geofences: [Geofence]
    var body: some View {
        Map {
            ForEach(geofences) { place in
                Marker(place.name, coordinate: ChinaCoordinate.display(latitude: place.latitude, longitude: place.longitude)).tint(.white)
                MapCircle(center: ChinaCoordinate.display(latitude: place.latitude, longitude: place.longitude), radius: CLLocationDistance(place.radius))
                    .foregroundStyle(.white.opacity(0.12)).stroke(.white.opacity(0.7), lineWidth: 1)
            }
        }
        .navigationTitle("地理围栏")
        .overlay { if geofences.isEmpty { ContentUnavailableView("暂无地理围栏", systemImage: "mappin.slash") } }
    }
}

private struct GrafanaView: View {
    let url: URL
    @StateObject private var browser = GrafanaBrowser()
    var body: some View {
        GrafanaWebView(browser: browser, url: url)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("中文仪表盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { browser.webView.goBack() } label: { Image(systemName: "chevron.left") }
                    Button { browser.webView.goForward() } label: { Image(systemName: "chevron.right") }
                    Spacer()
                    Button { browser.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
                }
            }
    }
}

private final class GrafanaBrowser: ObservableObject {
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.allowsBackForwardNavigationGestures = true
        return view
    }()
}

private struct GrafanaWebView: UIViewRepresentable {
    let browser: GrafanaBrowser
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        browser.webView.load(URLRequest(url: url))
        return browser.webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
