import XCTest
@testable import WeatherIOS

final class WeatherLogicTests: XCTestCase {
    func testClearWeatherUsesClearVisualUnlessHot() {
        XCTAssertEqual(
            WeatherRules.visual(CurrentWeather.fixture(weatherCode: 0, temperature: 24)),
            .clearMorning
        )
    }

    func testHotWeatherUsesHotVisualUnlessRaining() {
        XCTAssertEqual(
            WeatherRules.visual(CurrentWeather.fixture(weatherCode: 0, temperature: 36)),
            .hot
        )
        XCTAssertEqual(
            WeatherRules.visual(CurrentWeather.fixture(weatherCode: 63, temperature: 36)),
            .rain
        )
    }

    func testRainAndStormCodesUseRainVisual() {
        XCTAssertEqual(
            WeatherRules.visual(CurrentWeather.fixture(weatherCode: 61, temperature: 22)),
            .rain
        )
        XCTAssertEqual(
            WeatherRules.visual(CurrentWeather.fixture(weatherCode: 95, temperature: 22)),
            .rain
        )
    }

    func testWindyLabelAppliesWhenNotRaining() {
        XCTAssertEqual(
            WeatherRules.conditionLabel(CurrentWeather.fixture(weatherCode: 2, windSpeed: 38)),
            "Windy"
        )
        XCTAssertEqual(
            WeatherRules.conditionLabel(CurrentWeather.fixture(weatherCode: 63, windSpeed: 42)),
            "Rain"
        )
    }

    func testCityRankingPrefersExactMatchThenDistance() {
        let userCoordinates = Coordinates(latitude: 12.9716, longitude: 77.5946)
        let cities = [
            City(name: "Bangalore Rural", country: "India", latitude: 13.2257, longitude: 77.5750),
            City(name: "Bangalore", country: "India", latitude: 12.9716, longitude: 77.5946),
            City(name: "Bangalore", country: "United States", latitude: 44.0, longitude: -93.0)
        ]

        let sorted = CityRanking.sorted(cities, query: "Bangalore", userCoordinates: userCoordinates)

        XCTAssertEqual(sorted.first?.country, "India")
        XCTAssertEqual(sorted.last?.country, "United States")
    }
}

private extension CurrentWeather {
    static func fixture(
        weatherCode: Int,
        temperature: Double = 24,
        windSpeed: Double = 0,
        relativeHumidity: Double = 50,
        cloudCover: Double = 0,
        isDay: Int = 1,
        time: String? = "2026-06-22T10:00"
    ) -> CurrentWeather {
        CurrentWeather(
            temperature: temperature,
            weatherCode: weatherCode,
            windSpeed: windSpeed,
            relativeHumidity: relativeHumidity,
            cloudCover: cloudCover,
            isDay: isDay,
            time: time
        )
    }
}
