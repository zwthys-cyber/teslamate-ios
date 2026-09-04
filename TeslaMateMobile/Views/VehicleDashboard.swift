import MapKit
import SwiftUI

struct VehicleDashboard: View {
    @Environment(AppSession.self) private var session
    let vehicle: Vehicle

    var body: some View {
        ZStack {
            TMStyle.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 28) {
                    if session.vehicles.count > 1 { vehiclePicker }
                    hero
                    primaryStatus
                    locationCard
                    detailsLink
                }
                .padding(.horizontal, 20).padding(.bottom, 36)
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
        VStack(spacing: 26) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.name).font(.system(size: 34, weight: .semibold, design: .default)).tracking(-0.8)
                    Text([vehicle.model.map { "Model \($0)" }, vehicle.trimBadging, "VIN \(vehicle.vinSuffix)"].compactMap { $0 }.joined(separator: "  ·  "))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 7) { Circle().fill(stateColor).frame(width: 6, height: 6); Text(stateName) }
                    .font(.caption.weight(.medium)).foregroundStyle(stateColor)
                    .padding(.horizontal, 11).padding(.vertical, 7).background(TMStyle.surface, in: Capsule())
            }

            Image(systemName: "car.side.fill")
                .resizable().scaledToFit().frame(maxWidth: 306, maxHeight: 124)
                .symbolRenderingMode(.hierarchical).foregroundStyle(.white.opacity(0.9))
                .padding(.top, 4)

            HStack(alignment: .lastTextBaseline, spacing: 14) {
                Text("\(vehicle.batteryLevel ?? 0)").font(.system(size: 64, weight: .medium, design: .rounded)).tracking(-3).monospacedDigit()
                Text("%").font(.title2.weight(.medium)).foregroundStyle(.secondary).padding(.bottom, 7)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(distance(vehicle.estBatteryRangeKm)).font(.title2.weight(.semibold).monospacedDigit())
                    Text("预估续航").font(.caption).foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var primaryStatus: some View {
        VStack(alignment: .leading, spacing: 14) {
            TMSectionTitle("即时状态", detail: "自动更新")
            HStack(spacing: 0) {
                StatusMetric("车锁", vehicle.locked == true ? "已锁" : "未锁", vehicle.locked == true ? "lock.fill" : "lock.open")
                Divider().frame(height: 42)
                StatusMetric("空调", vehicle.isClimateOn == true ? "运行" : "关闭", "fan")
                Divider().frame(height: 42)
                StatusMetric("车内", temperature(vehicle.insideTemp), "thermometer.medium")
            }
            .tmCard()
            VStack(spacing: 0) {
                DetailLine(title: "总里程", value: distance(vehicle.odometer), icon: "gauge.with.dots.needle.67percent")
                Divider().overlay(.white.opacity(0.1))
                DetailLine(title: "车外温度", value: temperature(vehicle.outsideTemp), icon: "thermometer.low")
                Divider().overlay(.white.opacity(0.1))
                DetailLine(title: "车辆软件", value: vehicle.version ?? "—", icon: "cpu")
            }.padding(.horizontal, 16).background(TMStyle.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 16).stroke(TMStyle.border, lineWidth: 0.5) }
        }
    }

    @ViewBuilder private var locationCard: some View {
        if let coordinate {
            VStack(alignment: .leading, spacing: 14) {
                TMSectionTitle("当前位置", detail: vehicle.geofence)
                Map(initialPosition: .region(.init(center: coordinate, span: .init(latitudeDelta: 0.012, longitudeDelta: 0.012)))) {
                    Annotation(vehicle.name, coordinate: coordinate) {
                        Image(systemName: "car.side.fill").font(.headline).padding(10).background(.white, in: Circle()).foregroundStyle(.black).shadow(radius: 8)
                    }
                }.frame(height: 250).clipShape(.rect(cornerRadius: 16)).overlay { RoundedRectangle(cornerRadius: 16).stroke(TMStyle.border, lineWidth: 0.5) }
                Button {
                    let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                    item.name = vehicle.name
                    item.openInMaps()
                } label: {
                    Label("在系统地图中打开", systemImage: "arrow.up.right.square").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity)
                }.buttonStyle(.plain)
            }
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

private struct StatusMetric: View {
    let title, value, icon: String
    init(_ title: String, _ value: String, _ icon: String) { self.title = title; self.value = value; self.icon = icon }
    var body: some View {
        VStack(spacing: 7) { Image(systemName: icon).font(.body); Text(value).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.75); Text(title).font(.caption2).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
    }
}

private struct DetailLine: View {
    let title, value, icon: String
    var body: some View { HStack(spacing: 13) { Image(systemName: icon).foregroundStyle(.secondary).frame(width: 24); Text(title).font(.subheadline); Spacer(); Text(value).font(.subheadline.weight(.medium).monospacedDigit()) }.padding(.vertical, 14) }
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
