import SwiftUI

struct SearchView: View {
    let viewModel: WeatherViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var focusTask: Task<Void, Never>?

    private static let keyboardBarGap: CGFloat = 12
    private static let searchFieldHeight: CGFloat = 48

    var body: some View {
        ZStack {
            ZStack {
                SearchBackdropView()

                SearchContentView(
                    viewModel: viewModel,
                    selectCity: selectCity(_:)
                )
            }
            .opacity(searchOverlayOpacity)
            .mask {
                SearchOverlayRadialMask(isPresented: viewModel.isSearchPresented)
            }
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
            focusTask?.cancel()
            focusTask = Task {
                try? await Task.sleep(for: .milliseconds(360))
                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    isSearchFocused = true
                }
            }
        }
        .onDisappear {
            focusTask?.cancel()
            focusTask = nil
            isSearchFocused = false
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
            if viewModel.isSearchPresented {
                closeButton
                    .transition(.identity)
            }
        }
        .frame(width: 44, height: 44)
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
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

    private var searchFieldContentOpacity: Double {
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

    private func selectCity(_ city: City) {
        triggerActionHaptic()
        isSearchFocused = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            viewModel.selectCity(city)
        }
    }

    private func dismissSearch() {
        triggerActionHaptic()
        isSearchFocused = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            viewModel.dismissSearch()
        }
    }

    private func triggerActionHaptic() {
        AppHaptics.selection()
    }
}

struct SearchBottomBarView: View {
    let viewModel: WeatherViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var focusTask: Task<Void, Never>?

    private static let keyboardBarGap: CGFloat = 12
    private static let searchFieldHeight: CGFloat = 48

    var body: some View {
        ZStack {
            Color.clear
                .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            searchBottomBar
        }
        .onAppear {
            focusTask?.cancel()
            focusTask = Task {
                try? await Task.sleep(for: .milliseconds(360))
                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    isSearchFocused = true
                }
            }
        }
        .onDisappear {
            focusTask?.cancel()
            focusTask = nil
            isSearchFocused = false
        }
    }

    private var searchBottomBar: some View {
        HStack(spacing: 12) {
            searchFieldControls
                .frame(height: Self.searchFieldHeight)
                .frame(maxWidth: .infinity)

            closeButtonSlot
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, Self.keyboardBarGap)
        .animation(searchFieldContentAnimation, value: viewModel.isSearchPresented)
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
            if viewModel.isSearchPresented {
                closeButton
                    .transition(.identity)
            }
        }
        .frame(width: 44, height: 44)
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
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

    private var searchFieldContentAnimation: Animation {
        viewModel.isSearchPresented
            ? .easeOut(duration: 0.12)
            : .timingCurve(0.32, 0, 0.67, 0, duration: 0.06)
    }

    private func dismissSearch() {
        triggerActionHaptic()
        isSearchFocused = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            viewModel.dismissSearch()
        }
    }

    private func triggerActionHaptic() {
        AppHaptics.selection()
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
    let selectCity: (City) -> Void

    private var trimmedQuery: String {
        viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isShowingEmptyState: Bool {
        trimmedQuery.count < 2 || viewModel.searchResults.isEmpty
    }

    var body: some View {
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
            } else {
                List {
                    ForEach(viewModel.searchResults) { city in
                        Button {
                            selectCity(city)
                        } label: {
                            Text(city.displayName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .foregroundStyle(WeatherPalette.ink)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.visible, edges: .bottom)
                    }
                }
                .listStyle(.plain)
                .environment(\.locale, Locale(identifier: "en_US"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isShowingEmptyState ? .center : .top)
        .padding(.horizontal, isShowingEmptyState ? 28 : 0)
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
