import SwiftUI
import UIKit

@MainActor
enum AppHaptics {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

struct WeatherSceneView: View {
    let viewModel: WeatherViewModel
    let showsLocationButton: Bool
    @State private var hasDisplayedWeather = false

    init(viewModel: WeatherViewModel, showsLocationButton: Bool = true) {
        self.viewModel = viewModel
        self.showsLocationButton = showsLocationButton
    }

    private var snapshot: WeatherSnapshot? {
        viewModel.displayedSnapshot
    }

    private var hasWeatherData: Bool {
        snapshot != nil
    }

    private var availabilityAnimation: Animation? {
        hasDisplayedWeather ? .easeOut(duration: 0.36) : nil
    }

    var body: some View {
        ZStack {
            WeatherBackgroundView(visual: viewModel.currentVisual)
                .opacity(hasWeatherData ? 1 : 0)

            WeatherStatusView(
                state: viewModel.state,
                isLoading: viewModel.isInitialLoading
            )
            .opacity(hasWeatherData ? 0 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: .bottom)
        .overlay(alignment: .topLeading) {
            WeatherReadoutView(
                temperatureText: viewModel.temperatureText,
                conditionText: viewModel.conditionText
            )
            .padding(.horizontal, 22)
            .padding(.top, 0)
            .opacity(hasWeatherData ? 1 : 0)
            .accessibilityHidden(!hasWeatherData)
            .animation(availabilityAnimation, value: hasWeatherData)
        }
        .overlay(alignment: .bottom) {
            if showsLocationButton && hasWeatherData && !viewModel.isSearchPresented {
                locationButton
                    .padding(.horizontal, 22)
                    .padding(.bottom, 0)
                    .transition(.identity)
                    .animation(hasDisplayedWeather ? .easeOut(duration: 0.32).delay(0.08) : nil, value: hasWeatherData)
            }
        }
        .animation(availabilityAnimation, value: hasWeatherData)
        .onChange(of: hasWeatherData) { _, hasWeatherData in
            if hasWeatherData {
                hasDisplayedWeather = true
            }
        }
    }

    private var locationButton: some View {
        Button {
            AppHaptics.selection()
            viewModel.presentSearch()
        } label: {
            locationButtonLabel
        }
        /*
        .nativeLocationPillGlassButton()
        .nativeSearchPillGlassTransition(in: searchTransitionNamespace)
        */
        .buttonStyle(.plain)
        .accessibilityHint("Opens location search")
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var locationButtonLabel: some View {
        locationButtonContent
        /*
        ZStack {
            locationButtonContent
                .hidden()
                .locationPillGlass()
                .background {
                    Color.clear
                        .searchPillMatchedGeometry(in: searchTransitionNamespace)
                }

            locationButtonContent
        }
        */
    }

    private var locationButtonContent: some View {
        HStack(spacing: 8) {
            LocationPinIcon()
                .frame(width: 19, height: 19)

            Text(viewModel.currentCity.displayName)
                .lineLimit(1)
        }
        .font(.body)
        .foregroundStyle(WeatherPalette.ink)
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
    }
}

private struct WeatherStatusView: View {
    let state: WeatherViewModel.LoadState
    let isLoading: Bool

    private var title: String {
        switch state {
        case .idle, .loading:
            return "Loading weather"
        case .loaded:
            return ""
        case .staleLoaded(_, let message), .unavailable(let message):
            return message
        }
    }

    var body: some View {
        ZStack {
            Color.white

            VStack(spacing: 14) {
                if isLoading {
                    ProgressView()
                        .tint(WeatherPalette.ink)
                }

                if !isLoading, !title.isEmpty {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(WeatherPalette.ink)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct LocationPinIcon: View {
    var body: some View {
        ZStack {
            LocationPinShape()
                .stroke(style: StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))

            Circle()
                .stroke(lineWidth: 2.25)
                .frame(width: 5, height: 5)
                .offset(y: -3)
        }
    }
}

struct LocationPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height * 0.94))
        path.addCurve(
            to: CGPoint(x: width * 0.82, y: height * 0.27),
            control1: CGPoint(x: width * 0.82, y: height * 0.66),
            control2: CGPoint(x: width * 0.82, y: height * 0.43)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.18, y: height * 0.27),
            control1: CGPoint(x: width * 0.82, y: height * -0.06),
            control2: CGPoint(x: width * 0.18, y: height * -0.06)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.94),
            control1: CGPoint(x: width * 0.18, y: height * 0.43),
            control2: CGPoint(x: width * 0.18, y: height * 0.66)
        )

        return path
    }
}

#Preview("Rainy Square Asset") {
    WeatherSceneView(viewModel: .previewRain)
}

#Preview("Long City Large Text") {
    WeatherSceneView(viewModel: .previewLongCity)
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}
