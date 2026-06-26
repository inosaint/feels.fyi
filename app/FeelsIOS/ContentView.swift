import SwiftUI

struct ContentView: View {
    @State private var viewModel: WeatherViewModel
    @State private var isSplashVisible = true
    @State private var isSplashResolving = false

    init(viewModel: WeatherViewModel? = nil) {
        _viewModel = State(
            initialValue: viewModel ?? WeatherViewModel(
                locationProvider: LocationManager(),
                persistence: UserDefaultsWeatherStore.sharedSurfaceStore
            )
        )
    }

    var body: some View {
        ZStack {
            WeatherSceneView(viewModel: viewModel)
                .opacity(isSplashVisible && !isSplashResolving ? 0 : 1)

            if viewModel.isSearchPresented {
                SearchView(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(1)
            }

            if isSplashVisible {
                SplashView(isResolving: isSplashResolving)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeOut(duration: 0.22), value: viewModel.isSearchPresented)
        .task {
            async let initialize: Void = viewModel.initialize()
            await resolveSplash()
            _ = await initialize
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(viewModel.statusMessage)
    }

    private func resolveSplash() async {
        try? await Task.sleep(for: .milliseconds(780))
        withAnimation(.easeOut(duration: 0.28)) {
            isSplashResolving = true
        }
        try? await Task.sleep(for: .milliseconds(240))
        withAnimation(.easeOut(duration: 0.28)) {
            isSplashVisible = false
        }
    }
}

private struct SplashView: View {
    let isResolving: Bool

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image("hot35")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .saturation(isResolving ? 1.2 : 1)
                    .brightness(isResolving ? 0.08 : 0)
                    .scaleEffect(isResolving ? 0.92 : 1)

                Text("feels.fyi")
                    .font(.system(size: 24, weight: .regular, design: .serif).italic())
                    .foregroundStyle(WeatherPalette.ink)
            }
            .opacity(isResolving ? 0 : 1)
            .scaleEffect(isResolving ? 0.96 : 1)
        }
        .accessibilityLabel("feels.fyi")
    }
}

#Preview("Loaded") {
    ContentView(viewModel: .previewLoaded)
}

#Preview("Loading") {
    ContentView(viewModel: .previewLoading)
}

#Preview("Unavailable") {
    ContentView(viewModel: .previewUnavailable)
}
