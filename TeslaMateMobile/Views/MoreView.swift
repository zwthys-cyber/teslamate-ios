import SwiftUI

struct MoreView: View {
    @Environment(AppSession.self) private var session
    @State private var settings = false
    var body: some View {
        List {
            Section("地点与围栏") { ForEach(session.geofences) { place in Label { LabeledContent(place.name, value: "\(place.radius) m") } icon: { Image(systemName: "mappin.circle.fill").foregroundStyle(.red) } } }
            Section("完整仪表盘") {
                Link(destination: URL(string: session.serverURL.replacingOccurrences(of: ":4000/", with: ":3000/"))!) { Label("打开中文 Grafana 仪表盘", systemImage: "chart.xyaxis.line") }
            }
            Section("连接") { Button { settings = true } label: { Label("服务器设置", systemImage: "gearshape") }; LabeledContent("服务器", value: session.serverURL) }
        }.navigationTitle("更多").sheet(isPresented: $settings) { ConnectionView() }
    }
}
