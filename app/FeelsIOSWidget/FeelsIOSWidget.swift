import SwiftUI
import WidgetKit

struct FeelsIOSWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WeatherSnapshot

    var city: String {
        snapshot.city.displayName
    }

    var temperature: String {
        "\(snapshot.temperatureText)°"
    }

    var condition: String {
        snapshot.conditionText
    }
}

struct FeelsIOSWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FeelsIOSWidgetEntry {
        FeelsIOSWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FeelsIOSWidgetEntry) -> Void) {
        completion(FeelsIOSWidgetEntry(date: Date(), snapshot: UserDefaultsWeatherStore.loadSharedSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FeelsIOSWidgetEntry>) -> Void) {
        let entry = FeelsIOSWidgetEntry(date: Date(), snapshot: UserDefaultsWeatherStore.loadSharedSnapshot())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct FeelsIOSWidgetView: View {
    var entry: FeelsIOSWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(entry.snapshot.visual.widgetGradient)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.city)
                    .font(.headline)
                    .lineLimit(1)
                Text(entry.temperature)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                Text(entry.condition)
                    .font(.caption)
                    .lineLimit(2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding()
        }
        .containerBackground(for: .widget) {
            Color(red: 0.52, green: 0.71, blue: 0.82)
        }
    }
}

private extension WeatherVisual {
    var widgetGradient: LinearGradient {
        LinearGradient(
            colors: widgetColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var widgetColors: [Color] {
        switch self {
        case .hot:
            return [Color(red: 0.94, green: 0.96, blue: 0.0), Color(red: 0.97, green: 0.54, blue: 0.12)]
        case .clearMorning:
            return [Color(red: 0.52, green: 0.71, blue: 0.82), Color(red: 0.04, green: 0.56, blue: 0.84)]
        case .clearEvening:
            return [Color(red: 0.04, green: 0.56, blue: 0.84), Color(red: 0.21, green: 0.08, blue: 0.45)]
        case .cloudy:
            return [Color(red: 0.04, green: 0.37, blue: 0.91), Color(red: 0.25, green: 0.46, blue: 0.72)]
        case .fog:
            return [Color(red: 0.23, green: 0.09, blue: 0.36), Color(red: 0.48, green: 0.56, blue: 0.58)]
        case .drizzle:
            return [Color(red: 0.48, green: 0.56, blue: 0.58), Color(red: 0.05, green: 0.37, blue: 0.68)]
        case .rain:
            return [Color(red: 0.23, green: 0.35, blue: 0.69), Color(red: 0.74, green: 0.28, blue: 0.13)]
        case .storm:
            return [Color(red: 0.21, green: 0.08, blue: 0.94), Color(red: 0.05, green: 0.03, blue: 0.18)]
        }
    }
}

struct FeelsIOSWidget: Widget {
    let kind = "FeelsIOSWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FeelsIOSWidgetProvider()) { entry in
            FeelsIOSWidgetView(entry: entry)
        }
        .configurationDisplayName("feels.fyi")
        .description("A quick glance at the current weather.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct FeelsIOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        FeelsIOSWidget()
    }
}
