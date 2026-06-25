import Foundation
import SwiftUI

struct Coordinates: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

struct City: Codable, Equatable, Identifiable {
    static let defaultCity = City(
        name: "Bangalore",
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

    init(name: String, country: String, latitude: Double, longitude: Double, population: Int? = nil) {
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.population = population
    }

    var coordinates: Coordinates {
        Coordinates(latitude: latitude, longitude: longitude)
    }

    var displayName: String {
        country.isEmpty ? name : "\(name), \(country)"
    }
}

enum WeatherVisual: String, Codable {
    case hot
    case clearMorning
    case clearEvening
    case cloudy
    case fog
    case rain

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
        case .rain:
            return "heavy-rain-and-wind-ios"
        }
    }

    var fallbackColor: Color {
        switch self {
        case .hot:
            return Color(red: 0.94, green: 0.96, blue: 0.0)
        case .clearMorning:
            return Color(red: 0.52, green: 0.71, blue: 0.82)
        case .clearEvening:
            return Color(red: 0.04, green: 0.56, blue: 0.84)
        case .cloudy:
            return Color(red: 0.04, green: 0.37, blue: 0.91)
        case .fog:
            return Color(red: 0.23, green: 0.09, blue: 0.36)
        case .rain:
            return Color(red: 0.21, green: 0.08, blue: 0.94)
        }
    }

}

enum WeatherRules {
    static let clearCodes: Set<Int> = [0, 1]
    static let cloudyCodes: Set<Int> = [2, 3]
    static let fogCodes: Set<Int> = [45, 48]
    static let rainCodes: Set<Int> = [
        51, 53, 55, 56, 57, 61, 63, 65, 66, 67,
        80, 81, 82, 95, 96, 99
    ]

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

        if weather.windSpeed >= 38, !rainCodes.contains(code) {
            return "Windy"
        }

        return labels[code] ?? "Weather"
    }

    static func visual(_ weather: CurrentWeather) -> WeatherVisual {
        let code = weather.weatherCode
        let isHot = weather.temperature > 35
        let isRain = rainCodes.contains(code) || code >= 95
        let isClear = clearCodes.contains(code)
        let isCloudy = cloudyCodes.contains(code)
        let isNightCloudy = weather.isDay == 0 && !isRain && isCloudy

        if fogCodes.contains(code) || isMisty(weather) || isNightCloudy {
            return .fog
        }

        if isHot, !isRain {
            return .hot
        }

        if !isHot, !isRain, isClear {
            return clearVisual(for: weather)
        }

        if !isHot, !isRain, isCloudy {
            return .cloudy
        }

        return .rain
    }

    private static func isMisty(_ weather: CurrentWeather) -> Bool {
        !rainCodes.contains(weather.weatherCode)
            && !clearCodes.contains(weather.weatherCode)
            && weather.relativeHumidity >= 88
            && weather.cloudCover >= 85
            && weather.windSpeed <= 14
    }

    private static func clearVisual(for weather: CurrentWeather) -> WeatherVisual {
        guard let hour = weather.hour else {
            return .clearMorning
        }

        return hour >= 15 ? .clearEvening : .clearMorning
    }
}

enum CityRanking {
    static func sorted(_ cities: [City], query: String, userCoordinates: Coordinates?) -> [City] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rankingCoordinates = userCoordinates ?? City.defaultCity.coordinates

        return cities.sorted { first, second in
            let firstExact = first.name.lowercased() == normalizedQuery ? 0 : 1
            let secondExact = second.name.lowercased() == normalizedQuery ? 0 : 1

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

    private static func popularityScore(_ city: City, query: String) -> Double {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedName = city.name.lowercased()
        let normalizedCountry = city.country.lowercased()
        var score = log10(Double((city.population ?? 0) + 1))

        if normalizedName == normalizedQuery {
            score += 3
        }

        if normalizedName == "bali", normalizedCountry == "indonesia" {
            score += 6
        }

        return score
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

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
