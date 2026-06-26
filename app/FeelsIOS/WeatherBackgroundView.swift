import SwiftUI

struct WeatherBackgroundView: View {
    let visual: WeatherVisual

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                visual.fallbackColor

                Image(visual.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }
}

extension WeatherVisual {
    var fallbackColor: Color {
        switch self {
        case .hot:
            return Color(red: 0.94, green: 0.96, blue: 0.0)
        case .clearMorning:
            return Color(red: 0.52, green: 0.71, blue: 0.82)
        case .clearEvening:
            return Color(red: 0.04, green: 0.56, blue: 0.84)
        case .cloudy:
            return Color(red: 0.04, green: 0.37, blue: 0.91)
        case .fog:
            return Color(red: 0.23, green: 0.09, blue: 0.36)
        case .drizzle:
            return Color(red: 0.48, green: 0.56, blue: 0.58)
        case .rain:
            return Color(red: 0.23, green: 0.35, blue: 0.69)
        case .storm:
            return Color(red: 0.21, green: 0.08, blue: 0.94)
        }
    }
}
