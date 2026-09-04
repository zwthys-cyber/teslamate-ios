import MapKit
import SwiftUI

struct VehicleDashboard: View {
    let vehicle: Vehicle

    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude = vehicle.latitude, let longitude = vehicle.longitude else { return nil }
        return .init(latitude: latitude, longitude: longitude)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if let coordinate {
                    Map(initialPosition: .region(.init(
                        center: coordinate,
                        span: .init(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    ))) {
                        Annotation(vehicle.name, coordinate: coordinate) {
                            Image(systemName: "car.side.fill")
                                .padding(9)
                                .background(.red, in: Circle())
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(height: 230)
                    .clipShape(.rect(cornerRadius: 18))
                }
                metrics
                NavigationLink { VehicleDetailsView(vehicle: vehicle) } label: {
                    Label("查看完整车辆状态", systemImage: "list.bullet.rectangle.portrait")
                        .frame(maxWidth: .infinity).padding().background(.thinMaterial, in: .rect(cornerRadius: 16))
                }
            }
            .padding()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(vehicle.name).font(.largeTitle.bold())
                Text([vehicle.model, vehicle.trimBadging, "VIN \(vehicle.vinSuffix)"].compactMap { $0 }.joined(separator: " · "))
                    .font(.subheadline).foregroundStyle(.secondary)
                Label(stateName, systemImage: stateIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(stateColor)
            }
            Spacer()
            ZStack {
                Circle().stroke(.secondary.opacity(0.25), lineWidth: 7)
                Circle().trim(from: 0, to: Double(vehicle.batteryLevel ?? 0) / 100)
                    .stroke(batteryColor, style: .init(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(vehicle.batteryLevel ?? 0)%").font(.headline.monospacedDigit())
            }
            .frame(width: 72, height: 72)
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            MetricCard(title: "预估续航", value: distance(vehicle.estBatteryRangeKm), icon: "road.lanes")
            MetricCard(title: "典型续航", value: distance(vehicle.idealBatteryRangeKm), icon: "bolt.fill")
            MetricCard(title: "车内温度", value: temperature(vehicle.insideTemp), icon: "thermometer.medium")
            MetricCard(title: "车外温度", value: temperature(vehicle.outsideTemp), icon: "sun.max.fill")
            MetricCard(title: "总里程", value: distance(vehicle.odometer), icon: "gauge.with.dots.needle.67percent")
            MetricCard(title: "固件", value: vehicle.version ?? "—", icon: "cpu")
            MetricCard(title: "车锁", value: vehicle.locked == true ? "已锁定" : "未锁定", icon: vehicle.locked == true ? "lock.fill" : "lock.open.fill")
            MetricCard(title: "位置", value: vehicle.geofence ?? "未知", icon: "location.fill")
            MetricCard(title: "空调", value: vehicle.isClimateOn == true ? "运行中" : "已关闭", icon: "fan.fill")
            MetricCard(title: "哨兵模式", value: vehicle.sentryMode == true ? "已开启" : "已关闭", icon: "eye.fill")
        }
    }

    private func distance(_ value: Double?) -> String { value.map { String(format: "%.1f km", $0) } ?? "—" }
    private func temperature(_ value: Double?) -> String { value.map { String(format: "%.1f ℃", $0) } ?? "—" }
    private var stateName: String { ["online": "在线", "asleep": "休眠", "offline": "离线", "driving": "行驶中", "charging": "充电中"][vehicle.state ?? ""] ?? "状态未知" }
    private var stateIcon: String { vehicle.state == "online" ? "checkmark.circle.fill" : "moon.zzz.fill" }
    private var stateColor: Color { vehicle.state == "online" ? .green : .secondary }
    private var batteryColor: Color { (vehicle.batteryLevel ?? 0) < 20 ? .red : .green }
}

private struct VehicleDetailsView: View {
    let vehicle: Vehicle
    var body: some View {
        List {
            Section("安全与开闭状态") {
                status("车辆锁定", vehicle.locked, "lock.fill")
                status("车门关闭", vehicle.doorsOpen.map { !$0 }, "car.side")
                status("车窗关闭", vehicle.windowsOpen.map { !$0 }, "rectangle.split.3x1")
                status("前备箱关闭", vehicle.frunkOpen.map { !$0 }, "car.front.waves.up")
                status("后备箱关闭", vehicle.trunkOpen.map { !$0 }, "car.rear")
                status("充电口打开", vehicle.chargePortDoorOpen, "bolt.circle")
                status("哨兵模式", vehicle.sentryMode, "eye.fill")
            }
            Section("空调与驾驶") {
                LabeledContent("车内温度", value: degree(vehicle.insideTemp))
                LabeledContent("车外温度", value: degree(vehicle.outsideTemp))
                status("空调运行", vehicle.isClimateOn, "fan.fill")
                status("预设温度中", vehicle.isPreconditioning, "thermometer.medium")
                LabeledContent("当前挡位", value: vehicle.shiftState ?? "P")
                LabeledContent("当前速度", value: vehicle.speed.map { String(format: "%.0f km/h", $0) } ?? "—")
            }
            Section("胎压（bar）") {
                tire("左前", vehicle.tpmsPressureFl, vehicle.tpmsSoftWarningFl)
                tire("右前", vehicle.tpmsPressureFr, vehicle.tpmsSoftWarningFr)
                tire("左后", vehicle.tpmsPressureRl, vehicle.tpmsSoftWarningRl)
                tire("右后", vehicle.tpmsPressureRr, vehicle.tpmsSoftWarningRr)
            }
            Section("充电状态") {
                LabeledContent("状态", value: vehicle.chargingState ?? "未连接")
                LabeledContent("充电限制", value: vehicle.chargeLimitSoc.map { "\($0)%" } ?? "—")
                LabeledContent("功率", value: vehicle.chargerPower.map { String(format: "%.0f kW", $0) } ?? "—")
                LabeledContent("电压", value: vehicle.chargerVoltage.map { String(format: "%.0f V", $0) } ?? "—")
                LabeledContent("电流", value: vehicle.chargerActualCurrent.map { String(format: "%.0f A", $0) } ?? "—")
                LabeledContent("预计充满", value: vehicle.timeToFullCharge.map { String(format: "%.1f 小时", $0) } ?? "—")
            }
            Section("软件") {
                LabeledContent("当前版本", value: vehicle.version ?? "—")
                LabeledContent("可用更新", value: vehicle.updateAvailable == true ? (vehicle.updateVersion ?? "有新版本") : "暂无")
            }
        }.navigationTitle("车辆详情")
    }

    private func status(_ title: String, _ value: Bool?, _ icon: String) -> some View {
        Label { LabeledContent(title, value: value == nil ? "未知" : (value! ? "是" : "否")) } icon: { Image(systemName: icon) }
    }
    private func tire(_ title: String, _ value: Double?, _ warning: Bool?) -> some View {
        LabeledContent(title, value: value.map { String(format: "%.2f", $0) + (warning == true ? " ⚠︎" : "") } ?? "—")
    }
    private func degree(_ value: Double?) -> String { value.map { String(format: "%.1f ℃", $0) } ?? "—" }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}
