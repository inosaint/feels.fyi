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

    private static func preview(snapshot: WeatherSnapshot) -> WeatherViewModel {
        WeatherViewModel(
            weatherFetcher: PreviewWeatherClient(result: .success(snapshot.weather)),
            citySearcher: PreviewWeatherClient(result: .success(snapshot.weather)),
            persistence: PreviewWeatherStore(snapshot: snapshot),
            initialState: .loaded(snapshot)
        )
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
        [
            .defaultCity,
            City(name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777)
        ]
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

    func loadSnapshot() -> WeatherSnapshot? {
        snapshot
    }

    func saveSnapshot(_ snapshot: WeatherSnapshot) {}
}
