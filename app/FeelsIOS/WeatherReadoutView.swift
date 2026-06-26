import SwiftUI

struct WeatherReadoutView: View {
    let temperatureText: String
    let conditionText: String
    @State private var temperatureWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                let readoutWidth = min(proxy.size.width, 330)

                ZStack(alignment: .topLeading) {
                    Text(temperatureText)
                        .font(.custom("Caveat Brush", fixedSize: 252))
                        .minimumScaleFactor(0.58)
                        .lineLimit(1)
                        .background(
                            GeometryReader { textProxy in
                                Color.clear
                                    .preference(key: TemperatureWidthKey.self, value: textProxy.size.width)
                            }
                        )

                    Text("°")
                        .font(.custom("Caveat Brush", fixedSize: 42))
                        .offset(x: min(max(0, temperatureWidth - 6), readoutWidth - 15), y: 38)
                }
                .frame(width: readoutWidth, height: 166, alignment: .topLeading)
            }
            .frame(height: 166)
            .foregroundStyle(WeatherPalette.ink)
            .onPreferenceChange(TemperatureWidthKey.self) { width in
                temperatureWidth = width
            }

            Text(conditionText)
                .font(.system(size: 26, weight: .regular))
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(WeatherPalette.ink)
                .padding(.leading, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TemperatureWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
