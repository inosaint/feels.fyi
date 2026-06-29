import SwiftUI

struct WeatherReadoutView: View {
    let temperatureText: String
    let conditionText: String
    private let temperatureVisualYOffset: CGFloat = 70
    @State private var temperatureWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                let readoutWidth = min(proxy.size.width, 330)

                ZStack(alignment: .topLeading) {
                    Text(temperatureText)
                        .font(.custom("Jua", fixedSize: 100))
                        .minimumScaleFactor(0)
                        .lineLimit(1)
                        .background(
                            GeometryReader { textProxy in
                                Color.clear
                                    .preference(key: TemperatureWidthKey.self, value: textProxy.size.width)
                            }
                        )
                        .offset(y: temperatureVisualYOffset)

                    Text("°")
                        .font(.custom("Jua", fixedSize: 42))
                        .offset(
                            x: min(max(0, temperatureWidth - 6), readoutWidth - 15),
                            y: 72
                        )
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
