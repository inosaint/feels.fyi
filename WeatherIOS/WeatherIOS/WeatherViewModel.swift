import Combine
import Foundation
import SwiftUI

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var temperatureText = "--"
    @Published var conditionText = "Loading"
    @Published var currentCity: City
    @Published var currentVisual: WeatherVisual
    @Published var searchQuery = ""
    @Published var searchResults: [City] = []
    @Published var isSearchPresented = false
    @Published var isLoading = false
    @Published var isInitialLoad = true
    @Published var hasWeatherData = false
    @Published var statusMessage = "Allow location"

    private let weatherService: WeatherService
    private let locationManager: LocationManager
    private let userDefaults: UserDefaults
    private var searchTask: Task<Void, Never>?
    private var userCoordinates: Coordinates?
    private var hasInitialized = false

    private enum Keys {
        static let selectedCity = "selectedCity"
        static let visual = "weatherVisual"
    }

    init(
        weatherService: WeatherService = WeatherService(),
        locationManager: LocationManager = LocationManager(),
        userDefaults: UserDefaults = .standard
    ) {
        self.weatherService = weatherService
        self.locationManager = locationManager
        self.userDefaults = userDefaults
        self.currentCity = Self.restoreCity(from: userDefaults) ?? .defaultCity
        self.currentVisual = Self.restoreVisual(from: userDefaults) ?? .clearMorning
        self.searchQuery = currentCity.name
    }

    func initialize() async {
        guard !hasInitialized else {
            return
        }

        hasInitialized = true
        statusMessage = "Allow location"

        if let coordinates = await locationManager.requestLocation() {
            userCoordinates = coordinates
            await loadWeather(
                for: City(
                    name: "Current location",
                    country: "",
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                ),
                shouldPersistCity: false
            )
        } else {
            await loadWeather(for: currentCity)
        }
    }

    func presentSearch() {
        searchQuery = ""
        statusMessage = currentCity.displayName
        searchResults = []
        isSearchPresented = true
    }

    func dismissSearch() {
        searchTask?.cancel()
        searchResults = []
        isSearchPresented = false
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            return
        }

        statusMessage = "Searching"
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else {
                return
            }

            do {
                let cities = try await weatherService.searchCities(query: trimmedQuery)
                guard !Task.isCancelled else {
                    return
                }

                searchResults = Array(
                    CityRanking.sorted(
                        cities,
                        query: trimmedQuery,
                        userCoordinates: userCoordinates
                    ).prefix(5)
                )
                statusMessage = currentCity.displayName
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                searchResults = []
                statusMessage = "Search unavailable"
            }
        }
    }

    func submitSearch() {
        searchTask?.cancel()

        Task {
            await performSearch(query: searchQuery)
        }
    }

    func selectCity(_ city: City) {
        dismissSearch()

        Task {
            await loadWeather(for: city)
        }
    }

    private func performSearch(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            return
        }

        statusMessage = "Searching"

        do {
            let cities = try await weatherService.searchCities(query: trimmedQuery)
            searchResults = Array(
                CityRanking.sorted(
                    cities,
                    query: trimmedQuery,
                    userCoordinates: userCoordinates
                ).prefix(5)
            )
            statusMessage = currentCity.displayName
        } catch {
            searchResults = []
            statusMessage = "Search unavailable"
        }
    }

    private func loadWeather(for city: City, shouldPersistCity: Bool = true) async {
        isLoading = true
        let shouldKeepExistingWeather = hasWeatherData

        if !shouldKeepExistingWeather {
            withAnimation(.easeOut(duration: 0.22)) {
                hasWeatherData = false
            }
            conditionText = "Loading"
        }

        statusMessage = "Loading \(city.name)"
        let isInitialWeatherRequest = isInitialLoad

        do {
            let currentWeather = try await weatherService.fetchWeather(for: city)
            temperatureText = "\(Int(currentWeather.temperature.rounded()))"
            conditionText = WeatherRules.conditionLabel(currentWeather)
            currentVisual = WeatherRules.visual(currentWeather)
            currentCity = city
            searchQuery = city.name
            statusMessage = city.displayName
            withAnimation(.easeOut(duration: 0.36)) {
                hasWeatherData = true
            }

            if shouldPersistCity {
                persist(city)
            }
            persist(currentVisual)
        } catch {
            statusMessage = "Weather unavailable"

            if !shouldKeepExistingWeather {
                conditionText = "Unavailable"
                withAnimation(.easeOut(duration: 0.22)) {
                    hasWeatherData = false
                }
            }
        }

        isLoading = false
        if isInitialWeatherRequest {
            isInitialLoad = false
        }
    }

    private func persist(_ city: City) {
        guard let data = try? JSONEncoder().encode(city) else {
            return
        }

        userDefaults.set(data, forKey: Keys.selectedCity)
    }

    private func persist(_ visual: WeatherVisual) {
        userDefaults.set(visual.rawValue, forKey: Keys.visual)
    }

    private static func restoreCity(from userDefaults: UserDefaults) -> City? {
        guard let data = userDefaults.data(forKey: Keys.selectedCity) else {
            return nil
        }

        return try? JSONDecoder().decode(City.self, from: data)
    }

    private static func restoreVisual(from userDefaults: UserDefaults) -> WeatherVisual? {
        guard let rawValue = userDefaults.string(forKey: Keys.visual) else {
            return nil
        }

        return WeatherVisual(rawValue: rawValue)
    }
}
