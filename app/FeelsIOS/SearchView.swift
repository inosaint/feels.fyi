import SwiftUI

struct SearchView: View {
    let viewModel: WeatherViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var focusTask: Task<Void, Never>?

    private static let keyboardBarGap: CGFloat = 12

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            SearchContentView(
                viewModel: viewModel,
                selectCity: selectCity(_:)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            searchBottomBar
        }
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

    @ViewBuilder
    private var searchBottomBar: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 12) {
                searchBottomBarContent
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, Self.keyboardBarGap)
        } else {
            searchBottomBarContent
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, Self.keyboardBarGap)
        }
    }

    private var searchBottomBarContent: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.1))

                TextField(
                    "Search location",
                    text: Binding(
                        get: { viewModel.searchQuery },
                        set: { viewModel.updateSearchQuery($0) }
                    )
                )
                .focused($isSearchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .textContentType(.none)
                .onSubmit {
                    triggerActionHaptic()
                    viewModel.submitSearch()
                }

                if !viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        triggerActionHaptic()
                        viewModel.updateSearchQuery("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 21, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(red: 0.05, green: 0.05, blue: 0.06))
                    .accessibilityLabel("Clear search")
                }
            }
            .font(.system(size: 19, weight: .regular))
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .frame(height: 44)
            .searchFieldGlass()

            Button {
                dismissSearch()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .regular))
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(WeatherPalette.ink)
            .searchActionGlass()
            .accessibilityLabel("Close search")
        }
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
                .foregroundStyle(Color.gray.opacity(0.86))
                .padding(.bottom, 4)

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)

            Text(description)
                .font(.system(size: 15, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
