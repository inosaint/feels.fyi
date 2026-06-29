import SwiftUI

struct SearchView: View {
    let viewModel: WeatherViewModel
    let bottomContentInset: CGFloat
    let dismissSearchAction: () -> Void
    @FocusState private var isSearchFocused: Bool
    @State private var retainedBottomContentInset: CGFloat = 0

    private static let keyboardBarGap: CGFloat = 12
    private static let searchFieldHeight: CGFloat = 48

    var body: some View {
        ZStack {
            ZStack {
                SearchBackdropView()

                SearchContentView(
                    viewModel: viewModel,
                    bottomContentInset: resolvedBottomContentInset
                )
            }
            .opacity(searchOverlayOpacity)
            .blur(radius: searchOverlayBlurRadius)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(searchOverlayAnimation, value: viewModel.isSearchPresented)
        /*
        .safeAreaInset(edge: .bottom, spacing: 0) {
            searchBottomBar
        }
        */
        .environment(\.locale, Locale(identifier: "en_US"))
        .onAppear {
            retainBottomContentInsetIfNeeded(bottomContentInset)
        }
        .onChange(of: bottomContentInset) { _, inset in
            retainBottomContentInsetIfNeeded(inset)
        }
    }

    private var searchBottomBar: some View {
        searchBottomBarContent
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, Self.keyboardBarGap)
    }

    private var searchBottomBarContent: some View {
        HStack(spacing: 12) {
            searchField

            closeButtonSlot
        }
        .animation(searchFieldContentAnimation, value: viewModel.isSearchPresented)
    }

    private var searchField: some View {
        ZStack {
            searchFieldSurface
            searchFieldControls
        }
    }

    @ViewBuilder
    private var searchFieldSurface: some View {
        if viewModel.isSearchPresented {
            Color.clear
                .frame(height: Self.searchFieldHeight)
                .frame(maxWidth: .infinity)
                /*
                .searchFieldGlass()
                .searchPillMatchedGeometry(
                    in: searchTransitionNamespace,
                    isSource: viewModel.isSearchPresented
                )
                .nativeSearchFieldGlass()
                .nativeSearchPillGlassTransition(in: searchTransitionNamespace)
                */
                .transition(.identity)
        } else {
            Color.clear
                .frame(height: Self.searchFieldHeight)
                .frame(maxWidth: .infinity)
        }
    }

    private var searchFieldControls: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(WeatherPalette.ink.opacity(0.92))

            searchTextEntry

            if !viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    triggerActionHaptic()
                    viewModel.updateSearchQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                }
                .buttonStyle(.plain)
                .foregroundStyle(WeatherPalette.ink.opacity(0.82))
                .accessibilityLabel("Clear search")
            }
        }
        .opacity(searchFieldContentOpacity)
        .font(.system(size: 19, weight: .regular))
        .padding(.leading, 12)
        .padding(.trailing, 10)
    }

    private var searchTextEntry: some View {
        ZStack(alignment: .leading) {
            TextField(
                "",
                text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.updateSearchQuery($0) }
                )
            )
            .focused($isSearchFocused)
            .textFieldStyle(.plain)
            .foregroundStyle(.clear)
            .tint(WeatherPalette.ink)
            .submitLabel(.search)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.words)
            .textContentType(.none)
            .accessibilityLabel("Search location")
            .onSubmit {
                triggerActionHaptic()
                viewModel.submitSearch()
            }

            Text(visibleSearchText)
                .foregroundStyle(visibleSearchTextColor)
                .lineLimit(1)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var visibleSearchText: String {
        viewModel.searchQuery.isEmpty ? "Search location" : viewModel.searchQuery
    }

    private var visibleSearchTextColor: Color {
        viewModel.searchQuery.isEmpty ? WeatherPalette.ink.opacity(0.7) : WeatherPalette.ink
    }

    private var closeButtonSlot: some View {
        ZStack {
            closeButton
                .opacity(closeButtonOpacity)
                .scaleEffect(viewModel.isSearchPresented ? 1 : 0.82)
                .allowsHitTesting(viewModel.isSearchPresented)
        }
        .frame(width: 44, height: 44)
    }

    private var closeButton: some View {
        Button {
            dismissSearch()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .regular))
                .frame(width: 44, height: 44)
        }
        /*
        .buttonStyle(.plain)
        .searchActionGlass()
        */
        .buttonStyle(.plain)
        .foregroundStyle(WeatherPalette.ink)
        /*
        .nativeSearchActionGlassButton()
        .nativeCompactSearchActionGlass()
        */
        .accessibilityLabel("Close search")
    }

    private var searchOverlayOpacity: Double {
        viewModel.isSearchPresented ? 1 : 0
    }

    private var searchOverlayBlurRadius: CGFloat {
        viewModel.isSearchPresented ? 0 : 10
    }

    private var resolvedBottomContentInset: CGFloat {
        viewModel.isSearchPresented ? bottomContentInset : retainedBottomContentInset
    }

    private var searchFieldContentOpacity: Double {
        viewModel.isSearchPresented ? 1 : 0
    }

    private var closeButtonOpacity: Double {
        viewModel.isSearchPresented ? 1 : 0
    }

    private var searchOverlayAnimation: Animation {
        viewModel.isSearchPresented
            ? .easeOut(duration: 0.22)
            : .timingCurve(0.32, 0, 0.67, 0, duration: 0.18)
    }

    private var searchFieldContentAnimation: Animation {
        viewModel.isSearchPresented
            ? .easeOut(duration: 0.12)
            : .timingCurve(0.32, 0, 0.67, 0, duration: 0.06)
    }

    private func dismissSearch() {
        triggerActionHaptic()
        dismissSearchAction()
    }

    private func retainBottomContentInsetIfNeeded(_ inset: CGFloat) {
        guard viewModel.isSearchPresented && inset > 0 else {
            return
        }

        retainedBottomContentInset = inset
    }

    private func triggerActionHaptic() {
        AppHaptics.selection()
    }
}

struct SearchBottomBarView: View {
    let viewModel: WeatherViewModel
    @Binding var shouldFocusSearchField: Bool
    let keyboardOffset: CGFloat
    let collapsedWidth: CGFloat
    let isRecentLocationsRowVisible: Bool
    let visibleRecentLocationIDs: Set<String>
    let visibleSearchResultIDs: Set<String>
    let selectRecentCityAction: (City) -> Void
    let selectSearchResultAction: (City) -> Void
    let hideRecentLocationsAction: () -> Void
    let hideSearchResultsAction: () -> Void
    let dismissSearchAction: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    @State private var focusTask: Task<Void, Never>?

    private static let horizontalPadding: CGFloat = 16
    private static let topPadding: CGFloat = 8
    private static let searchFieldHeight: CGFloat = 48
    private static let supplementalRowSpacing: CGFloat = 10
    private static let statusBarClearance: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            searchBottomBar(
                searchResultMaxHeight: searchResultMaxHeight(
                    availableHeight: proxy.size.height,
                    topSafeAreaInset: proxy.safeAreaInsets.top
                )
            )
                .frame(width: searchChromeWidth)
                .padding(.bottom, keyboardOffset)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .animation(searchFieldContentAnimation, value: viewModel.isSearchPresented)
        .onAppear {
            scheduleSearchFocus()
        }
        .onChange(of: shouldFocusSearchField) { _, isFocused in
            guard isTextFieldFocused != isFocused else {
                return
            }

            isTextFieldFocused = isFocused
        }
        .onChange(of: isTextFieldFocused) { _, isFocused in
            guard shouldFocusSearchField != isFocused else {
                return
            }

            shouldFocusSearchField = isFocused
        }
        .onDisappear {
            focusTask?.cancel()
            focusTask = nil
            isTextFieldFocused = false
            shouldFocusSearchField = false
        }
    }

    private func searchBottomBar(searchResultMaxHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if isRecentLocationsRowVisible {
                RecentLocationChipRow(
                    cities: viewModel.recentSearchedCities,
                    visibleCityIDs: visibleRecentLocationIDs,
                    selectCity: selectRecentCity(_:)
                )
                .transition(.identity)
            }

            if shouldShowSearchResults, searchResultMaxHeight > 0 {
                SearchResultStack(
                    cities: viewModel.searchResults,
                    visibleCityIDs: visibleSearchResultIDs,
                    maxHeight: searchResultMaxHeight,
                    selectCity: selectSearchResult(_:)
                )
                .transition(.identity)
            }

            HStack(spacing: 12) {
                searchFieldControls
                    .frame(height: Self.searchFieldHeight)
                    .frame(maxWidth: .infinity)

                closeButtonSlot
            }
        }
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.top, Self.topPadding)
        .animation(searchFieldContentAnimation, value: viewModel.isSearchPresented)
    }

    private var shouldShowSearchResults: Bool {
        viewModel.isSearchPresented
            && viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
            && !viewModel.searchResults.isEmpty
    }

    private func searchResultMaxHeight(
        availableHeight: CGFloat,
        topSafeAreaInset: CGFloat
    ) -> CGFloat {
        guard shouldShowSearchResults else {
            return 0
        }

        let reservedHeight = keyboardOffset
            + Self.topPadding
            + Self.searchFieldHeight
            + Self.supplementalRowSpacing
            + topSafeAreaInset
            + Self.statusBarClearance
        let availableResultHeight = max(0, availableHeight - reservedHeight)
        let contentHeight = SearchResultRowMotion.stackHeight(for: viewModel.searchResults.count)

        return min(contentHeight, availableResultHeight)
    }

    private var searchFieldControls: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(WeatherPalette.ink.opacity(0.92))

            searchTextEntry

            if !viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    triggerActionHaptic()
                    viewModel.updateSearchQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                }
                .buttonStyle(.plain)
                .foregroundStyle(WeatherPalette.ink.opacity(0.82))
                .accessibilityLabel("Clear search")
            }
        }
        .opacity(searchFieldContentOpacity)
        .font(.system(size: 19, weight: .regular))
        .padding(.leading, 12)
        .padding(.trailing, 10)
    }

    private var searchTextEntry: some View {
        ZStack(alignment: .leading) {
            TextField(
                "",
                text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.updateSearchQuery($0) }
                )
            )
            .focused($isTextFieldFocused)
            .textFieldStyle(.plain)
            .foregroundStyle(.clear)
            .tint(WeatherPalette.ink)
            .submitLabel(.search)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.words)
            .textContentType(.none)
            .accessibilityLabel("Search location")
            .onSubmit {
                triggerActionHaptic()
                viewModel.submitSearch()
            }

            Text(visibleSearchText)
                .foregroundStyle(visibleSearchTextColor)
                .lineLimit(1)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var visibleSearchText: String {
        viewModel.searchQuery.isEmpty ? "Search location" : viewModel.searchQuery
    }

    private var visibleSearchTextColor: Color {
        viewModel.searchQuery.isEmpty ? WeatherPalette.ink.opacity(0.7) : WeatherPalette.ink
    }

    private var closeButtonSlot: some View {
        ZStack {
            closeButton
                .opacity(closeButtonOpacity)
                .scaleEffect(viewModel.isSearchPresented ? 1 : 0.82)
                .allowsHitTesting(viewModel.isSearchPresented)
        }
        .frame(width: 44, height: 44)
    }

    private var closeButton: some View {
        Button {
            dismissSearch()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .regular))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(WeatherPalette.ink)
        .accessibilityLabel("Close search")
    }

    private var searchFieldContentOpacity: Double {
        viewModel.isSearchPresented ? 1 : 0
    }

    private var closeButtonOpacity: Double {
        viewModel.isSearchPresented ? 1 : 0
    }

    private var searchChromeWidth: CGFloat? {
        viewModel.isSearchPresented ? nil : collapsedWidth
    }

    private var searchFieldContentAnimation: Animation {
        viewModel.isSearchPresented
            ? .easeOut(duration: 0.12)
            : .timingCurve(0.32, 0, 0.67, 0, duration: 0.06)
    }

    private func scheduleSearchFocus() {
        focusTask?.cancel()
        focusTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else {
                return
            }

            shouldFocusSearchField = true
            isTextFieldFocused = true
        }
    }

    private func selectRecentCity(_ city: City) {
        hideRecentLocationsAction()
        hideSearchResultsAction()
        shouldFocusSearchField = false
        isTextFieldFocused = false
        selectRecentCityAction(city)
    }

    private func selectSearchResult(_ city: City) {
        hideRecentLocationsAction()
        hideSearchResultsAction()
        shouldFocusSearchField = false
        isTextFieldFocused = false
        selectSearchResultAction(city)
    }

    private func dismissSearch() {
        triggerActionHaptic()
        hideRecentLocationsAction()
        hideSearchResultsAction()
        shouldFocusSearchField = false
        isTextFieldFocused = false
        dismissSearchAction()
    }

    private func triggerActionHaptic() {
        AppHaptics.selection()
    }
}

private struct SearchPopButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCompressed = false
    @State private var showsRipple = false
    @State private var rippleExpanded = false
    @State private var popTask: Task<Void, Never>?

    var body: some View {
        Button {
            triggerPop()
        } label: {
            label()
                .scaleEffect(isCompressed ? 0.965 : 1)
                .overlay {
                    if showsRipple {
                        Capsule()
                            .stroke(WeatherPalette.ink.opacity(0.28), lineWidth: 1.4)
                            .scaleEffect(rippleExpanded ? 1.14 : 0.88)
                            .opacity(rippleExpanded ? 0 : 1)
                    }
                }
                .animation(SearchSelectionPopMotion.compressionAnimation(reduceMotion: reduceMotion), value: isCompressed)
                .animation(SearchSelectionPopMotion.rippleAnimation(reduceMotion: reduceMotion), value: rippleExpanded)
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .onDisappear {
            popTask?.cancel()
            popTask = nil
        }
    }

    private func triggerPop() {
        AppHaptics.selection()

        guard !reduceMotion else {
            action()
            return
        }

        popTask?.cancel()
        isCompressed = true
        showsRipple = true
        rippleExpanded = false

        popTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else {
                return
            }

            rippleExpanded = true

            try? await Task.sleep(for: SearchSelectionPopMotion.compressionDuration)
            guard !Task.isCancelled else {
                return
            }

            isCompressed = false

            try? await Task.sleep(for: SearchSelectionPopMotion.selectionDelay)
            guard !Task.isCancelled else {
                return
            }

            action()

            try? await Task.sleep(for: SearchSelectionPopMotion.cleanupDelay)
            guard !Task.isCancelled else {
                return
            }

            showsRipple = false
            rippleExpanded = false
            popTask = nil
        }
    }
}

private enum SearchSelectionPopMotion {
    static let compressionDuration: Duration = .milliseconds(70)
    static let selectionDelay: Duration = .milliseconds(55)
    static let cleanupDelay: Duration = .milliseconds(80)

    static func compressionAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.12)
    }

    static func rippleAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.22)
    }
}

private struct SearchResultStack: View {
    let cities: [City]
    let visibleCityIDs: Set<String>
    let maxHeight: CGFloat
    let selectCity: (City) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var displayedCities: [(index: Int, city: City)] {
        Array(cities.enumerated()).reversed().map { (index: $0.offset, city: $0.element) }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: SearchResultRowMotion.rowSpacing) {
                ForEach(displayedCities, id: \.city.id) { result in
                    let isVisible = visibleCityIDs.contains(result.city.id)

                    SearchResultRow(
                        city: result.city,
                        isVisible: isVisible,
                        resultIndex: result.index,
                        resultCount: cities.count,
                        selectCity: selectCity
                    )
                    .id(result.city.id)
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: SearchResultRowFramePreferenceKey.self,
                                value: [
                                    result.city.id: proxy.frame(in: .named(SearchResultRowCoordinateSpace.name))
                                ]
                            )
                        }
                    }
                    .scaleEffect(SearchResultRowMotion.scale(isVisible: isVisible, reduceMotion: reduceMotion), anchor: .bottom)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: SearchResultRowMotion.offset(isVisible: isVisible, reduceMotion: reduceMotion))
                    .allowsHitTesting(isVisible)
                    .animation(SearchResultRowMotion.animation(for: result.index, reduceMotion: reduceMotion), value: isVisible)
                }
            }
            .padding(.vertical, SearchResultRowMotion.viewportPadding)
            .frame(maxWidth: .infinity, minHeight: maxHeight, alignment: .bottom)
        }
        .frame(height: maxHeight)
        .background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named(SearchResultRowCoordinateSpace.name))
                let bleed = SearchResultRowMotion.viewportClipBleed

                Color.clear.preference(
                    key: SearchResultViewportFramePreferenceKey.self,
                    value: CGRect(
                        x: frame.minX,
                        y: max(0, frame.minY - bleed),
                        width: frame.width,
                        height: frame.height + bleed * 2
                    )
                )
            }
        }
        .defaultScrollAnchor(.bottom)
    }
}

private struct SearchResultRow: View {
    let city: City
    let isVisible: Bool
    let resultIndex: Int
    let resultCount: Int
    let selectCity: (City) -> Void

    var body: some View {
        SearchPopButton {
            selectCity(city)
        } label: {
            SearchResultRowContent(city: city)
        }
        .accessibilityLabel(city.displayName)
        .accessibilityHidden(!isVisible)
        .accessibilitySortPriority(Double(resultCount - resultIndex))
    }
}

struct SearchResultMeasuredGlassLayer: View {
    let cities: [City]
    let visibleCityIDs: Set<String>
    let rowFrames: [String: CGRect]
    let viewportFrame: CGRect?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                    let isVisible = visibleCityIDs.contains(city.id)

                    if let frame = rowFrames[city.id] {
                        SearchResultRowGlassSurface()
                            .frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY)
                            .scaleEffect(SearchResultRowMotion.scale(isVisible: isVisible, reduceMotion: reduceMotion), anchor: .bottom)
                            .opacity(isVisible ? 1 : 0)
                            .offset(y: SearchResultRowMotion.offset(isVisible: isVisible, reduceMotion: reduceMotion))
                            .animation(SearchResultRowMotion.animation(for: index, reduceMotion: reduceMotion), value: isVisible)
                    }
                }
            }
            .nativeLiquidGlassContainer(spacing: SearchResultRowMotion.rowSpacing)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .mask(alignment: .topLeading) {
                if let viewportFrame {
                    Rectangle()
                        .frame(width: viewportFrame.width, height: viewportFrame.height)
                        .position(x: viewportFrame.midX, y: viewportFrame.midY)
                }
            }
        }
    }
}

private struct SearchResultRowGlassSurface: View {
    var body: some View {
        Color.clear
            .nativeSearchResultRowGlass()
            .accessibilityHidden(true)
    }
}

enum SearchResultRowMotion {
    static let firstRowDelay: Duration = .milliseconds(85)
    static let rowInterval: Duration = .milliseconds(70)
    static let rowHeight: CGFloat = 58
    static let rowSpacing: CGFloat = 8
    static let viewportPadding: CGFloat = 14
    static let viewportClipBleed: CGFloat = 18
    private static let hiddenYOffset: CGFloat = 10

    static func stackHeight(for rowCount: Int) -> CGFloat {
        guard rowCount > 0 else {
            return 0
        }

        return CGFloat(rowCount) * rowHeight
            + CGFloat(rowCount - 1) * rowSpacing
            + viewportPadding * 2
    }

    static func scale(isVisible: Bool, reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 1 : (isVisible ? 1 : 0.86)
    }

    static func offset(isVisible: Bool, reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 0 : (isVisible ? 0 : hiddenYOffset)
    }

    static func animation(for index: Int, reduceMotion: Bool) -> Animation? {
        if reduceMotion {
            return .easeOut(duration: 0.16)
        }

        return .timingCurve(0.16, 1, 0.3, 1, duration: 0.42)
            .delay(Double(index) * 0.018)
    }
}

enum SearchResultRowCoordinateSpace {
    static let name = "search-result-row-space"
}

struct SearchResultRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct SearchResultViewportFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

private struct SearchResultRowContent: View {
    let city: City

    var body: some View {
        HStack(spacing: 11) {
            if let flag = city.countryFlagEmoji {
                Text(flag)
                    .font(.system(size: 22))
                    .frame(width: 26, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(city.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WeatherPalette.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !city.country.isEmpty {
                    Text(city.country)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(WeatherPalette.ink.opacity(0.72))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: SearchResultRowMotion.rowHeight, alignment: .leading)
        .contentShape(Capsule())
    }
}

private struct RecentLocationChipRow: View {
    let cities: [City]
    let visibleCityIDs: Set<String>
    let selectCity: (City) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                    let isVisible = visibleCityIDs.contains(city.id)

                    RecentLocationChip(
                        city: city,
                        isVisible: isVisible,
                        selectCity: selectCity
                    )
                    .id(city.id)
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: RecentLocationChipFramePreferenceKey.self,
                                value: [
                                    city.id: proxy.frame(in: .named(RecentLocationChipCoordinateSpace.name))
                                ]
                            )
                        }
                    }
                    .scaleEffect(RecentLocationChipMotion.scale(isVisible: isVisible, reduceMotion: reduceMotion), anchor: .center)
                    .opacity(isVisible ? 1 : 0)
                    .allowsHitTesting(isVisible)
                    .animation(RecentLocationChipMotion.animation(for: index, reduceMotion: reduceMotion), value: isVisible)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }
}

private struct RecentLocationChip: View {
    let city: City
    let isVisible: Bool
    let selectCity: (City) -> Void

    var body: some View {
        SearchPopButton {
            selectCity(city)
        } label: {
            RecentLocationChipContent(city: city)
        }
        .accessibilityLabel("Search \(city.displayName) again")
        .accessibilityHidden(!isVisible)
    }
}

struct RecentLocationChipMeasuredGlassLayer: View {
    let cities: [City]
    let visibleCityIDs: Set<String>
    let chipFrames: [String: CGRect]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                    let isVisible = visibleCityIDs.contains(city.id)

                    if let frame = chipFrames[city.id] {
                        RecentLocationChipGlassSurface()
                            .frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY)
                            .scaleEffect(RecentLocationChipMotion.scale(isVisible: isVisible, reduceMotion: reduceMotion), anchor: .center)
                            .opacity(isVisible ? 1 : 0)
                            .animation(RecentLocationChipMotion.animation(for: index, reduceMotion: reduceMotion), value: isVisible)
                    }
                }
            }
            .nativeLiquidGlassContainer(spacing: 8)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

private struct RecentLocationChipGlassSurface: View {
    var body: some View {
        Color.clear
            .nativeCompactLocationPillGlass()
            .accessibilityHidden(true)
    }
}

enum RecentLocationChipMotion {
    static let rowDelay: Duration = .milliseconds(380)
    static let firstChipDelay: Duration = .milliseconds(85)
    static let chipInterval: Duration = .milliseconds(115)
    static let rowHeight: CGFloat = 42

    static func scale(isVisible: Bool, reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 1 : (isVisible ? 1 : 0.82)
    }

    static func animation(for index: Int, reduceMotion: Bool) -> Animation? {
        if reduceMotion {
            return .easeOut(duration: 0.18)
        }

        return .timingCurve(0.16, 1, 0.3, 1, duration: 0.52)
            .delay(Double(index) * 0.025)
    }
}

enum RecentLocationChipCoordinateSpace {
    static let name = "recent-location-chip-space"
}

struct RecentLocationChipFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct RecentLocationChipContent: View {
    let city: City

    var body: some View {
        HStack(spacing: 6) {
            if let flag = city.countryFlagEmoji {
                Text(flag)
            }

            Text(city.name)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 150, alignment: .leading)
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(WeatherPalette.ink)
        .padding(.horizontal, 12)
        .frame(minHeight: 38)
    }
}

private extension City {
    var countryFlagEmoji: String? {
        guard let countryCode = countryCode?.uppercased(), countryCode.count == 2 else {
            return nil
        }

        var flag = ""
        for scalar in countryCode.unicodeScalars {
            guard scalar.value >= 65, scalar.value <= 90,
                  let flagScalar = UnicodeScalar(127397 + scalar.value) else {
                return nil
            }

            flag.append(String(flagScalar))
        }

        return flag
    }
}

private struct SearchOverlayRadialMask: View {
    let isPresented: Bool

    var body: some View {
        GeometryReader { proxy in
            let diameter = max(proxy.size.width, proxy.size.height) * 2.5

            Circle()
                .fill(.white)
                .frame(width: diameter, height: diameter)
                .scaleEffect(isPresented ? 1 : 0.04)
                .blur(radius: isPresented ? 0 : 26)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .ignoresSafeArea()
    }
}

private struct SearchBackdropView: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.white.opacity(0.08))
            .ignoresSafeArea()
    }
}

private struct SearchContentView: View {
    let viewModel: WeatherViewModel
    let bottomContentInset: CGFloat

    private var trimmedQuery: String {
        viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isShowingEmptyState: Bool {
        trimmedQuery.count < 2 || viewModel.searchResults.isEmpty
    }

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = isShowingEmptyState ? 28 : 0
            let contentWidth = max(0, proxy.size.width - horizontalPadding * 2)
            let contentHeight = max(0, proxy.size.height - bottomContentInset)

            searchContent
                .frame(
                    width: contentWidth,
                    height: contentHeight,
                    alignment: isShowingEmptyState ? .center : .top
                )
                .padding(.horizontal, horizontalPadding)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }

    private var searchContent: some View {
        ZStack {
            if trimmedQuery.count < 2 {
                SearchEmptyState(
                    title: "Search for a place",
                    systemImage: "magnifyingglass",
                    description: "Start typing a city or region."
                )
            } else if viewModel.searchResults.isEmpty {
                SearchEmptyState(
                    title: viewModel.isSearching ? "Searching" : "No Results for \"\(trimmedQuery)\"",
                    systemImage: "magnifyingglass",
                    description: viewModel.isSearching ? "Looking up matching places." : "Check the spelling or try a new search."
                )
            }
        }
    }
}

private struct SearchEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(WeatherPalette.ink.opacity(0.64))
                .padding(.bottom, 4)

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(WeatherPalette.ink)

            Text(description)
                .font(.system(size: 15, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(WeatherPalette.ink.opacity(0.78))
        }
        .frame(maxWidth: .infinity)
    }
}
