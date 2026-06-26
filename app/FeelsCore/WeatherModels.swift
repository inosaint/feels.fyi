import Foundation

struct Coordinates: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

struct City: Codable, Equatable, Identifiable, Sendable {
    static let defaultCity = City(
        name: "Bengaluru",
        country: "India",
        latitude: 12.9716,
        longitude: 77.5946
    )

    var id: String {
        "\(name)-\(country)-\(latitude)-\(longitude)"
    }

    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let population: Int?
    let countryCode: String?

    init(
        name: String,
        country: String,
        latitude: Double,
        longitude: Double,
        population: Int? = nil,
        countryCode: String? = nil
    ) {
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.population = population
        self.countryCode = countryCode
    }

    var coordinates: Coordinates {
        Coordinates(latitude: latitude, longitude: longitude)
    }

    var displayName: String {
        country.isEmpty ? name : "\(name), \(country)"
    }
}

enum IndianPlaceNameAliases {
    private static let aliases: [String: [String]] = [
        "ahmednagar": ["ahilyanagar"],
        "allahabad": ["prayagraj"],
        "aurangabad": ["chhatrapati sambhajinagar", "sambhajinagar"],
        "bangalore": ["bengaluru"],
        "belgaum": ["belagavi"],
        "bellary": ["ballari"],
        "bijapur": ["vijayapura"],
        "calcutta": ["kolkata"],
        "chikmagalur": ["chikkamagaluru"],
        "cuddapah": ["kadapa"],
        "daltonganj": ["medininagar"],
        "faizabad": ["ayodhya"],
        "goa": ["panjim"],
        "gulbarga": ["kalaburagi"],
        "gurgaon": ["gurugram"],
        "hospet": ["hosapete"],
        "hoshangabad": ["narmadapuram"],
        "hubli": ["hubballi"],
        "karimganj": ["sribhumi"],
        "mangalore": ["mangaluru"],
        "mysore": ["mysuru"],
        "new raipur": ["atal nagar", "naya raipur"],
        "osmanabad": ["dharashiv"],
        "panaji": ["panjim"],
        "pondicherry": ["puducherry"],
        "rajahmundry": ["rajamahendravaram", "rajahmahendravaram"],
        "shimoga": ["shivamogga"],
        "tumkur": ["tumakuru"]
    ]

    static func searchVariants(for query: String) -> [String] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        var variants = [trimmedQuery]
        variants.append(contentsOf: aliases[normalized(trimmedQuery)] ?? [])
        return deduplicated(variants)
    }

    static func isRenameQuery(_ query: String) -> Bool {
        aliases[normalized(query)] != nil
    }

    static func matches(_ city: City, query: String) -> Bool {
        let normalizedCityName = normalized(city.name)
        return searchVariants(for: query).contains { normalized($0) == normalizedCityName }
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_IN"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func deduplicated(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { value in
            seen.insert(normalized(value)).inserted
        }
    }
}

enum WeatherVisual: String, Codable, CaseIterable, Sendable {
    case hot
    case clearMorning
    case clearEvening
    case cloudy
    case fog
    case drizzle
    case rain
    case storm

    var assetName: String {
        switch self {
        case .hot:
            return "hot35-ios"
        case .clearMorning:
            return "clear-sky-morning-ios"
        case .clearEvening:
            return "clear-sky-evening-ios"
        case .cloudy:
            return "cloudy-ios"
        case .fog:
            return "fog-ios"
        case .drizzle:
            return "drizzle-ios"
        case .rain:
            return "rain-ios"
        case .storm:
            return "heavy-rain-and-wind-ios"
        }
    }
}

enum WeatherRules {
    static let clearCodes: Set<Int> = [0, 1]
    static let cloudyCodes: Set<Int> = [2, 3]
    static let fogCodes: Set<Int> = [45, 48]
    static let drizzleCodes: Set<Int> = [51, 53, 55, 56, 57, 61]
    static let rainCodes: Set<Int> = [63, 65, 66, 67, 80, 81]
    static let stormCodes: Set<Int> = [82, 95, 96, 99]
    static let snowCodes: Set<Int> = [71, 73, 75, 77, 85, 86]

    static let labels: [Int: String] = [
        0: "Sunny",
        1: "Mostly sunny",
        2: "Partly cloudy",
        3: "Cloudy",
        45: "Foggy",
        48: "Foggy",
        51: "Drizzle",
        53: "Drizzle",
        55: "Drizzle",
        56: "Icy drizzle",
        57: "Icy drizzle",
        61: "Light rain",
        63: "Rain",
        65: "Heavy rain",
        66: "Icy rain",
        67: "Icy rain",
        71: "Light snow",
        73: "Snow",
        75: "Heavy snow",
        77: "Snow grains",
        80: "Rain showers",
        81: "Rain showers",
        82: "Heavy showers",
        85: "Snow showers",
        86: "Snow showers",
        95: "Stormy",
        96: "Thunderstorm",
        99: "Thunderstorm"
    ]

    static func conditionLabel(_ weather: CurrentWeather) -> String {
        let isNight = weather.isDay == 0
        let code = weather.weatherCode

        if isNight, code == 0 {
            return "Clear"
        }

        if isNight, code == 1 {
            return "Mostly clear"
        }

        if isMisty(weather) {
            return "Misty"
        }

        if weather.windSpeed >= 38, !isHeavyPrecipitation(code) {
            return "Windy"
        }

        return labels[code] ?? "Weather"
    }

    static func visual(_ weather: CurrentWeather) -> WeatherVisual {
        let code = weather.weatherCode
        let isHot = weather.temperature > 35
        let isDrizzle = drizzleCodes.contains(code)
        let isRain = rainCodes.contains(code)
        let isStorm = stormCodes.contains(code)
        let isHeavyPrecipitation = isRain || isStorm
        let isClear = clearCodes.contains(code)
        let isCloudy = cloudyCodes.contains(code)
        let isSnow = snowCodes.contains(code)
        let isNightCloudy = weather.isDay == 0 && !isRain && isCloudy

        if fogCodes.contains(code) || isMisty(weather) || isNightCloudy {
            return .fog
        }

        if isHot, !isHeavyPrecipitation {
            return .hot
        }

        if !isHeavyPrecipitation, isClear {
            return clearVisual(for: weather)
        }

        if !isHeavyPrecipitation, isCloudy || isSnow {
            return .cloudy
        }

        if !isHeavyPrecipitation, isDrizzle {
            return .drizzle
        }

        if isStorm || weather.windSpeed >= 38 {
            return .storm
        }

        if isRain {
            return .rain
        }

        return .cloudy
    }

    private static func isMisty(_ weather: CurrentWeather) -> Bool {
        !rainCodes.contains(weather.weatherCode)
            && !stormCodes.contains(weather.weatherCode)
            && !snowCodes.contains(weather.weatherCode)
            && !clearCodes.contains(weather.weatherCode)
            && weather.relativeHumidity >= 88
            && weather.cloudCover >= 85
            && weather.windSpeed <= 14
    }

    private static func isHeavyPrecipitation(_ code: Int) -> Bool {
        rainCodes.contains(code) || stormCodes.contains(code)
    }

    private static func clearVisual(for weather: CurrentWeather) -> WeatherVisual {
        guard let hour = weather.hour else {
            return .clearMorning
        }

        return hour >= 15 ? .clearEvening : .clearMorning
    }
}

struct CurrentWeather: Codable, Equatable, Sendable {
    let temperature: Double
    let weatherCode: Int
    let windSpeed: Double
    let relativeHumidity: Double
    let cloudCover: Double
    let isDay: Int
    let time: String?

    var hour: Int? {
        guard let time, time.count >= 13 else {
            return nil
        }

        let hourStart = time.index(time.startIndex, offsetBy: 11)
        let hourEnd = time.index(hourStart, offsetBy: 2)
        return Int(time[hourStart..<hourEnd])
    }
}

enum CityRanking {
    static func sorted(_ cities: [City], query: String, userCoordinates: Coordinates?) -> [City] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rankingCoordinates = userCoordinates ?? City.defaultCity.coordinates

        return cities.sorted { first, second in
            let firstExact = isExactMatch(first, normalizedQuery: normalizedQuery, originalQuery: query) ? 0 : 1
            let secondExact = isExactMatch(second, normalizedQuery: normalizedQuery, originalQuery: query) ? 0 : 1

            if firstExact != secondExact {
                return firstExact < secondExact
            }

            let popularityDifference = popularityScore(second, query: query) - popularityScore(first, query: query)
            if abs(popularityDifference) > 1 {
                return popularityDifference < 0
            }

            return distanceKm(from: rankingCoordinates, to: first.coordinates)
                < distanceKm(from: rankingCoordinates, to: second.coordinates)
        }
    }

    static func distanceKm(from start: Coordinates, to end: Coordinates) -> Double {
        let radiusKm = 6371.0
        let latDistance = degreesToRadians(end.latitude - start.latitude)
        let lonDistance = degreesToRadians(end.longitude - start.longitude)
        let startLat = degreesToRadians(start.latitude)
        let endLat = degreesToRadians(end.latitude)
        let angle = pow(sin(latDistance / 2), 2)
            + cos(startLat) * cos(endLat) * pow(sin(lonDistance / 2), 2)

        return radiusKm * 2 * atan2(sqrt(angle), sqrt(1 - angle))
    }

    private static func popularityScore(_ city: City, query: String) -> Double {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedName = city.name.lowercased()
        let normalizedCountry = city.country.lowercased()
        var score = log10(Double((city.population ?? 0) + 1))

        if isExactMatch(city, normalizedQuery: normalizedQuery, originalQuery: query) {
            score += 3
        }

        if IndianPlaceNameAliases.isRenameQuery(query), city.countryCode == "IN" || normalizedCountry == "india" {
            score += 2
        }

        if normalizedName == "bali", normalizedCountry == "indonesia" {
            score += 6
        }

        return score
    }

    private static func isExactMatch(_ city: City, normalizedQuery: String, originalQuery: String) -> Bool {
        city.name.lowercased() == normalizedQuery || IndianPlaceNameAliases.matches(city, query: originalQuery)
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
