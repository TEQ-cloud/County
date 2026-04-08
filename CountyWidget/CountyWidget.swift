//
//  CountyWidget.swift
//  CountyWidget
//
//  Created by Quinten de Haard on 19/03/2026.
//

import WidgetKit
import SwiftUI

struct CountyEntry: TimelineEntry {
    let date: Date
    let countdowns: [CountdownEntry]
}

struct CountyProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountyEntry {
        CountyEntry(date: .now, countdowns: [
            CountdownEntry(name: "New Year", date: Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 1))!),
            CountdownEntry(name: "Birthday", date: Calendar.current.date(byAdding: .day, value: 30, to: .now)!),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (CountyEntry) -> Void) {
        let countdowns = SharedData.load()
        completion(CountyEntry(date: .now, countdowns: countdowns))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountyEntry>) -> Void) {
        let countdowns = SharedData.load()
        let entry = CountyEntry(date: .now, countdowns: countdowns)
        let nextUpdate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CountyWidgetEntryView: View {
    var entry: CountyEntry
    @Environment(\.widgetFamily) var family

    var maxItems: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        case .systemLarge: return 8
        default: return 3
        }
    }

    var body: some View {
        if entry.countdowns.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No countdowns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.countdowns.prefix(maxItems).enumerated()), id: \.element.id) { _, countdown in
                    HStack {
                        Text(countdown.name)
                            .font(.system(.callout, weight: .semibold))
                            .lineLimit(1)
                        Spacer()
                        Text("\(countdown.daysLeft)d")
                            .font(.system(.callout, design: .rounded, weight: .bold))
                            .foregroundStyle(countdown.daysLeft <= 7 ? .red : .primary)
                    }
                    if countdown.id != entry.countdowns.prefix(maxItems).last?.id {
                        Divider()
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
    }
}

struct CountyWidget: Widget {
    let kind = "CountyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountyProvider()) { entry in
            CountyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Countdowns")
        .description("See your upcoming countdowns at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    CountyWidget()
} timeline: {
    CountyEntry(date: .now, countdowns: [
        CountdownEntry(name: "New Year", date: Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 1))!),
        CountdownEntry(name: "Birthday", date: Calendar.current.date(byAdding: .day, value: 5, to: .now)!),
        CountdownEntry(name: "Holiday", date: Calendar.current.date(byAdding: .day, value: 45, to: .now)!),
    ])
}
