import Foundation
import Observation

@MainActor
@Observable
final class WeatherViewModel {
    private static let searchResultsLimit = 6
    private static let recentSearchedCitiesLimit = 3

    enum LoadState: Equatable {
        case idle
        case loading(previous: WeatherSnapshot?)
        case loaded(WeatherSnapshot)
        case staleLoaded(WeatherSnapshot, message: String)
        case unavailable(message: String)

        var snapshot: WeatherSnapshot? {
            switch self {
            case .idle, .unavailable:
                return nil
            case .loading(let previous):
                return previous
            case .loaded(let snapshot), .staleLoaded(let snapshot, _):
                return snapshot
            }
        }

        var isLoading: Bool {
            if case .loading = self {
                return true
            }

            return false
        }

        var isUnavailable: Bool {
            if case .unavailable = self {
                return true
            }

            return false
        }

        var message: String? {
            switch self {
            case .staleLoaded(_, let message), .unavailable(let message):
                return message
            case .idle, .loading, .loaded:
                return nil
            }
        }
    }

    var state: LoadState
    var searchQuery = ""
    var searchResults: [City] = []
    var recentSearchedCities: [City] = []
    var isSearchPresented = false
    var isSearching = false
    var searchMessage = ""
    var statusMessage = "Allow location"

    @ObservationIgnored private let weatherFetcher: any WeatherFetching
    @ObservationIgnored private let citySearcher: any CitySearching
    @ObservationIgnored private let locationProvider: any LocationProviding
    @ObservationIgnored private let persistence: any WeatherPersisting
    @ObservationIgnored private let searchDebounce: Duration
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var weatherTask: Task<Void, Never>?
    @ObservationIgnored private var userCoordinates: Coordinates?
    @ObservationIgnored private var selectedCity: City
    @ObservationIgnored private var restoredVisual: WeatherVisual
    @ObservationIgnored private var hasInitialized = false
    @ObservationIgnored private var loadSequence = 0

    init(
        weatherFetcher: any WeatherFetching = WeatherService(),
        citySearcher: any CitySearching = WeatherService(),
        locationProvider: any LocationProviding = UnavailableLocationProvider(),
        persistence: any WeatherPersisting = UserDefaultsWeatherStore(),
        searchDebounce: Duration = .milliseconds(300),
        initialState: LoadState? = nil
    ) {
        self.weatherFetcher = weatherFetcher
        self.citySearcher = citySearcher
        self.locationProvider = locationProvider
        self.persistence = persistence
        self.searchDebounce = searchDebounce

        let cachedSnapshot = persistence.loadSnapshot()
        let cachedCurrentLocationState = cachedSnapshot.flatMap(Self.currentLocationState)
        self.selectedCity = .defaultCity
        self.restoredVisual = cachedCurrentLocationState?.snapshot?.visual
            ?? (persistence as? UserDefaultsWeatherStore)?.loadLegacyVisual()
            ?? .clearMorning
        self.state = initialState ?? cachedCurrentLocationState ?? .idle
        self.searchQuery = selectedCity.name
        self.recentSearchedCities = Self.normalizedRecentSearchedCities(
            persistence.loadRecentSearchedCities()
        )
        self.statusMessage = state.snapshot?.city.displayName ?? "Allow location"
    }

    deinit {
        searchTask?.cancel()
        weatherTask?.cancel()
    }

    var displayedSnapshot: WeatherSnapshot? {
        state.snapshot
    }

    var hasWeatherData: Bool {
        displayedSnapshot != nil
    }

    var currentCity: City {
        displayedSnapshot?.city ?? selectedCity
    }

    var currentVisual: WeatherVisual {
        displayedSnapshot?.visual ?? restoredVisual
    }

    var temperatureText: String {
        displayedSnapshot?.temperatureText ?? "--"
    }

    var conditionText: String {
        displayedSnapshot?.conditionText ?? state.message ?? "Loading"
    }

    var isInitialLoading: Bool {
        state.isLoading && displayedSnapshot == nil
    }

    func initialize() async {
        guard !hasInitialized else {
            return
        }

        hasInitialized = true
        statusMessage = "Allow location"

        if let coordinates = await locationProvider.requestLocation() {
            userCoordinates = coordinates
            await loadWeather(
                for: City(
                    name: "Current location",
                    country: "",
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )
            )
        } else {
            await loadWeather(for: .defaultCity)
        }
    }

    func presentSearch() {
        searchQuery = ""
        searchMessage = ""
        statusMessage = currentCity.displayName
        searchResults = []
        isSearchPresented = true
    }

    func dismissSearch() {
        searchTask?.cancel()
        searchResults = []
        isSearching = false
        searchMessage = ""
        isSearchPresented = false
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            isSearching = false
            searchMessage = ""
            return
        }

        isSearching = true
        searchMessage = "Searching"
        statusMessage = "Searching"

        searchTask = Task {
            do {
                try await Task.sleep(for: searchDebounce)
                guard !Task.isCancelled else {
                    return
                }

                await performSearch(query: trimmedQuery)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                searchResults = []
                isSearching = false
                searchMessage = "Search unavailable"
                statusMessage = "Search unavailable"
            }
        }
    }

    func submitSearch() {
        searchTask?.cancel()
        searchTask = Task {
            await performSearch(query: searchQuery)
        }
    }

    func selectCity(_ city: City) {
        dismissSearch()
        weatherTask?.cancel()
        weatherTask = Task {
            await loadCity(city, shouldSaveRecentSearch: true)
        }
    }

    func loadCity(_ city: City, shouldSaveRecentSearch: Bool = false) async {
        dismissSearch()
        await loadWeather(for: city, shouldSaveRecentSearch: shouldSaveRecentSearch)
    }

    private func performSearch(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            isSearching = false
            searchMessage = ""
            return
        }

        isSearching = true
        searchMessage = "Searching"
        statusMessage = "Searching"

        do {
            let cities = try await citySearcher.searchCities(query: trimmedQuery)
            guard !Task.isCancelled else {
                return
            }

            searchResults = Array(
                CityRanking.sorted(
                    cities,
                    query: trimmedQuery,
                    userCoordinates: userCoordinates
                ).prefix(Self.searchResultsLimit)
            )
            isSearching = false
            searchMessage = searchResults.isEmpty ? "No results" : ""
            statusMessage = currentCity.displayName
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else {
                return
            }

            searchResults = []
            isSearching = false
            searchMessage = "Search unavailable"
            statusMessage = "Search unavailable"
        }
    }

    private func loadWeather(
        for city: City,
        shouldSaveRecentSearch: Bool = false
    ) async {
        loadSequence += 1
        let loadToken = loadSequence
        let previousSnapshot = state.snapshot

        state = .loading(previous: previousSnapshot)
        statusMessage = "Loading \(city.name)"

        do {
            let currentWeather = try await weatherFetcher.fetchWeather(for: city)
            guard loadToken == loadSequence, !Task.isCancelled else {
                return
            }

            let snapshot = WeatherSnapshot(
                city: city,
                weather: currentWeather,
                visual: WeatherRules.visual(currentWeather)
            )
            selectedCity = city
            restoredVisual = snapshot.visual
            state = .loaded(snapshot)
            searchQuery = city.name
            statusMessage = city.displayName

            persistence.saveSnapshot(snapshot)
            if shouldSaveRecentSearch {
                saveRecentSearchedCity(city)
            }
        } catch is CancellationError {
            return
        } catch {
            guard loadToken == loadSequence, !Task.isCancelled else {
                return
            }

            statusMessage = "Weather unavailable"
            if let previousSnapshot {
                state = .staleLoaded(previousSnapshot, message: "Weather unavailable")
            } else {
                state = .unavailable(message: "Weather unavailable")
            }
        }
    }

    private func saveRecentSearchedCity(_ city: City) {
        recentSearchedCities = Self.normalizedRecentSearchedCities([city] + recentSearchedCities)
        persistence.saveRecentSearchedCities(recentSearchedCities)
    }

    private static func currentLocationState(_ snapshot: WeatherSnapshot) -> LoadState? {
        guard snapshot.city.name == "Current location" else {
            return nil
        }

        return .staleLoaded(snapshot, message: "Updating weather")
    }

    private static func normalizedRecentSearchedCities(_ cities: [City]) -> [City] {
        var seen = Set<String>()
        var normalized: [City] = []

        for city in cities {
            guard seen.insert(city.id).inserted else {
                continue
            }

            normalized.append(city)

            if normalized.count == recentSearchedCitiesLimit {
                break
            }
        }

        return normalized
    }
}
