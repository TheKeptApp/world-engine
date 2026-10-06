import SwiftUI
import WorldEngine
import WorldEnvironment

/// experience-v1 §5 weather strip (top safe area): condition (icon + text, not colour alone),
/// temperature, precipitation, wind, place, valid time and the data's kind. Demo weather is labeled
/// "Demo"; the Apple Weather attribution slot is reserved for live data (5B).
struct WeatherStrip: View {
    let env: EnvironmentController

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: env.conditionSymbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.title3)
                    .accessibilityHidden(true)
                Text(env.conditionText).font(.subheadline.weight(.semibold))
                if let t = env.temperatureText { Text(t).font(.subheadline) }
                if let p = env.precipitationText { Text(p).font(.footnote) }
                if let w = env.windText { Text(w).font(.footnote) }
                Spacer(minLength: 4)
                Text("Demo")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.yellow.opacity(0.85), in: Capsule())
                    .foregroundStyle(.black)
                    .accessibilityLabel("Demo weather, not observed")
            }
            HStack(spacing: 4) {
                Text(env.locationLabel)
                Text("·")
                Text(env.clockText(env.time))
                if !env.isLive { Text("· preview") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            // Reserved for live data: Apple Weather mark + "Weather data sources" legal link, and
            // the modified-data notice (weather v1 §10). Demo weather carries no Apple branding.
            Text("Apple Weather attribution appears here with live data")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 10)
    }
}

/// experience-v1 §5 time scrubber (above the bottom attribution): local time with zone, the day's
/// sunrise and sunset, day stepping for seasons, and Return to live.
struct TimeScrubber: View {
    let env: EnvironmentController

    var body: some View {
        let day = env.dayStart
        let fraction = min(1, max(0, env.time.timeIntervalSince(day) / 86_400))
        VStack(spacing: 4) {
            HStack {
                Button { env.set(time: env.time.addingTimeInterval(-86_400 * 7)) } label: { Image(systemName: "chevron.left.2") }
                    .accessibilityLabel("Back one week")
                Button { env.set(time: env.time.addingTimeInterval(-86_400)) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Back one day")
                Spacer()
                Text(env.clockText(env.time)).font(.footnote.monospacedDigit().weight(.semibold))
                Spacer()
                Button { env.set(time: env.time.addingTimeInterval(86_400)) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Forward one day")
                Button { env.set(time: env.time.addingTimeInterval(86_400 * 7)) } label: { Image(systemName: "chevron.right.2") }
                    .accessibilityLabel("Forward one week")
            }
            ZStack {
                GeometryReader { geo in
                    let events = env.sunEvents
                    ForEach([events.sunrise, events.sunset].compactMap { $0 }, id: \.self) { t in
                        let x = geo.size.width * min(1, max(0, t.timeIntervalSince(day) / 86_400))
                        Image(systemName: t == events.sunrise ? "sunrise.fill" : "sunset.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .position(x: x, y: 2)
                    }
                }
                .frame(height: 10)
                .offset(y: -12)
                Slider(value: Binding(get: { fraction }, set: { env.set(time: day.addingTimeInterval($0 * 86_400)) }), in: 0...1)
                    .accessibilityLabel("Time of day")
            }
            if !env.isLive {
                Button("Return to live") { env.goLive() }
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 10)
    }
}
