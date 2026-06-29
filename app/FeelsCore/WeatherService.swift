import Foundation

protocol WeatherFetching {
    func fetchWeather(for city: City) async throws -> CurrentWeather
}

protocol CitySearching {
    func searchCities(query: String) async throws -> [City]
}

protocol LocationProviding {
    func requestLocation() async -> Coordinates?
}

struct UnavailableLocationProvider: LocationProviding {
    func requestLocation() async -> Coordinates? {
        nil
    }
}

struct WeatherService: WeatherFetching, CitySearching {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchWeather(for city: City) async throws -> CurrentWeather {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(city.latitude)),
            URLQueryItem(name: "longitude", value: String(city.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,cloud_cover,is_day"),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validate(response)
        let forecast = try JSONDecoder().decode(ForecastResponse.self, from: data)

        return CurrentWeather(
            temperature: forecast.current.temperature,
            weatherCode: forecast.current.weatherCode,
            windSpeed: forecast.current.windSpeed,
            relativeHumidity: forecast.current.relativeHumidity,
            cloudCover: forecast.current.cloudCover,
            isDay: forecast.current.isDay,
            time: forecast.current.time
        )
    }

    func searchCities(query: String) async throws -> [City] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            return []
        }

        var cities: [City] = []
        for variant in IndianPlaceNameAliases.searchVariants(for: trimmedQuery) {
            cities.append(contentsOf: try await searchCitiesMatching(variant))
        }

        return deduplicated(cities)
    }

    private func searchCitiesMatching(_ query: String) async throws -> [City] {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "20"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validate(response)
        let searchResponse = try JSONDecoder().decode(GeocodingResponse.self, from: data)

        return searchResponse.results.map {
            City(
                name: $0.name,
                country: $0.country ?? "",
                latitude: $0.latitude,
                longitude: $0.longitude,
                population: $0.population,
                countryCode: $0.countryCode
            )
        }
    }

    private func deduplicated(_ cities: [City]) -> [City] {
        var seen = Set<String>()
        return cities.filter { city in
            seen.insert(city.deduplicationKey).inserted
        }
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw WeatherServiceError.requestFailed
        }
    }
}

enum WeatherServiceError: Error {
    case invalidURL
    case requestFailed
}

private struct ForecastResponse: Decodable {
    let current: ForecastCurrent
}

private struct ForecastCurrent: Decodable {
    let time: String?
    let temperature: Double
    let weatherCode: Int
    let windSpeed: Double
    let relativeHumidity: Double
    let cloudCover: Double
    let isDay: Int

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case relativeHumidity = "relative_humidity_2m"
        case cloudCover = "cloud_cover"
        case isDay = "is_day"
    }
}

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        results = try container.decodeIfPresent([GeocodingResult].self, forKey: .results) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case results
    }
}

private struct GeocodingResult: Decodable {
    let name: String
    let country: String?
    let countryCode: String?
    let latitude: Double
    let longitude: Double
    let population: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case country
        case countryCode = "country_code"
        case latitude
        case longitude
        case population
    }
}

private extension City {
    var deduplicationKey: String {
        let roundedLatitude = (latitude * 10_000).rounded() / 10_000
        let roundedLongitude = (longitude * 10_000).rounded() / 10_000
        return "\(name.lowercased())-\(country.lowercased())-\(roundedLatitude)-\(roundedLongitude)"
    }
}
