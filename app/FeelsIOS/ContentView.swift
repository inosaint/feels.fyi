import SwiftUI
import UIKit

struct ContentView: View {
    private static let searchKeyboardBarGap: CGFloat = 12
    private static let searchBarHorizontalPadding: CGFloat = 16
    private static let searchBarTopPadding: CGFloat = 8
    private static let searchFieldHeight: CGFloat = 48
    private static let searchCloseButtonSize: CGFloat = 44

    @State private var viewModel: WeatherViewModel
    @State private var isSplashVisible = true
    @State private var isSplashResolving = false
    @State private var isSearchOverlayVisible = false
    @State private var isSearchFieldFocused = false
    @State private var keyboardTransition = KeyboardTransition()
    @State private var searchOverlayDismissTask: Task<Void, Never>?
    @State private var recentLocationsTask: Task<Void, Never>?
    @State private var recentLocationChipTask: Task<Void, Never>?
    @State private var isRecentLocationsRowVisible = false
    @State private var visibleRecentLocationIDs = Set<String>()
    @State private var recentLocationChipFrames: [String: CGRect] = [:]
    @State private var searchResultRowTask: Task<Void, Never>?
    @State private var visibleSearchResultIDs = Set<String>()
    @State private var searchResultRowFrames: [String: CGRect] = [:]
    @State private var searchResultViewportMaskFrame: SearchResultViewportMaskFrame?
    @State private var locationPillSize: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var searchTransitionNamespace

    private var searchPresentationAnimation: Animation {
        keyboardTransition.animation
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
        GeometryReader { proxy in
            layeredContent(bottomSafeAreaInset: proxy.safeAreaInsets.bottom)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
            .coordinateSpace(name: RecentLocationChipCoordinateSpace.name)
            .coordinateSpace(name: SearchResultRowCoordinateSpace.name)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .animation(searchPresentationAnimation, value: viewModel.isSearchPresented)
            .onPreferenceChange(LocationPillSizePreferenceKey.self) { size in
                guard size != .zero else {
                    return
                }

                locationPillSize = size
            }
            .onPreferenceChange(RecentLocationChipFramePreferenceKey.self) { frames in
                recentLocationChipFrames = frames
            }
            .onPreferenceChange(SearchResultRowFramePreferenceKey.self) { frames in
                searchResultRowFrames = frames
            }
            .onPreferenceChange(SearchResultViewportFramePreferenceKey.self) { maskFrame in
                searchResultViewportMaskFrame = maskFrame
            }
            .task {
                async let initialize: Void = viewModel.initialize()
                await resolveSplash()
                _ = await initialize
            }
            .onAppear {
                isSearchOverlayVisible = viewModel.isSearchPresented
                syncRecentLocationsRowVisibility()
                syncSearchResultRowVisibility()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                let nextTransition = KeyboardTransition(notification: notification)
                withAnimation(nextTransition.animation) {
                    keyboardTransition = nextTransition
                }
            }
            .onChange(of: viewModel.isSearchPresented) { _, isPresented in
                searchOverlayDismissTask?.cancel()

                if isPresented {
                    isSearchFieldFocused = true
                    withAnimation(searchPresentationAnimation) {
                        isSearchOverlayVisible = true
                    }
                    syncRecentLocationsRowVisibility()
                    syncSearchResultRowVisibility()
                } else {
                    hideRecentLocationsRow()
                    hideSearchResultRows()
                    isSearchFieldFocused = false
                    let removalDelay = keyboardTransition.overlayRemovalDelay
                    searchOverlayDismissTask = Task { @MainActor in
                        try? await Task.sleep(for: removalDelay)
                        guard !Task.isCancelled else {
                            return
                        }

                        withAnimation(.easeOut(duration: 0.08)) {
                            isSearchOverlayVisible = false
                        }
                    }
                }
            }
            .onChange(of: viewModel.searchQuery) { _, _ in
                syncRecentLocationsRowVisibility()
                syncSearchResultRowVisibility()
            }
            .onChange(of: viewModel.recentSearchedCities) { _, _ in
                syncRecentLocationsRowVisibility()
            }
            .onChange(of: viewModel.searchResults) { _, _ in
                syncSearchResultRowVisibility()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(viewModel.statusMessage)
    }

    private func layeredContent(bottomSafeAreaInset: CGFloat) -> some View {
        let keyboardOffset = searchKeyboardOffset(bottomSafeAreaInset: bottomSafeAreaInset)

        return ZStack {
            WeatherSceneView(
                viewModel: viewModel,
                showsLocationButton: false
            )
                .opacity(isSplashVisible && !isSplashResolving ? 0 : 1)

            bottomGlassLayer(keyboardOffset: keyboardOffset)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .zIndex(0.5)

            recentLocationChipGlassLayer
                .zIndex(0.55)

            searchResultRowGlassLayer
                .zIndex(0.45)

            locationButtonLayer
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .zIndex(0.75)

            if isSearchOverlayVisible {
                SearchView(
                    viewModel: viewModel,
                    bottomContentInset: searchContentBottomInset(keyboardOffset: keyboardOffset),
                    dismissSearchAction: dismissSearchAfterKeyboard
                )
                    .transition(.opacity)
                    .allowsHitTesting(viewModel.isSearchPresented)
                    .zIndex(0.25)
            }

            if isSearchOverlayVisible {
                SearchBottomBarView(
                    viewModel: viewModel,
                    shouldFocusSearchField: $isSearchFieldFocused,
                    keyboardOffset: keyboardOffset,
                    collapsedWidth: searchChromeCollapsedWidth,
                    isRecentLocationsRowVisible: isRecentLocationsRowVisible,
                    visibleRecentLocationIDs: visibleRecentLocationIDs,
                    visibleSearchResultIDs: visibleSearchResultIDs,
                    selectRecentCityAction: selectSearchCity,
                    selectSearchResultAction: selectSearchCity,
                    hideRecentLocationsAction: hideRecentLocationsRow,
                    hideSearchResultsAction: hideSearchResultRows,
                    dismissSearchAction: dismissSearchAfterKeyboard
                )
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
    private func bottomGlassLayer(keyboardOffset: CGFloat) -> some View {
        if viewModel.hasWeatherData {
            if isSearchOverlayVisible {
                searchGlassBottomBar
                    .frame(width: searchChromeWidth)
                    .padding(.bottom, keyboardOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
        VStack(alignment: .leading, spacing: 10) {
            if isRecentLocationsRowVisible {
                Color.clear
                    .frame(height: RecentLocationChipMotion.rowHeight)
                    .transition(.identity)
            }

            ZStack {
                searchGlassSurfaces
                    .nativeLiquidGlassContainer(spacing: 12)

                searchGlassRims
            }
        }
        .padding(.horizontal, Self.searchBarHorizontalPadding)
        .padding(.top, Self.searchBarTopPadding)
    }

    private var recentLocationChipGlassLayer: some View {
        RecentLocationChipMeasuredGlassLayer(
            cities: viewModel.recentSearchedCities,
            visibleCityIDs: visibleRecentLocationIDs,
            chipFrames: recentLocationChipFrames
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var searchResultRowGlassLayer: some View {
        SearchResultMeasuredGlassLayer(
            cities: viewModel.searchResults,
            visibleCityIDs: visibleSearchResultIDs,
            rowFrames: searchResultRowFrames,
            viewportMaskFrame: searchResultViewportMaskFrame
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var searchChromeWidth: CGFloat? {
        viewModel.isSearchPresented ? nil : searchChromeCollapsedWidth
    }

    private var searchChromeCollapsedWidth: CGFloat {
        locationPillGlassWidth + Self.searchBarHorizontalPadding * 2
    }

    private var searchGlassSurfaces: some View {
        Group {
            if viewModel.isSearchPresented {
                HStack(spacing: 12) {
                    searchFieldGlassSurface

                    Color.clear
                        .frame(width: Self.searchCloseButtonSize, height: Self.searchCloseButtonSize)
                        .nativeCompactSearchActionGlass()
                }
            } else {
                searchFieldGlassSurface
            }
        }
    }

    private var searchGlassRims: some View {
        ZStack(alignment: .trailing) {
            Group {
                if viewModel.isSearchPresented {
                    HStack(spacing: 12) {
                        searchFieldGlassRim

                        Color.clear
                            .frame(width: Self.searchCloseButtonSize, height: Self.searchCloseButtonSize)
                    }
                } else {
                    searchFieldGlassRim
                }
            }

            closeActionGlassRim
                .opacity(viewModel.isSearchPresented ? 1 : 0)
                .transaction { transaction in
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
        }
    }

    private var searchFieldGlassSurface: some View {
        Color.clear
            .frame(height: Self.searchFieldHeight)
            .frame(maxWidth: .infinity)
            .nativeSearchFieldGlass(fallbackSearchFillOpacity: searchFallbackFillOpacity)
            .nativeSearchPillGlassTransition(in: searchTransitionNamespace)
    }

    private var searchFallbackFillOpacity: Double {
        viewModel.isSearchPresented ? 1 : 0
    }

    private var searchFieldGlassRim: some View {
        Color.clear
            .frame(height: Self.searchFieldHeight)
            .frame(maxWidth: .infinity)
            .nativeLiquidGlassRimBorder()
    }

    private var closeActionGlassRim: some View {
        Color.clear
            .frame(width: Self.searchCloseButtonSize, height: Self.searchCloseButtonSize)
            .nativeLiquidGlassRimBorder()
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

    private func searchKeyboardOffset(bottomSafeAreaInset: CGFloat) -> CGFloat {
        guard keyboardTransition.keyboardHeight > 0 else {
            return 0
        }

        return max(0, keyboardTransition.keyboardHeight - bottomSafeAreaInset) + Self.searchKeyboardBarGap
    }

    private func searchContentBottomInset(keyboardOffset: CGFloat) -> CGFloat {
        guard keyboardOffset > 0 else {
            return 0
        }

        return keyboardOffset + Self.searchBarTopPadding + Self.searchFieldHeight
    }

    @ViewBuilder
    private var locationButtonLayer: some View {
        if viewModel.hasWeatherData {
            Button {
                AppHaptics.selection()
                presentSearchFromLocation()
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
            .opacity(viewModel.isSearchPresented ? 0 : 1)
            .allowsHitTesting(!viewModel.isSearchPresented)
            .accessibilityHidden(viewModel.isSearchPresented)
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

    private func dismissSearchAfterKeyboard() {
        commitSearchDismissalWithKeyboard {
            viewModel.dismissSearch()
        }
    }

    private func selectSearchCity(_ city: City) {
        hideRecentLocationsRow()
        hideSearchResultRows()
        commitSearchDismissalWithKeyboard {
            viewModel.selectCity(city)
        }
    }

    private func presentSearchFromLocation() {
        searchOverlayDismissTask?.cancel()
        isSearchFieldFocused = true

        withAnimation(searchPresentationAnimation) {
            isSearchOverlayVisible = true
            viewModel.presentSearch()
        }
    }

    private func commitSearchDismissalWithKeyboard(_ commit: @escaping @MainActor () -> Void) {
        isSearchFieldFocused = false

        let animation = searchPresentationAnimation
        withAnimation(animation) {
            keyboardTransition.keyboardHeight = 0
            commit()
        }
    }

    private var trimmedSearchQuery: String {
        viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldShowRecentLocations: Bool {
        viewModel.isSearchPresented
            && trimmedSearchQuery.isEmpty
            && !viewModel.recentSearchedCities.isEmpty
    }

    private var shouldShowSearchResults: Bool {
        viewModel.isSearchPresented
            && trimmedSearchQuery.count >= 2
            && !viewModel.searchResults.isEmpty
    }

    private var currentSearchResultIDs: [String] {
        viewModel.searchResults.map(\.id)
    }

    private func syncRecentLocationsRowVisibility() {
        if shouldShowRecentLocations {
            scheduleRecentLocationsRow()
        } else {
            hideRecentLocationsRow()
        }
    }

    private func scheduleRecentLocationsRow() {
        if isRecentLocationsRowVisible {
            revealRecentLocationChips()
            return
        }

        recentLocationsTask?.cancel()
        recentLocationsTask = Task { @MainActor in
            try? await Task.sleep(for: RecentLocationChipMotion.rowDelay)
            guard !Task.isCancelled, shouldShowRecentLocations else {
                return
            }

            isRecentLocationsRowVisible = true
            revealRecentLocationChips()
        }
    }

    private func revealRecentLocationChips() {
        recentLocationChipTask?.cancel()
        recentLocationChipTask = Task { @MainActor in
            visibleRecentLocationIDs = []

            guard !viewModel.recentSearchedCities.isEmpty else {
                return
            }

            if reduceMotion {
                visibleRecentLocationIDs = Set(viewModel.recentSearchedCities.map(\.id))
                return
            }

            try? await Task.sleep(for: RecentLocationChipMotion.firstChipDelay)
            for city in viewModel.recentSearchedCities {
                guard !Task.isCancelled, shouldShowRecentLocations else {
                    return
                }

                visibleRecentLocationIDs.insert(city.id)
                try? await Task.sleep(for: RecentLocationChipMotion.chipInterval)
            }
        }
    }

    private func hideRecentLocationsRow() {
        recentLocationsTask?.cancel()
        recentLocationChipTask?.cancel()
        recentLocationsTask = nil
        recentLocationChipTask = nil

        guard isRecentLocationsRowVisible || !visibleRecentLocationIDs.isEmpty else {
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isRecentLocationsRowVisible = false
            visibleRecentLocationIDs = []
            recentLocationChipFrames = [:]
        }
    }

    private func syncSearchResultRowVisibility() {
        if shouldShowSearchResults {
            revealSearchResultRows()
        } else {
            hideSearchResultRows()
        }
    }

    private func revealSearchResultRows() {
        let cities = viewModel.searchResults
        let cityIDs = cities.map(\.id)
        let targetVisibleIDs = Set(cityIDs)

        guard !cities.isEmpty else {
            hideSearchResultRows()
            return
        }

        if visibleSearchResultIDs == targetVisibleIDs && searchResultRowTask == nil {
            return
        }

        searchResultRowTask?.cancel()
        searchResultRowTask = Task { @MainActor in
            visibleSearchResultIDs = []

            guard shouldShowSearchResults, currentSearchResultIDs == cityIDs else {
                return
            }

            if reduceMotion {
                visibleSearchResultIDs = targetVisibleIDs
                searchResultRowTask = nil
                return
            }

            try? await Task.sleep(for: SearchResultRowMotion.firstRowDelay)
            for city in cities {
                guard !Task.isCancelled,
                      shouldShowSearchResults,
                      currentSearchResultIDs == cityIDs else {
                    return
                }

                visibleSearchResultIDs.insert(city.id)
                try? await Task.sleep(for: SearchResultRowMotion.rowInterval)
            }

            searchResultRowTask = nil
        }
    }

    private func hideSearchResultRows() {
        searchResultRowTask?.cancel()
        searchResultRowTask = nil

        guard !visibleSearchResultIDs.isEmpty || !searchResultRowFrames.isEmpty || searchResultViewportMaskFrame != nil else {
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            visibleSearchResultIDs = []
            searchResultRowFrames = [:]
            searchResultViewportMaskFrame = nil
        }
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

private struct KeyboardTransition {
    private static let searchChromeLead: TimeInterval = 0.06

    var duration: TimeInterval = 0.28
    var keyboardHeight: CGFloat = 0
    var animation: Animation = .easeOut(duration: 0.22)

    init() {}

    init(notification: Notification) {
        let rawDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        let duration = max(rawDuration ?? 0.28, 0.16)
        let rawCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
        let curve = rawCurve.flatMap(UIView.AnimationCurve.init(rawValue:)) ?? .easeOut
        let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        let screenHeight = UIScreen.main.bounds.height
        let keyboardHeight = endFrame.map { max(0, screenHeight - $0.minY) } ?? 0

        self.duration = duration
        self.keyboardHeight = keyboardHeight
        self.animation = Self.animation(duration: max(duration - Self.searchChromeLead, 0.01), curve: curve)
    }

    var overlayRemovalDelay: Duration {
        let milliseconds = Int64((duration * 1000).rounded()) + 80
        return .milliseconds(milliseconds)
    }

    private static func animation(duration: TimeInterval, curve: UIView.AnimationCurve) -> Animation {
        switch curve {
        case .easeInOut:
            return .easeInOut(duration: duration)
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .linear:
            return .linear(duration: duration)
        @unknown default:
            return .easeOut(duration: duration)
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

#Preview("Search Results") {
    ContentView(viewModel: .previewSearchResults)
}
