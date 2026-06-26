# feels.fyi

Native SwiftUI version of the existing web weather app.

Project domain: `feels.fyi`

Default app bundle identifier: `fyi.feels.weather`

## Source Layout

- `FeelsCore/` contains the shared weather models, mapping rules, Open-Meteo service, cache payload, persistence store, and testable app state model.
- `FeelsIOS/` contains the iPhone/iPad SwiftUI shell and views. It compiles the shared core sources through the Xcode project.
- Widget and watch targets read the latest cached `WeatherSnapshot` through `UserDefaultsWeatherStore.loadSharedSnapshot()`. Runtime sharing expects the `group.fyi.feels.weather` App Group to be registered and enabled before release.

## Open In Xcode

Open `FeelsIOS.xcodeproj` and run the `FeelsIOS` target on an iPhone simulator or device after Xcode is installed and selected.

## Preview Plugin Notes

The `build-ios-apps` plugin's simulator-browser preview flow expects an importable Swift package, so this folder also includes `Package.swift`.

When the plugin's XcodeBuildMCP tools are exposed and a simulator UDID is available, point the preview launcher at:

```bash
/Users/trine/Documents/GitHub/feels.fyi/app/Package.swift
```

Use package target:

```bash
FeelsIOS
```

No Xcode installation, simulator boot, or preview rendering was performed during initial creation.
