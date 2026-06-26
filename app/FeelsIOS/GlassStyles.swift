import SwiftUI

enum WeatherPalette {
    static let ink = Color(red: 0.13, green: 0.02, blue: 0.07)
}

extension View {
    @ViewBuilder
    func searchFieldGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(.white.opacity(0.24)).interactive(), in: .capsule)
        } else {
            self
                .background(Color(.secondarySystemBackground), in: Capsule())
        }
    }

    @ViewBuilder
    func searchActionGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(.white.opacity(0.14)).interactive(), in: .capsule)
        } else {
            self
                .background(Color(.secondarySystemBackground), in: Capsule())
        }
    }

    @ViewBuilder
    func locationPillGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(.white.opacity(0.22)).interactive(), in: .capsule)
                .shadow(color: .black.opacity(0.16), radius: 23, x: 0, y: 18)
        } else {
            self
                .background(.white.opacity(0.34), in: Capsule())
                .shadow(color: .black.opacity(0.16), radius: 23, x: 0, y: 18)
        }
    }
}
