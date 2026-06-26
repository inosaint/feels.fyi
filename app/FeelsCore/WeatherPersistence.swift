import Foundation

protocol WeatherPersisting {
    func loadSelectedCity() -> City?
    func saveSelectedCity(_ city: City)
    func loadSnapshot() -> WeatherSnapshot?
    func saveSnapshot(_ snapshot: WeatherSnapshot)
}

struct WeatherSnapshot: Codable, Equatable, Sendable {
    let city: City
    let weather: CurrentWeather
    let visual: WeatherVisual
    let capturedAt: Date

    init(
        city: City,
        weather: CurrentWeather,
        visual: WeatherVisual,
        capturedAt: Date = Date()
    ) {
        self.city = city
        self.weather = weather
        self.visual = visual
        self.capturedAt = capturedAt
    }

    var temperatureText: String {
        "\(Int(weather.temperature.rounded()))"
    }

    var conditionText: String {
        WeatherRules.conditionLabel(weather)
    }

    static let placeholder = WeatherSnapshot(
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
}

struct UserDefaultsWeatherStore: WeatherPersisting {
    static let appGroupSuiteName = "group.fyi.feels.weather"
    static var sharedSurfaceStore: UserDefaultsWeatherStore {
        UserDefaultsWeatherStore(suiteName: appGroupSuiteName) ?? UserDefaultsWeatherStore()
    }

    static func loadSharedSnapshot() -> WeatherSnapshot {
        sharedSurfaceStore.loadSnapshot() ?? UserDefaultsWeatherStore().loadSnapshot() ?? .placeholder
    }

    private let userDefaults: UserDefaults

    private enum Keys {
        static let selectedCity = "selectedCity"
        static let snapshot = "weatherSnapshot"
        static let legacyVisual = "weatherVisual"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    init?(suiteName: String) {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return nil
        }

        self.userDefaults = userDefaults
    }

    func loadSelectedCity() -> City? {
        guard let data = userDefaults.data(forKey: Keys.selectedCity) else {
            return nil
        }

        return try? JSONDecoder().decode(City.self, from: data)
    }

    func saveSelectedCity(_ city: City) {
        guard let data = try? JSONEncoder().encode(city) else {
            return
        }

        userDefaults.set(data, forKey: Keys.selectedCity)
    }

    func loadSnapshot() -> WeatherSnapshot? {
        guard let data = userDefaults.data(forKey: Keys.snapshot) else {
            return nil
        }

        return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: WeatherSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        userDefaults.set(data, forKey: Keys.snapshot)
    }

    func loadLegacyVisual() -> WeatherVisual? {
        guard let rawValue = userDefaults.string(forKey: Keys.legacyVisual) else {
            return nil
        }

        return WeatherVisual(rawValue: rawValue)
    }
}
