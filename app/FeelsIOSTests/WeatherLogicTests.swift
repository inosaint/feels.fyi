import Foundation
import XCTest

#if SWIFT_PACKAGE
@testable import FeelsCore
#else
@testable import FeelsIOS
#endif

final class WeatherLogicTests: XCTestCase {
    override func tearDown() {
        URLProtocolMock.handler = nil
        super.tearDown()
    }

    func testClearWeatherUsesClearVisualUnlessHot() {
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 0, temperature: 24)),
            .clearMorning
        )
    }

    func testHotWeatherUsesHotVisualUnlessRaining() {
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 0, temperature: 36)),
            .hot
        )
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 63, temperature: 36)),
            .rain
        )
    }

    func testPrecipitationCodesUseMappedVisuals() {
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 51, temperature: 22)),
            .drizzle
        )
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 63, temperature: 22)),
            .rain
        )
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 95, temperature: 22)),
            .storm
        )
    }

    func testNightCloudyFallsBackToFogVisual() {
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 3, cloudCover: 92, isDay: 0)),
            .fog
        )
    }

    func testSnowAndUnknownCodesUseNonRainFallbacks() {
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 73, temperature: 2)),
            .cloudy
        )
        XCTAssertEqual(
            WeatherRules.conditionLabel(TestWeather.current(weatherCode: 73, temperature: 2)),
            "Snow"
        )
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 999)),
            .cloudy
        )
        XCTAssertEqual(
            WeatherRules.conditionLabel(TestWeather.current(weatherCode: 999)),
            "Weather"
        )
    }

    func testWindyLabelAppliesWhenNotRaining() {
        XCTAssertEqual(
            WeatherRules.conditionLabel(TestWeather.current(weatherCode: 2, windSpeed: 38)),
            "Windy"
        )
        XCTAssertEqual(
            WeatherRules.conditionLabel(TestWeather.current(weatherCode: 63, windSpeed: 42)),
            "Rain"
        )
        XCTAssertEqual(
            WeatherRules.visual(TestWeather.current(weatherCode: 0, temperature: 37, windSpeed: 42)),
            .hot
        )
    }

    func testMistyVisualAppliesBeforeCloudyVisual() {
        let weather = TestWeather.current(
            weatherCode: 3,
            relativeHumidity: 91,
            cloudCover: 94,
            windSpeed: 6
        )

        XCTAssertEqual(WeatherRules.conditionLabel(weather), "Misty")
        XCTAssertEqual(WeatherRules.visual(weather), .fog)
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
        XCTAssertEqual(sorted.dropFirst().first?.country, "United States")
        XCTAssertEqual(sorted.last?.name, "Bangalore Rural")
    }

    func testCityRankingUsesDefaultCoordinatesWhenUserCoordinatesAreMissing() {
        let cities = [
            City(name: "Bangalore", country: "United States", latitude: 44.0, longitude: -93.0),
            City(name: "Bangalore", country: "India", latitude: 12.9716, longitude: 77.5946)
        ]

        let sorted = CityRanking.sorted(cities, query: "Bangalore", userCoordinates: nil)

        XCTAssertEqual(sorted.first?.country, "India")
    }

    func testIndianRenameAliasesIncludeModernSearchVariants() {
        XCTAssertEqual(IndianPlaceNameAliases.searchVariants(for: "Bangalore"), ["Bangalore", "bengaluru"])
        XCTAssertEqual(IndianPlaceNameAliases.searchVariants(for: "mangalore"), ["mangalore", "mangaluru"])
        XCTAssertEqual(IndianPlaceNameAliases.searchVariants(for: "Gurgaon"), ["Gurgaon", "gurugram"])
        XCTAssertEqual(IndianPlaceNameAliases.searchVariants(for: "Goa"), ["Goa", "panjim"])
        XCTAssertEqual(IndianPlaceNameAliases.searchVariants(for: "Panaji"), ["Panaji", "panjim"])
    }

    func testCityRankingTreatsIndianRenameAsExactMatch() {
        let cities = [
            City(name: "Mangalore", country: "Australia", latitude: -42.65, longitude: 147.23334, population: 421, countryCode: "AU"),
            City(name: "Mangalore", country: "Australia", latitude: -36.93333, longitude: 145.18333, population: 186, countryCode: "AU"),
            City(name: "Mangaluru", country: "India", latitude: 12.91723, longitude: 74.85603, population: 499487, countryCode: "IN")
        ]

        let sorted = CityRanking.sorted(cities, query: "Mangalore", userCoordinates: nil)

        XCTAssertEqual(sorted.first?.name, "Mangaluru")
        XCTAssertEqual(sorted.first?.country, "India")
    }

    func testCityRankingPrefersBengaluruForBangaloreSearch() {
        let cities = [
            City(name: "Bangalore Town", country: "Pakistan", latitude: 24.8717, longitude: 67.0839, countryCode: "PK"),
            City(name: "Bengaluru", country: "India", latitude: 12.97194, longitude: 77.59369, population: 8495492, countryCode: "IN")
        ]

        let sorted = CityRanking.sorted(cities, query: "Bangalore", userCoordinates: nil)

        XCTAssertEqual(sorted.first?.name, "Bengaluru")
        XCTAssertEqual(sorted.first?.country, "India")
    }

    func testCityRankingPrefersPanjimForGoaSearch() {
        let cities = [
            City(name: "Goa", country: "Philippines", latitude: 13.6978, longitude: 123.4892, population: 20936, countryCode: "PH"),
            City(name: "Panjim", country: "India", latitude: 15.49574, longitude: 73.82624, population: 70991, countryCode: "IN")
        ]

        let sorted = CityRanking.sorted(cities, query: "Goa", userCoordinates: nil)

        XCTAssertEqual(sorted.first?.name, "Panjim")
        XCTAssertEqual(sorted.first?.country, "India")
    }

    func testFetchWeatherDecodesCurrentForecast() async throws {
        let service = makeService { request in
            XCTAssertEqual(request.url?.host, "api.open-meteo.com")
            return httpResponse(
                url: request.url,
                statusCode: 200,
                body: """
                {
                  "current": {
                    "time": "2026-06-22T10:00",
                    "temperature_2m": 28.4,
                    "weather_code": 1,
                    "wind_speed_10m": 9,
                    "relative_humidity_2m": 61,
                    "cloud_cover": 14,
                    "is_day": 1
                  }
                }
                """
            )
        }

        let weather = try await service.fetchWeather(for: .defaultCity)

        XCTAssertEqual(weather.temperature, 28.4)
        XCTAssertEqual(weather.weatherCode, 1)
        XCTAssertEqual(weather.hour, 10)
    }

    func testFetchWeatherRejectsInvalidHTTPAndMalformedJSON() async throws {
        let failingService = makeService { request in
            httpResponse(url: request.url, statusCode: 500, body: "{}")
        }

        await XCTAssertThrowsErrorAsync {
            try await failingService.fetchWeather(for: .defaultCity)
        }

        let malformedService = makeService { request in
            httpResponse(url: request.url, statusCode: 200, body: "{")
        }

        await XCTAssertThrowsErrorAsync {
            try await malformedService.fetchWeather(for: .defaultCity)
        }
    }

    func testSearchCitiesDecodesEmptyAndDeduplicatedResults() async throws {
        let emptyService = makeService { request in
            httpResponse(url: request.url, statusCode: 200, body: "{}")
        }

        let emptyResults = try await emptyService.searchCities(query: "zz")
        XCTAssertTrue(emptyResults.isEmpty)

        let duplicateService = makeService { request in
            httpResponse(
                url: request.url,
                statusCode: 200,
                body: """
                {
                  "results": [
                    {"name":"Bengaluru","country":"India","country_code":"IN","latitude":12.97194,"longitude":77.59369,"population":8495492},
                    {"name":"Bengaluru","country":"India","country_code":"IN","latitude":12.9719401,"longitude":77.5936901,"population":8495492}
                  ]
                }
                """
            )
        }

        let results = try await duplicateService.searchCities(query: "Bengaluru")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Bengaluru")
    }

    @MainActor
    func testFirstLaunchSuccessLoadsAndCachesSnapshot() async {
        let weather = TestWeather.current(weatherCode: 0, temperature: 31)
        let fetcher = MockWeatherFetcher(result: .success(weather))
        let store = InMemoryWeatherStore()
        let viewModel = WeatherViewModel(
            weatherFetcher: fetcher,
            citySearcher: MockCitySearcher(),
            locationProvider: MockLocationProvider(coordinates: nil),
            persistence: store,
            searchDebounce: .zero
        )

        await viewModel.initialize()

        guard case .loaded(let snapshot) = viewModel.state else {
            return XCTFail("Expected loaded state, got \(viewModel.state)")
        }
        XCTAssertEqual(snapshot.city, .defaultCity)
        XCTAssertEqual(snapshot.temperatureText, "31")
        XCTAssertEqual(store.snapshot, snapshot)
        XCTAssertEqual(fetcher.requestedCities, [.defaultCity])
    }

    @MainActor
    func testLaunchFailureKeepsCachedWeatherStale() async {
        let cached = WeatherSnapshot.fixture(city: .defaultCity, weatherCode: 1, temperature: 29)
        let store = InMemoryWeatherStore(snapshot: cached, selectedCity: .defaultCity)
        let viewModel = WeatherViewModel(
            weatherFetcher: MockWeatherFetcher(result: .failure(MockError.failure)),
            citySearcher: MockCitySearcher(),
            locationProvider: MockLocationProvider(coordinates: nil),
            persistence: store,
            searchDebounce: .zero
        )

        await viewModel.initialize()

        guard case .staleLoaded(let snapshot, let message) = viewModel.state else {
            return XCTFail("Expected stale loaded state, got \(viewModel.state)")
        }
        XCTAssertEqual(snapshot, cached)
        XCTAssertEqual(message, "Weather unavailable")
        XCTAssertEqual(viewModel.temperatureText, cached.temperatureText)
    }

    @MainActor
    func testPermissionDeniedFallsBackToSelectedCity() async {
        let selectedCity = City(name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777)
        let fetcher = MockWeatherFetcher(result: .success(TestWeather.current(weatherCode: 2, temperature: 27)))
        let store = InMemoryWeatherStore(selectedCity: selectedCity)
        let viewModel = WeatherViewModel(
            weatherFetcher: fetcher,
            citySearcher: MockCitySearcher(),
            locationProvider: MockLocationProvider(coordinates: nil),
            persistence: store,
            searchDebounce: .zero
        )

        await viewModel.initialize()

        XCTAssertEqual(fetcher.requestedCities, [selectedCity])
        XCTAssertEqual(viewModel.currentCity, selectedCity)
    }

    @MainActor
    func testCurrentLocationSnapshotDoesNotOverwriteSelectedCity() async {
        let selectedCity = City(name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777)
        let fetcher = MockWeatherFetcher(result: .success(TestWeather.current(weatherCode: 0, temperature: 30)))
        let store = InMemoryWeatherStore(selectedCity: selectedCity)
        let viewModel = WeatherViewModel(
            weatherFetcher: fetcher,
            citySearcher: MockCitySearcher(),
            locationProvider: MockLocationProvider(coordinates: Coordinates(latitude: 12.90, longitude: 77.50)),
            persistence: store,
            searchDebounce: .zero
        )

        await viewModel.initialize()

        XCTAssertEqual(viewModel.currentCity.name, "Current location")
        XCTAssertEqual(store.selectedCity, selectedCity)
        XCTAssertEqual(store.snapshot?.city.name, "Current location")
    }

    @MainActor
    func testCitySelectionSuccessAndFailureStateTransitions() async {
        let city = City(name: "Kolkata", country: "India", latitude: 22.5726, longitude: 88.3639)
        let fetcher = MockWeatherFetcher(result: .success(TestWeather.current(weatherCode: 51, temperature: 26)))
        let store = InMemoryWeatherStore()
        let viewModel = WeatherViewModel(
            weatherFetcher: fetcher,
            citySearcher: MockCitySearcher(),
            persistence: store,
            searchDebounce: .zero
        )

        await viewModel.loadCity(city)
        XCTAssertEqual(viewModel.currentCity, city)
        XCTAssertEqual(store.selectedCity, city)
        XCTAssertEqual(viewModel.currentVisual, .drizzle)

        fetcher.result = .failure(MockError.failure)
        await viewModel.loadCity(.defaultCity)

        guard case .staleLoaded(let snapshot, _) = viewModel.state else {
            return XCTFail("Expected stale weather after failed city load")
        }
        XCTAssertEqual(snapshot.city, city)
    }

    @MainActor
    func testSearchDebounceAndCancellationBehavior() async {
        let searcher = MockCitySearcher(results: [
            City(name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777)
        ])
        let viewModel = WeatherViewModel(
            weatherFetcher: MockWeatherFetcher(result: .success(TestWeather.current())),
            citySearcher: searcher,
            persistence: InMemoryWeatherStore(),
            searchDebounce: .zero
        )

        viewModel.updateSearchQuery("mu")
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(viewModel.searchResults.first?.name, "Mumbai")
        XCTAssertEqual(searcher.queries, ["mu"])

        let slowViewModel = WeatherViewModel(
            weatherFetcher: MockWeatherFetcher(result: .success(TestWeather.current())),
            citySearcher: searcher,
            persistence: InMemoryWeatherStore(),
            searchDebounce: .seconds(30)
        )
        slowViewModel.updateSearchQuery("be")
        slowViewModel.updateSearchQuery("b")

        XCTAssertTrue(slowViewModel.searchResults.isEmpty)
        XCTAssertFalse(slowViewModel.isSearching)
    }

    private func makeService(
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> WeatherService {
        URLProtocolMock.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        return WeatherService(session: URLSession(configuration: configuration))
    }

    private func httpResponse(
        url: URL?,
        statusCode: Int,
        body: String
    ) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: url ?? URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, Data(body.utf8))
    }
}

private final class URLProtocolMock: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: MockError.failure)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class MockWeatherFetcher: WeatherFetching {
    var result: Result<CurrentWeather, Error>
    private(set) var requestedCities: [City] = []

    init(result: Result<CurrentWeather, Error>) {
        self.result = result
    }

    func fetchWeather(for city: City) async throws -> CurrentWeather {
        requestedCities.append(city)
        return try result.get()
    }
}

private final class MockCitySearcher: CitySearching {
    var results: [City]
    var error: Error?
    private(set) var queries: [String] = []

    init(results: [City] = [], error: Error? = nil) {
        self.results = results
        self.error = error
    }

    func searchCities(query: String) async throws -> [City] {
        queries.append(query)
        if let error {
            throw error
        }

        return results
    }
}

private struct MockLocationProvider: LocationProviding {
    let coordinates: Coordinates?

    func requestLocation() async -> Coordinates? {
        coordinates
    }
}

private final class InMemoryWeatherStore: WeatherPersisting {
    var snapshot: WeatherSnapshot?
    var selectedCity: City?

    init(snapshot: WeatherSnapshot? = nil, selectedCity: City? = nil) {
        self.snapshot = snapshot
        self.selectedCity = selectedCity
    }

    func loadSelectedCity() -> City? {
        selectedCity
    }

    func saveSelectedCity(_ city: City) {
        selectedCity = city
    }

    func loadSnapshot() -> WeatherSnapshot? {
        snapshot
    }

    func saveSnapshot(_ snapshot: WeatherSnapshot) {
        self.snapshot = snapshot
    }
}

private enum MockError: Error {
    case failure
}

private enum TestWeather {
    static func current(
        weatherCode: Int = 0,
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

private extension WeatherSnapshot {
    static func fixture(
        city: City,
        weatherCode: Int,
        temperature: Double
    ) -> WeatherSnapshot {
        let weather = TestWeather.current(weatherCode: weatherCode, temperature: temperature)
        return WeatherSnapshot(
            city: city,
            weather: weather,
            visual: WeatherRules.visual(weather),
            capturedAt: Date(timeIntervalSince1970: 1_787_328_000)
        )
    }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw", file: file, line: line)
    } catch {}
}
