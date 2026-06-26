import SwiftUI

struct FeelsWatchContentView: View {
    private let snapshot = UserDefaultsWeatherStore.loadSharedSnapshot()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(snapshot.city.displayName)
                .font(.headline)
                .lineLimit(1)
            Text("\(snapshot.temperatureText)°")
                .font(.system(size: 38, weight: .bold, design: .rounded))
            Text(snapshot.conditionText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

#Preview {
    FeelsWatchContentView()
}
