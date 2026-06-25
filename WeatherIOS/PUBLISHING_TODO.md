# Publishing TODO

- Replace the free Open-Meteo API usage before App Store release if production traffic, support guarantees, rate limits, licensing, or SLA requirements exceed the free service terms.
- Choose and integrate a paid weather provider plan, such as Apple WeatherKit, Tomorrow.io, WeatherAPI.com, AccuWeather, or another provider that fits the launch countries and budget.
- Add provider credentials through a release-safe configuration path. Do not hardcode paid API keys in the iOS app bundle unless the selected provider explicitly supports client-side public keys.
- Enroll in the Apple Developer Program and configure the `fyi.feels.weather` bundle identifier, signing team, certificates, provisioning profiles, App Store Connect app record, privacy nutrition labels, and location permission purpose text.
- Use `feels.fyi` as the public project domain for the app landing page, support URL, and privacy policy URL.
- Create production app icon assets, screenshots, `feels.fyi` support/privacy pages, and App Store review notes.
