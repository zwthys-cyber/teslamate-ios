import SwiftUI

struct ConnectionView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var serverURL = ""
    @State private var token = ""
    @State private var isConnecting = false
    @FocusState private var focusedField: Field?

    private enum Field { case server, token }

    var body: some View {
        NavigationStack {
            ZStack {
                TMStyle.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 16) {
                            Image(systemName: "car.side.fill").font(.system(size: 64, weight: .light)).symbolRenderingMode(.hierarchical)
                            VStack(spacing: 6) {
                                Text("连接 TeslaMate").font(.system(.title, design: .rounded, weight: .bold))
                                Text("安全访问你自己的车辆数据").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }.padding(.top, 24)

                        VStack(alignment: .leading, spacing: 18) {
                            connectionField("服务器地址", hint: "http://100.88.30.82:4000/", icon: "server.rack") {
                                TextField("服务器地址", text: $serverURL).textInputAutocapitalization(.never).keyboardType(.URL).focused($focusedField, equals: .server)
                            }
                            Divider().overlay(.white.opacity(0.12))
                            connectionField("访问令牌", hint: "64 位安全令牌", icon: "key.fill") {
                                SecureField("访问令牌", text: $token).textInputAutocapitalization(.never).focused($focusedField, equals: .token)
                            }
                        }.tmCard()

                        Button(action: connect) {
                            HStack(spacing: 10) {
                                if isConnecting { ProgressView().tint(.black) }
                                Text(isConnecting ? "正在验证连接" : "保存并连接").font(.headline)
                            }.frame(maxWidth: .infinity).padding(.vertical, 15).background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous)).foregroundStyle(.black)
                        }
                        .disabled(serverURL.isEmpty || token.isEmpty || isConnecting).opacity(serverURL.isEmpty || token.isEmpty ? 0.42 : 1)

                        if let error = session.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle").font(.subheadline).frame(maxWidth: .infinity, alignment: .leading).tmCard()
                        }

                        VStack(spacing: 8) {
                            Label("使用前请开启 Tailscale", systemImage: "network")
                            Label("令牌仅保存在本机钥匙串", systemImage: "lock.shield")
                        }.font(.caption).foregroundStyle(.secondary)
                    }.padding(.horizontal, 22).padding(.bottom, 30)
                }.scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { serverURL = session.serverURL; token = session.token }
        }
    }

    private func connectionField<Content: View>(_ title: String, hint: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).frame(width: 30).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption).foregroundStyle(.secondary); content().font(.body); Text(hint).font(.caption2).foregroundStyle(.tertiary) }
        }
    }

    private func connect() {
        focusedField = nil
        Task {
            isConnecting = true
            session.save(serverURL: serverURL, token: token)
            await session.refresh()
            isConnecting = false
            if session.errorMessage == nil { dismiss() }
        }
    }
}
