import MapKit
import SwiftUI

struct VehicleDashboard: View {
    @Environment(AppSession.self) private var session
    let vehicle: Vehicle

    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 22) {
                    if session.vehicles.count > 1 { vehiclePicker }
                    hero
                    primaryStatus
                    locationCard
                    detailsLink
                }
                .padding(.horizontal, 18).padding(.bottom, 30)
            }
            .refreshable { await session.refresh() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await session.refresh() } } label: {
                    Image(systemName: session.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        .symbolEffect(.pulse, isActive: session.isLoading)
                }.accessibilityLabel("刷新车辆状态")
            }
        }
    }

    private var vehiclePicker: some View {
        Picker("车辆", selection: Binding(get: { session.selectedVehicleID }, set: { id in Task { await session.selectVehicle(id) } })) {
            ForEach(session.vehicles) { Text($0.name).tag($0.id) }
        }.pickerStyle(.segmented)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.name).font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text([vehicle.model.map { "Model \($0)" }, vehicle.trimBadging, "VIN \(vehicle.vinSuffix)"].compactMap { $0 }.joined(separator: "  ·  "))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Label(stateName, systemImage: "circle.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(stateColor)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(stateColor.opacity(0.12), in: Capsule())
            }

            Image(systemName: "car.side.fill")
                .resizable().scaledToFit().frame(maxWidth: 270, maxHeight: 115)
                .symbolRenderingMode(.hierarchical).foregroundStyle(.white.opacity(0.92))
                .shadow(color: .white.opacity(0.12), radius: 24, y: 12)
                .padding(.vertical, 12)

            HStack(spacing: 8) {
                Image(systemName: batteryIcon).foregroundStyle(batteryColor)
                Text("\(vehicle.batteryLevel ?? 0)%").font(.title2.bold().monospacedDigit())
                Text("·").foregroundStyle(.tertiary)
                Text(distance(vehicle.estBatteryRangeKm)).font(.title3.weight(.medium)).foregroundStyle(.secondary)
            }
        }
    }

    private var primaryStatus: some View {
        VStack(spacing: 14) {
            TMSectionTitle("车辆状态", detail: "自动更新")
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                StatusTile("车锁", vehicle.locked == true ? "已锁定" : "未锁定", vehicle.locked == true ? "lock.fill" : "lock.open.fill", .white)
                StatusTile("空调", vehicle.isClimateOn == true ? "运行中" : "已关闭", "fan.fill", .white)
                StatusTile("车内", temperature(vehicle.insideTemp), "thermometer.medium", .white)
                StatusTile("车外", temperature(vehicle.outsideTemp), "sun.max.fill", .white)
                StatusTile("总里程", distance(vehicle.odometer), "gauge.with.dots.needle.67percent", .white)
                StatusTile("软件", vehicle.version ?? "—", "cpu", .white)
            }
        }
    }

    @ViewBuilder private var locationCard: some View {
        if let coordinate {
            VStack(spacing: 14) {
                TMSectionTitle("当前位置", detail: vehicle.geofence)
                Map(initialPosition: .region(.init(center: coordinate, span: .init(latitudeDelta: 0.012, longitudeDelta: 0.012)))) {
                    Annotation(vehicle.name, coordinate: coordinate) {
                        Image(systemName: "car.side.fill").font(.headline).padding(10).background(.white, in: Circle()).foregroundStyle(.black).shadow(radius: 8)
                    }
                }.frame(height: 230).clipShape(.rect(cornerRadius: 16))
                Button {
                    let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                    item.name = vehicle.name
                    item.openInMaps()
                } label: {
                    Label("在系统地图中打开", systemImage: "arrow.up.right.square").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity)
                }.buttonStyle(.plain)
            }.tmCard()
        }
    }

    private var detailsLink: some View {
        NavigationLink { VehicleDetailsView(vehicle: vehicle) } label: {
            HStack(spacing: 14) {
                Image(systemName: "car.side.and.exclamationmark").font(.title2).foregroundStyle(TMStyle.accent)
                VStack(alignment: .leading, spacing: 3) { Text("完整车辆信息").font(.headline); Text("车门、胎压、空调、充电与软件").font(.caption).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }.tmCard()
        }.buttonStyle(.plain)
    }

    private var coordinate: CLLocationCoordinate2D? { guard let lat = vehicle.latitude, let lon = vehicle.longitude else { return nil }; return .init(latitude: lat, longitude: lon) }
    private func distance(_ value: Double?) -> String { value.map { String(format: $0 > 1000 ? "%.0f km" : "%.1f km", $0) } ?? "—" }
    private func temperature(_ value: Double?) -> String { value.map { String(format: "%.1f ℃", $0) } ?? "—" }
    private var stateName: String { ["online":"在线", "asleep":"休眠", "offline":"离线", "driving":"行驶中", "charging":"充电中"][vehicle.state ?? ""] ?? "未知" }
    private var stateColor: Color { ["online", "driving", "charging"].contains(vehicle.state ?? "") ? .white : .secondary }
    private var batteryColor: Color { (vehicle.batteryLevel ?? 0) < 20 ? .secondary : .white }
    private var batteryIcon: String { (vehicle.batteryLevel ?? 0) < 20 ? "battery.25percent" : "battery.75percent" }
}

private struct StatusTile: View {
    let title, value, icon: String
    let tint: Color
    init(_ title: String, _ value: String, _ icon: String, _ tint: Color) { self.title = title; self.value = value; self.icon = icon; self.tint = tint }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(tint).frame(width: 34, height: 34).background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.75) }
            Spacer(minLength: 0)
        }.padding(12).background(TMStyle.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct VehicleDetailsView: View {
    let vehicle: Vehicle
    var body: some View {
        List {
            Section("安全与开闭状态") { status("车辆锁定", vehicle.locked, "lock.fill"); status("车门关闭", vehicle.doorsOpen.map { !$0 }, "car.side"); status("车窗关闭", vehicle.windowsOpen.map { !$0 }, "rectangle.split.3x1"); status("前备箱关闭", vehicle.frunkOpen.map { !$0 }, "car.front.waves.up"); status("后备箱关闭", vehicle.trunkOpen.map { !$0 }, "car.rear"); status("充电口打开", vehicle.chargePortDoorOpen, "bolt.circle"); status("哨兵模式", vehicle.sentryMode, "eye.fill") }
            Section("空调与驾驶") { LabeledContent("车内温度", value: degree(vehicle.insideTemp)); LabeledContent("车外温度", value: degree(vehicle.outsideTemp)); status("空调运行", vehicle.isClimateOn, "fan.fill"); status("预设温度中", vehicle.isPreconditioning, "thermometer.medium"); LabeledContent("当前挡位", value: vehicle.shiftState ?? "P"); LabeledContent("当前速度", value: vehicle.speed.map { String(format: "%.0f km/h", $0) } ?? "—") }
            Section("胎压（bar）") { tire("左前", vehicle.tpmsPressureFl, vehicle.tpmsSoftWarningFl); tire("右前", vehicle.tpmsPressureFr, vehicle.tpmsSoftWarningFr); tire("左后", vehicle.tpmsPressureRl, vehicle.tpmsSoftWarningRl); tire("右后", vehicle.tpmsPressureRr, vehicle.tpmsSoftWarningRr) }
            Section("充电状态") { LabeledContent("状态", value: vehicle.chargingState ?? "未连接"); LabeledContent("充电限制", value: vehicle.chargeLimitSoc.map { "\($0)%" } ?? "—"); LabeledContent("功率", value: vehicle.chargerPower.map { String(format: "%.0f kW", $0) } ?? "—"); LabeledContent("电压", value: vehicle.chargerVoltage.map { String(format: "%.0f V", $0) } ?? "—"); LabeledContent("电流", value: vehicle.chargerActualCurrent.map { String(format: "%.0f A", $0) } ?? "—"); LabeledContent("预计充满", value: vehicle.timeToFullCharge.map { String(format: "%.1f 小时", $0) } ?? "—") }
            Section("软件") { LabeledContent("当前版本", value: vehicle.version ?? "—"); LabeledContent("可用更新", value: vehicle.updateAvailable == true ? (vehicle.updateVersion ?? "有新版本") : "暂无") }
        }.navigationTitle("车辆详情")
    }
    private func status(_ title: String, _ value: Bool?, _ icon: String) -> some View { Label { LabeledContent(title, value: value == nil ? "未知" : (value! ? "是" : "否")) } icon: { Image(systemName: icon) } }
    private func tire(_ title: String, _ value: Double?, _ warning: Bool?) -> some View { LabeledContent(title, value: value.map { String(format: "%.2f", $0) + (warning == true ? " ⚠︎" : "") } ?? "—") }
    private func degree(_ value: Double?) -> String { value.map { String(format: "%.1f ℃", $0) } ?? "—" }
}
