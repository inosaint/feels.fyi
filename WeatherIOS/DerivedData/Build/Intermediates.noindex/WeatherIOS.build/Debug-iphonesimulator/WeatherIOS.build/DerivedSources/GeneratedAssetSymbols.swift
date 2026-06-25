import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "LaunchBackground" asset catalog color resource.
    static let launchBackground = DeveloperToolsSupport.ColorResource(name: "LaunchBackground", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "clear-sky" asset catalog image resource.
    static let clearSky = DeveloperToolsSupport.ImageResource(name: "clear-sky", bundle: resourceBundle)

    /// The "clear-sky-evening" asset catalog image resource.
    static let clearSkyEvening = DeveloperToolsSupport.ImageResource(name: "clear-sky-evening", bundle: resourceBundle)

    /// The "clear-sky-evening-ios" asset catalog image resource.
    static let clearSkyEveningIos = DeveloperToolsSupport.ImageResource(name: "clear-sky-evening-ios", bundle: resourceBundle)

    /// The "clear-sky-morning" asset catalog image resource.
    static let clearSkyMorning = DeveloperToolsSupport.ImageResource(name: "clear-sky-morning", bundle: resourceBundle)

    /// The "clear-sky-morning-ios" asset catalog image resource.
    static let clearSkyMorningIos = DeveloperToolsSupport.ImageResource(name: "clear-sky-morning-ios", bundle: resourceBundle)

    /// The "cloudy" asset catalog image resource.
    static let cloudy = DeveloperToolsSupport.ImageResource(name: "cloudy", bundle: resourceBundle)

    /// The "cloudy-ios" asset catalog image resource.
    static let cloudyIos = DeveloperToolsSupport.ImageResource(name: "cloudy-ios", bundle: resourceBundle)

    /// The "fog" asset catalog image resource.
    static let fog = DeveloperToolsSupport.ImageResource(name: "fog", bundle: resourceBundle)

    /// The "fog-ios" asset catalog image resource.
    static let fogIos = DeveloperToolsSupport.ImageResource(name: "fog-ios", bundle: resourceBundle)

    /// The "heavy-rain-and-wind" asset catalog image resource.
    static let heavyRainAndWind = DeveloperToolsSupport.ImageResource(name: "heavy-rain-and-wind", bundle: resourceBundle)

    /// The "heavy-rain-and-wind-ios" asset catalog image resource.
    static let heavyRainAndWindIos = DeveloperToolsSupport.ImageResource(name: "heavy-rain-and-wind-ios", bundle: resourceBundle)

    /// The "hot35" asset catalog image resource.
    static let hot35 = DeveloperToolsSupport.ImageResource(name: "hot35", bundle: resourceBundle)

    /// The "hot35-ios" asset catalog image resource.
    static let hot35Ios = DeveloperToolsSupport.ImageResource(name: "hot35-ios", bundle: resourceBundle)

}

