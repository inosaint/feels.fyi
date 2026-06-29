import SwiftUI

struct ContentView: View {
    private static let searchKeyboardBarGap: CGFloat = 12
    private static let searchFieldHeight: CGFloat = 48
    private static let searchCloseButtonSize: CGFloat = 44

    @State private var viewModel: WeatherViewModel
    @State private var isSplashVisible = true
    @State private var isSplashResolving = false
    @State private var isSearchOverlayVisible = false
    @State private var searchOverlayDismissTask: Task<Void, Never>?
    @State private var locationPillSize: CGSize = .zero
    @Namespace private var searchTransitionNamespace

    private var searchPresentationAnimation: Animation {
        viewModel.isSearchPresented
            ? .spring(response: 0.34, dampingFraction: 0.9)
            : .timingCurve(0.32, 0, 0.67, 0, duration: 0.22)
    }

    init(viewModel: WeatherViewModel? = nil) {
        _viewModel = State(
            initialValue: viewModel ?? WeatherViewModel(
                locationProvider: LocationManager(),
                persistence: UserDefaultsWeatherStore.sharedSurfaceStore
            )
        )
    }

    var body: some View {
        layeredContent
            .animation(searchPresentationAnimation, value: viewModel.isSearchPresented)
            .onPreferenceChange(LocationPillSizePreferenceKey.self) { size in
                guard size != .zero else {
                    return
                }

                locationPillSize = size
            }
            .task {
                async let initialize: Void = viewModel.initialize()
                await resolveSplash()
                _ = await initialize
            }
            .onAppear {
                isSearchOverlayVisible = viewModel.isSearchPresented
            }
            .onChange(of: viewModel.isSearchPresented) { _, isPresented in
                searchOverlayDismissTask?.cancel()

                if isPresented {
                    withAnimation(searchPresentationAnimation) {
                        isSearchOverlayVisible = true
                    }
                } else {
                    searchOverlayDismissTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(340))
                        guard !Task.isCancelled else {
                            return
                        }

                        withAnimation(.easeOut(duration: 0.08)) {
                            isSearchOverlayVisible = false
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(viewModel.statusMessage)
    }

    private var layeredContent: some View {
        ZStack {
            WeatherSceneView(
                viewModel: viewModel,
                showsLocationButton: false
            )
                .opacity(isSplashVisible && !isSplashResolving ? 0 : 1)

            bottomGlassLayer
                .zIndex(0.5)

            locationButtonLayer
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(0.75)

            if isSearchOverlayVisible {
                SearchView(
                    viewModel: viewModel
                )
                    .transition(.opacity)
                    .allowsHitTesting(viewModel.isSearchPresented)
                    .zIndex(0.25)
            }

            if isSearchOverlayVisible {
                SearchBottomBarView(viewModel: viewModel)
                    .allowsHitTesting(viewModel.isSearchPresented)
                    .zIndex(0.75)
            }

            if isSplashVisible {
                SplashView(isResolving: isSplashResolving)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
    }

    @ViewBuilder
    private var bottomGlassLayer: some View {
        if viewModel.hasWeatherData {
            if viewModel.isSearchPresented {
                ZStack {
                    Color.clear
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    searchGlassBottomBar
                }
                .allowsHitTesting(false)
            } else {
                locationPillGlassSurface
                    .padding(.horizontal, 22)
                    .padding(.bottom, 0)
                    .nativeLiquidGlassContainer(spacing: 12)
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private var searchGlassBottomBar: some View {
        ZStack {
            searchGlassSurfaces
                .nativeLiquidGlassContainer(spacing: 12)

            searchGlassRims
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, Self.searchKeyboardBarGap)
    }

    private var searchGlassSurfaces: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(height: Self.searchFieldHeight)
                .frame(maxWidth: .infinity)
                .nativeSearchFieldGlass()
                .nativeSearchPillGlassTransition(in: searchTransitionNamespace)

            Color.clear
                .frame(width: Self.searchCloseButtonSize, height: Self.searchCloseButtonSize)
                .nativeCompactSearchActionGlass()
        }
    }

    private var searchGlassRims: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(height: Self.searchFieldHeight)
                .frame(maxWidth: .infinity)
                .nativeLiquidGlassRimBorder()

            Color.clear
                .frame(width: Self.searchCloseButtonSize, height: Self.searchCloseButtonSize)
                .nativeLiquidGlassRimBorder()
        }
    }

    private var locationPillGlassSurface: some View {
        Color.clear
            .frame(width: locationPillGlassWidth, height: locationPillGlassHeight)
            .nativeCompactLocationPillGlass()
            .nativeSearchPillGlassTransition(in: searchTransitionNamespace)
    }

    private var locationPillGlassWidth: CGFloat {
        max(locationPillSize.width, 1)
    }

    private var locationPillGlassHeight: CGFloat {
        max(locationPillSize.height, 48)
    }

    @ViewBuilder
    private var locationButtonLayer: some View {
        if viewModel.hasWeatherData && !viewModel.isSearchPresented {
            Button {
                AppHaptics.selection()
                viewModel.presentSearch()
            } label: {
                locationPillContent
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: LocationPillSizePreferenceKey.self,
                                value: proxy.size
                            )
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens location search")
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 22)
            .padding(.bottom, 0)
            .transition(.identity)
        }
    }

    private var locationPillContent: some View {
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

private struct LocationPillSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let nextSize = nextValue()
        if nextSize != .zero {
            value = nextSize
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
