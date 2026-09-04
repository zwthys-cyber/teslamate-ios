import SwiftUI

enum TMStyle {
    static let accent = Color(red: 0.91, green: 0.13, blue: 0.16)
    static let background = Color(red: 0.035, green: 0.039, blue: 0.047)
    static let surface = Color.white.opacity(0.065)
    static let border = Color.white.opacity(0.09)
}

struct TMCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(TMStyle.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(TMStyle.border, lineWidth: 0.75) }
    }
}

extension View {
    func tmCard() -> some View { modifier(TMCard()) }
}

struct TMSectionTitle: View {
    let title: String
    let detail: String?
    init(_ title: String, detail: String? = nil) { self.title = title; self.detail = detail }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.semibold))
            Spacer()
            if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
        }
    }
}
