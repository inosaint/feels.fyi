# feels.fyi

Native SwiftUI version of the existing web weather app.

Project domain: `feels.fyi`

Default app bundle identifier: `fyi.feels.weather`

## Open In Xcode

Open `WeatherIOS.xcodeproj` and run the `WeatherIOS` target on an iPhone simulator or device after Xcode is installed and selected.

## Preview Plugin Notes

The `build-ios-apps` plugin's simulator-browser preview flow expects an importable Swift package, so this folder also includes `Package.swift`.

When the plugin's XcodeBuildMCP tools are exposed and a simulator UDID is available, point the preview launcher at:

```bash
/Users/trine/Documents/Codex/Weather/WeatherIOS/Package.swift
```

Use package target:

```bash
WeatherIOS
```

No Xcode installation, simulator boot, or preview rendering was performed during initial creation.
