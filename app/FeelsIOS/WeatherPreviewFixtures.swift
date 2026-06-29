import Foundation

extension WeatherViewModel {
    static var previewLoaded: WeatherViewModel {
        preview(snapshot: WeatherSnapshot.clearMorning)
    }

    static var previewLoading: WeatherViewModel {
        WeatherViewModel(
            weatherFetcher: PreviewWeatherClient(result: .success(WeatherSnapshot.clearMorning.weather)),
            citySearcher: PreviewWeatherClient(result: .success(WeatherSnapshot.clearMorning.weather)),
            persistence: PreviewWeatherStore(),
            initialState: .loading(previous: nil)
        )
    }

    static var previewUnavailable: WeatherViewModel {
        WeatherViewModel(
            weatherFetcher: PreviewWeatherClient(result: .success(WeatherSnapshot.clearMorning.weather)),
            citySearcher: PreviewWeatherClient(result: .success(WeatherSnapshot.clearMorning.weather)),
            persistence: PreviewWeatherStore(),
            initialState: .unavailable(message: "Weather unavailable")
        )
    }

    static var previewRain: WeatherViewModel {
        preview(snapshot: WeatherSnapshot.rain)
    }

    static var previewLongCity: WeatherViewModel {
        preview(snapshot: WeatherSnapshot.longCity)
    }

    static var previewSearchResults: WeatherViewModel {
        let viewModel = preview(snapshot: WeatherSnapshot.clearMorning)
        viewModel.isSearchPresented = true
        viewModel.searchQuery = "ba"
        viewModel.searchResults = PreviewSearchCityFixtures.cities
        return viewModel
    }

    private static func preview(snapshot: WeatherSnapshot) -> WeatherViewModel {
        WeatherViewModel(
            weatherFetcher: PreviewWeatherClient(result: .success(snapshot.weather)),
            citySearcher: PreviewWeatherClient(result: .success(snapshot.weather)),
            persistence: PreviewWeatherStore(snapshot: snapshot),
            initialState: .loaded(snapshot)
        )
    }
}

private enum PreviewSearchCityFixtures {
    static var cities: [City] {
        [
            City(name: "Bengaluru", country: "India", latitude: 12.97194, longitude: 77.59369, population: 8495492, countryCode: "IN"),
            City(name: "Bangkok", country: "Thailand", latitude: 13.75398, longitude: 100.50144, population: 5104476, countryCode: "TH"),
            City(name: "Barcelona", country: "Spain", latitude: 41.38879, longitude: 2.15899, population: 1621537, countryCode: "ES"),
            City(name: "Bali", country: "Indonesia", latitude: -8.40952, longitude: 115.18892, population: 4362000, countryCode: "ID"),
            City(name: "Basel", country: "Switzerland", latitude: 47.55839, longitude: 7.57327, population: 164488, countryCode: "CH"),
            City(name: "Baltimore", country: "United States", latitude: 39.29038, longitude: -76.61219, population: 576498, countryCode: "US"),
            City(name: "Baku", country: "Azerbaijan", latitude: 40.37767, longitude: 49.89201, population: 1116513, countryCode: "AZ"),
            City(name: "Bandung", country: "Indonesia", latitude: -6.92222, longitude: 107.60694, population: 1699719, countryCode: "ID"),
            City(name: "Bari", country: "Italy", latitude: 41.11773, longitude: 16.85118, population: 277387, countryCode: "IT"),
            City(name: "Barranquilla", country: "Colombia", latitude: 10.96854, longitude: -74.78132, population: 1380425, countryCode: "CO")
        ]
    }
}

private extension WeatherSnapshot {
    static let clearMorning = WeatherSnapshot(
        city: .defaultCity,
        weather: CurrentWeather(
            temperature: 29,
            weatherCode: 1,
            windSpeed: 8,
            relativeHumidity: 58,
            cloudCover: 18,
            isDay: 1,
            time: "2026-06-22T10:00"
        ),
        visual: .clearMorning,
        capturedAt: Date(timeIntervalSince1970: 1_787_328_000)
    )

    static let rain = WeatherSnapshot(
        city: City(name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777),
        weather: CurrentWeather(
            temperature: 27,
            weatherCode: 63,
            windSpeed: 21,
            relativeHumidity: 92,
            cloudCover: 96,
            isDay: 1,
            time: "2026-06-22T15:00"
        ),
        visual: .rain,
        capturedAt: Date(timeIntervalSince1970: 1_787_346_000)
    )

    static let longCity = WeatherSnapshot(
        city: City(
            name: "Thiruvananthapuram International",
            country: "India",
            latitude: 8.5241,
            longitude: 76.9366
        ),
        weather: CurrentWeather(
            temperature: 36,
            weatherCode: 0,
            windSpeed: 10,
            relativeHumidity: 62,
            cloudCover: 4,
            isDay: 1,
            time: "2026-06-22T12:00"
        ),
        visual: .hot,
        capturedAt: Date(timeIntervalSince1970: 1_787_335_200)
    )
}

private struct PreviewWeatherClient: WeatherFetching, CitySearching {
    let result: Result<CurrentWeather, Error>

    func fetchWeather(for city: City) async throws -> CurrentWeather {
        try result.get()
    }

    func searchCities(query: String) async throws -> [City] {
        PreviewSearchCityFixtures.cities
    }
}

private struct PreviewWeatherStore: WeatherPersisting {
    let snapshot: WeatherSnapshot?

    init(snapshot: WeatherSnapshot? = nil) {
        self.snapshot = snapshot
    }

    func loadSelectedCity() -> City? {
        snapshot?.city
    }

    func saveSelectedCity(_ city: City) {}

    func loadRecentSearchedCities() -> [City] {
        []
    }

    func saveRecentSearchedCities(_ cities: [City]) {}

    func loadSnapshot() -> WeatherSnapshot? {
        snapshot
    }

    func saveSnapshot(_ snapshot: WeatherSnapshot) {}
}
