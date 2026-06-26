# Surface TODO

Work through these in order: preliminary checks first, then one surface at a time.

## Priority Order

1. iOS app
2. Shared weather data and mapping
3. iOS widget
4. watchOS
5. iPad polish
6. Mac app and macOS widget

## Preliminary Checks And Fixes

- [x] Confirm Xcode can parse the project after adding new targets.
- [x] Confirm the main iOS app builds with the embedded iOS widget target.
- [x] Confirm the macOS widget target builds.
- [x] Confirm the watch target builds.
- [x] Run the existing weather logic tests.
- [x] Split weather logic into a UI-free package target or adjust the package manifest so SwiftPM tests do not compile iOS-only SwiftUI views as macOS code.
- [ ] Promote `weather-code-mapping.md` into a human-readable spec backed by a machine-readable `weather-code-mapping.json` manifest.
- [ ] Verify bundle identifiers, signing team, and provisioning profiles for all new targets.
- [ ] Re-check App Store Connect screenshot/icon requirements before final submission; device buckets change over time.

## Store Publishing Checklist

Use this as the release inventory for each App Store surface.

### Shared App Store Connect

- [ ] Apple Developer Program membership is active.
- [ ] App Store Connect app record exists for `feels.fyi`.
- [ ] Bundle IDs, App Groups, widget extension IDs, watch app ID, and future macOS ID are registered in Certificates, Identifiers & Profiles.
- [ ] Automatic signing works for Debug and Release, or manual profiles are created for each target.
- [ ] App privacy answers are completed for location, network/weather API usage, diagnostics, and any analytics.
- [ ] Age rating questionnaire is completed.
- [ ] Export compliance/encryption questionnaire is completed for HTTPS/networking.
- [ ] Support URL, marketing URL, and privacy policy URL are live on `feels.fyi`.
- [ ] Copyright, category, availability, pricing, and release option are set.
- [ ] Review notes explain weather provider, location usage, fallback behavior, and any test account/setup needs.
- [ ] TestFlight internal build uploaded and smoke-tested before App Review.

### iOS App Store Assets

- [ ] App icon asset catalog includes all required iPhone/iPad idioms plus a 1024 x 1024 px App Store marketing icon, PNG, no transparency.
- [ ] iPhone screenshots prepared, 1-10 per localization. Primary current bucket: 6.9" display at one accepted portrait size: 1260 x 2736, 1290 x 2796, or 1320 x 2868 px; landscape equivalents: 2736 x 1260, 2796 x 1290, or 2868 x 1320 px.
- [ ] Optional fallback iPhone screenshots prepared if needed: 6.5" display at 1284 x 2778 or 1242 x 2688 px portrait; 2778 x 1284 or 2688 x 1242 px landscape.
- [ ] Optional smaller iPhone screenshots reviewed for scaled appearance: 6.3", 6.1", 5.5", 4.7", and older sizes if App Store Connect asks for them.
- [ ] App preview videos considered only after the static screenshot story is strong; if used, create device-specific previews per App Store Connect specs.
- [ ] Metadata drafted: name, subtitle, description, keywords, promotional text, support URL, marketing URL, privacy policy URL.
- [ ] Location permission purpose copy is final in `Info.plist` and matches the App Review notes.
- [ ] Production weather provider/API-key strategy is decided and release-safe.

### iOS Widget Publishing

- [ ] iOS widget ships inside the iOS app binary; there is no separate App Store listing.
- [ ] Widget extension bundle ID and signing are configured.
- [ ] Widget display name, description, supported families, and placeholder/snapshot content are polished.
- [ ] App Store screenshots include at least one image showing the widget if it is part of the product story.
- [ ] App Review notes mention how the widget gets its weather data and how quickly it refreshes.

### watchOS App Store Assets

- [ ] Decide whether watchOS is shipped as part of the iOS app, a companion watch app, or a separate watch-only app record.
- [ ] Watch app icon set is complete for watchOS and App Store marketing.
- [ ] Apple Watch screenshots prepared, 1-10 per localization, using one consistent size across localizations: 422 x 514 px (Ultra 3), 410 x 502 px (Ultra 2/Ultra), 416 x 496 px (Series 10/11), 396 x 484 px (Series 7/8/9), 368 x 448 px (Series 4/5/6/SE), or 312 x 390 px (Series 3).
- [ ] Watch metadata is added in App Store Connect if watch-specific information is needed.
- [ ] If complications are added, App Review notes explain supported complication families and data refresh behavior.
- [ ] TestFlight install path is verified on paired watch/simulator before review.

### iPad App Store Assets

- [ ] iPad screenshots prepared because the app runs on iPad. Current required bucket: 13" display at 2064 x 2752 or 2048 x 2732 px portrait; 2752 x 2064 or 2732 x 2048 px landscape.
- [ ] Optional iPad screenshots reviewed for scaled appearance: 12.9", 11", 10.5", and 9.7" buckets if App Store Connect asks for them.
- [ ] iPad-specific screenshots show layouts that look intentionally designed, not just enlarged iPhone screens.
- [ ] iPad app icon idioms are complete in the asset catalog.
- [ ] Orientation support or full-screen requirement is resolved before submission.

### Mac App And macOS Widget Store Assets

- [ ] Decide whether to ship a native Mac app, Catalyst app, or no Mac App Store surface yet.
- [ ] If shipping on the Mac App Store, create/register the macOS bundle ID and signing/provisioning setup.
- [ ] Mac app icon asset catalog is complete, including 1024 x 1024 px marketing artwork and smaller macOS icon renditions.
- [ ] Mac screenshots prepared, 1-10 per localization, 16:10 aspect ratio at one accepted size: 1280 x 800, 1440 x 900, 2560 x 1600, or 2880 x 1800 px.
- [ ] macOS widget ships with a Mac host app; a standalone widget target is not enough for App Store distribution.
- [ ] Mac privacy, sandbox, hardened runtime, entitlements, and notarization/distribution settings are verified.
- [ ] Mac metadata and screenshots explain the window/menu-bar/widget behavior clearly.

## Shared Weather Logic

- [x] Bring iOS drizzle, rain, and storm visual mapping into parity with the web mapping.
- [x] Add iOS asset catalog entries for `drizzle.png` and `rain.png`.
- [ ] Add a cross-platform mapping fixture or generated Swift source from `weather-code-mapping.json` so web and iOS cannot drift.
- [x] Decide how widgets/watch should receive live weather data: App Group cache first, with local placeholder fallback until entitlements are registered.
- [x] Add tests for night cloudy, windy, drizzle, rain, storm, and snow fallback precedence.

## iOS App

- [x] Enable iPad support with `TARGETED_DEVICE_FAMILY = 1,2`.
- [ ] Finish the phone-first app experience before polishing secondary surfaces.
- [ ] Confirm the iOS app still matches the latest web weather mapping.
- [ ] Verify search, default city, location permission fallback, and unavailable-weather states.
- [x] Decide whether current weather should be cached for widgets/watch via App Groups.
- [ ] Add/update iOS app screenshots or visual checks for all weather states.

## iOS Widget

- [x] Add the iOS WidgetKit extension target.
- [x] Embed the iOS widget extension in the iOS app bundle.
- [x] Replace placeholder widget data with current weather from a shared cache or provider.
- [ ] Match widget visuals to the app's weather asset mapping.
- [ ] Add small, medium, and any desired lock-screen/accessory widget families.
- [ ] Verify widget previews and timeline refresh behavior.

## watchOS

- [x] Add a watchOS SwiftUI target scaffold.
- [x] Confirm the watchOS target builds.
- [ ] Decide whether this should be a standalone watch app, companion watch app, or legacy-style WatchKit extension pairing.
- [x] Replace placeholder watch content with current weather.
- [ ] Add compact watch-specific layouts for the main temperature, condition, and city.
- [ ] Add complications only after the widget/data-sharing path is settled.
- [ ] Verify build, previews, and install behavior on a watchOS simulator/device.

## iPad Polish

- [ ] Check app icon coverage for iPad idioms and App Store requirements.
- [ ] Audit the main weather readout on iPad portrait, iPad landscape, and Stage Manager sizes.
- [ ] Adjust the search sheet presentation for iPad if the full-height sheet feels too phone-shaped.
- [ ] Verify all weather background assets render correctly on larger iPad aspect ratios.
- [ ] Resolve the iPad orientation warning or intentionally require full screen.

## Mac App And macOS Widget

- [x] Add the macOS WidgetKit extension target.
- [x] Confirm the macOS widget target builds.
- [ ] Add a macOS host app if we want the macOS widget to ship as a normal Mac surface.
- [ ] Decide whether the macOS app should be a native SwiftUI app, Catalyst build, or widget-only companion.
- [x] Replace placeholder widget data with current weather from a shared cache or provider.
- [ ] Adapt the main app experience for menu bar/window/widget expectations on macOS.
- [ ] Tune layouts for macOS widget families and desktop tinting.
- [ ] Verify widget previews on macOS.
