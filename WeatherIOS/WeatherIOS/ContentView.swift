import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var isSplashVisible = true
    @State private var isSplashResolving = false

    var body: some View {
        ZStack {
            AppContentView(viewModel: viewModel)
                .opacity(isSplashVisible && !isSplashResolving ? 0 : 1)

            if isSplashVisible {
                SplashView(isResolving: isSplashResolving)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.42), value: isSplashVisible)
        .animation(.easeOut(duration: 0.28), value: isSplashResolving)
        .task {
            Task {
                await viewModel.initialize()
            }

            try? await Task.sleep(for: .milliseconds(780))
            withAnimation(.easeOut(duration: 0.28)) {
                isSplashResolving = true
            }
            try? await Task.sleep(for: .milliseconds(240))
            withAnimation(.easeOut(duration: 0.28)) {
                isSplashVisible = false
            }
        }
        .sheet(isPresented: $viewModel.isSearchPresented) {
            SearchView(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(viewModel.statusMessage)
    }
}

private struct AppContentView: View {
    @ObservedObject var viewModel: WeatherViewModel

    var body: some View {
        ZStack {
            if viewModel.hasWeatherData {
                WeatherBackground(visual: viewModel.currentVisual)
                    .transition(.opacity)
            } else {
                InitialLoadingView(
                    title: viewModel.isInitialLoad ? "Loading weather" : "Weather unavailable",
                    isLoading: viewModel.isInitialLoad
                )
                .transition(.opacity)
            }

            VStack(alignment: .leading) {
                if viewModel.hasWeatherData {
                    WeatherReadout(
                        temperatureText: viewModel.temperatureText,
                        conditionText: viewModel.conditionText
                    )
                    .padding(.top, 28)
                    .transition(.opacity)
                }

                Spacer()

                if viewModel.hasWeatherData {
                    Button {
                        viewModel.presentSearch()
                    } label: {
                        HStack(spacing: 8) {
                            LocationPinIcon()
                                .frame(width: 19, height: 19)

                            Text(viewModel.currentCity.displayName)
                                .lineLimit(1)
                        }
                        .font(.body)
                        .foregroundStyle(Color(red: 0.13, green: 0.02, blue: 0.07))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 48)
                        .locationPillGlass()
                    }
                    .accessibilityHint("Opens location search")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.32).delay(0.08), value: viewModel.hasWeatherData)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 52)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .animation(.easeOut(duration: 0.36), value: viewModel.hasWeatherData)
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
                    .foregroundStyle(Color(red: 0.13, green: 0.02, blue: 0.07))
            }
                .opacity(isResolving ? 0 : 1)
                .scaleEffect(isResolving ? 0.96 : 1)
        }
        .accessibilityLabel("feels.fyi")
    }
}

private struct WeatherBackground: View {
    let visual: WeatherVisual

    var body: some View {
        ZStack {
            visual.fallbackColor

            Image(visual.assetName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

private struct InitialLoadingView: View {
    let title: String
    let isLoading: Bool

    var body: some View {
        ZStack {
            Color.white

            VStack(spacing: 14) {
                if isLoading {
                    ProgressView()
                        .tint(Color(red: 0.13, green: 0.02, blue: 0.07))
                }

                if !isLoading {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(Color(red: 0.13, green: 0.02, blue: 0.07))
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct WeatherReadout: View {
    let temperatureText: String
    let conditionText: String
    @State private var temperatureWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                Text(temperatureText)
                    .font(.custom("Caveat Brush", size: 204))
                    .minimumScaleFactor(0.74)
                    .lineLimit(1)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: TemperatureWidthKey.self, value: proxy.size.width)
                        }
                    )

                Text("°")
                    .font(.custom("Caveat Brush", size: 40))
                    .offset(x: max(0, temperatureWidth - 9), y: 35)
            }
            .frame(width: 330, height: 156, alignment: .topLeading)
            .foregroundStyle(Color(red: 0.13, green: 0.02, blue: 0.07))
            .onPreferenceChange(TemperatureWidthKey.self) { width in
                temperatureWidth = width
            }

            Text(conditionText)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Color(red: 0.13, green: 0.02, blue: 0.07))
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

private struct LocationPinIcon: View {
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

private struct LocationPinShape: Shape {
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

private struct SearchView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary)

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
                    .keyboardType(.asciiCapable)
                    .textContentType(.none)
                    .onSubmit {
                        viewModel.submitSearch()
                    }
                }
                .font(.system(size: 19, weight: .regular))
                .padding(.horizontal, 12)
                .frame(height: 44)
                .searchFieldGlass()

                Button("Cancel") {
                    viewModel.dismissSearch()
                }
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color(red: 0.13, green: 0.02, blue: 0.07))
                .padding(.horizontal, 14)
                .frame(height: 44)
                .searchActionGlass()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Divider()

            SearchContentView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
        }
        .searchSheetBackground()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environment(\.locale, Locale(identifier: "en_US"))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isSearchFocused = true
            }
        }
    }
}

private struct SearchContentView: View {
    @ObservedObject var viewModel: WeatherViewModel

    private var trimmedQuery: String {
        viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if trimmedQuery.count < 2 {
            SearchEmptyState(
                title: "Search for a place",
                systemImage: "magnifyingglass",
                description: "Start typing a city or region."
            )
        } else if viewModel.searchResults.isEmpty {
            SearchEmptyState(
                title: viewModel.statusMessage == "Searching" ? "Searching" : "No cities found",
                systemImage: viewModel.statusMessage == "Searching" ? "hourglass" : "map",
                description: viewModel.statusMessage == "Searching" ? "Looking up matching places." : "Try a different spelling or nearby city."
            )
        } else {
            List {
                ForEach(viewModel.searchResults) { city in
                    Button {
                        viewModel.selectCity(city)
                    } label: {
                        Text(city.displayName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .foregroundStyle(Color(red: 0.13, green: 0.02, blue: 0.07))
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.visible, edges: .bottom)
                }
            }
            .listStyle(.plain)
            .environment(\.locale, Locale(identifier: "en_US"))
        }
    }
}

private struct SearchEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    @ViewBuilder
    func searchFieldGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(.white.opacity(0.18)).interactive(), in: .rect(cornerRadius: 13))
        } else {
            self
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }

    @ViewBuilder
    func searchActionGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(.white.opacity(0.14)).interactive(), in: .capsule)
        } else {
            self
                .background(Color(.secondarySystemBackground), in: Capsule())
        }
    }

    @ViewBuilder
    func searchSheetBackground() -> some View {
        if #available(iOS 26, *) {
            self
                .background(.regularMaterial)
        } else {
            self
                .background(Color(.systemBackground))
        }
    }

    @ViewBuilder
    func locationPillGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(.white.opacity(0.22)).interactive(), in: .capsule)
                .shadow(color: .black.opacity(0.16), radius: 23, x: 0, y: 18)
        } else {
            self
                .background(.white.opacity(0.34), in: Capsule())
                .shadow(color: .black.opacity(0.16), radius: 23, x: 0, y: 18)
        }
    }

}

#Preview {
    ContentView()
}
