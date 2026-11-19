import SwiftUI
import WidgetKit

// IronPath "This week" widget. The app (lib/widget_bridge.dart) writes the
// week's state into the shared App Group after every save; this extension
// only draws it. Labels arrive already localised from the app.
//
// Xcode: File ▸ New ▸ Target ▸ Widget Extension, name it IronPathWidget,
// replace the generated Swift with this file, and give both Runner and the
// extension the App Group below (Signing & Capabilities ▸ App Groups).

private let appGroup = "group.io.github.danielez18.ironpath"

struct WeekEntry: TimelineEntry {
  let date: Date
  let done: Int
  let total: Int
  let trained: [Bool]
  let planned: [Bool]
  let today: Int // 0 = Monday
  let labels: [String]
  let weekLabel: String
  let nextLabel: String
  let nextTitle: String
  /// The app's accent (its colour theme), light and dark, as ARGB.
  var accentLight: Int? = nil
  var accentDark: Int? = nil

  /// The accent to draw with: the app's own, Sage until the app has run.
  var accent: Color {
    guard let light = accentLight, let dark = accentDark else { return sage }
    return Color(UIColor { tc in
      uiColor(argb: tc.userInterfaceStyle == .dark ? dark : light)
    })
  }

  static let sample = WeekEntry(
    date: Date(), done: 2, total: 4,
    trained: [true, false, true, false, false, false, false],
    planned: [false, false, false, true, true, false, false],
    today: 2, labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    weekLabel: "This week", nextLabel: "Up next", nextTitle: "Upper Day")
}

struct WeekProvider: TimelineProvider {
  func placeholder(in context: Context) -> WeekEntry { .sample }

  func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
    completion(context.isPreview ? .sample : load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
    // redraw at midnight so "today" moves even if the app isn't opened
    let tomorrow = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86_400)
    completion(Timeline(entries: [load()], policy: .after(tomorrow)))
  }

  private func load() -> WeekEntry {
    let d = UserDefaults(suiteName: appGroup)
    let now = Date()
    var cal = Calendar.current
    cal.firstWeekday = 2 // Monday
    let today = (cal.component(.weekday, from: now) + 5) % 7
    let weekStart = cal.date(byAdding: .day, value: -today, to: cal.startOfDay(for: now))!
    let updated = Date(timeIntervalSince1970: (d?.double(forKey: "updated_at") ?? 0) / 1000)
    // a week that ended since the app last ran shows as a fresh week
    let stale = updated < weekStart
    let done = stale ? 0 : (d?.integer(forKey: "week_done") ?? 0)
    let total = d?.integer(forKey: "week_total") ?? 0
    let flags = stale ? "0000000" : (d?.string(forKey: "week_days") ?? "0000000")
    let trained = (0..<7).map { i -> Bool in
      let s = Array(flags)
      return i < s.count && s[i] == "1"
    }
    var planned = [Bool](repeating: false, count: 7)
    var remaining = max(0, min(7, total - done))
    if today < 7 {
      for i in today..<7 where remaining > 0 && !trained[i] {
        planned[i] = true
        remaining -= 1
      }
    }
    let labels = (d?.string(forKey: "day_labels") ?? "Mon|Tue|Wed|Thu|Fri|Sat|Sun")
      .components(separatedBy: "|")
    return WeekEntry(
      date: now, done: done, total: total, trained: trained, planned: planned,
      today: today, labels: labels,
      weekLabel: d?.string(forKey: "label_week") ?? "This week",
      nextLabel: d?.string(forKey: "label_next") ?? "Up next",
      nextTitle: stale ? "" : (d?.string(forKey: "next_title") ?? ""),
      accentLight: d?.object(forKey: "accent_light") == nil
        ? nil : d?.integer(forKey: "accent_light"),
      accentDark: d?.object(forKey: "accent_dark") == nil
        ? nil : d?.integer(forKey: "accent_dark"))
  }
}

private func uiColor(argb value: Int) -> UIColor {
  let u = UInt32(truncatingIfNeeded: value)
  return UIColor(
    red: CGFloat((u >> 16) & 0xFF) / 255,
    green: CGFloat((u >> 8) & 0xFF) / 255,
    blue: CGFloat(u & 0xFF) / 255,
    alpha: 1)
}

/// The default theme's sage accent, in both appearances.
private let sage = Color(UIColor { tc in
  tc.userInterfaceStyle == .dark
    ? UIColor(red: 0.56, green: 0.69, blue: 0.60, alpha: 1)
    : UIColor(red: 0.37, green: 0.50, blue: 0.42, alpha: 1)
})

struct DayDot: View {
  let trained: Bool
  let planned: Bool
  let today: Bool
  var size: CGFloat = 20
  var accent: Color = sage

  var body: some View {
    ZStack {
      if trained {
        Circle().fill(accent)
        Image(systemName: "checkmark")
          .font(.system(size: size * 0.5, weight: .bold))
          .foregroundStyle(.white)
      } else {
        Circle().strokeBorder(
          planned ? accent.opacity(0.55) : Color.secondary.opacity(0.3),
          lineWidth: planned ? 2 : 1.5)
        if today { Circle().fill(accent).frame(width: size * 0.34, height: size * 0.34) }
      }
    }
    .frame(width: size, height: size)
    .widgetAccentable()
  }
}

struct WeekRow: View {
  let entry: WeekEntry
  var dot: CGFloat = 20

  var body: some View {
    HStack(spacing: 0) {
      ForEach(0..<7, id: \.self) { i in
        VStack(spacing: 4) {
          DayDot(
            trained: entry.trained[i], planned: entry.planned[i], today: i == entry.today,
            size: dot, accent: entry.accent)
          Text(i < entry.labels.count ? entry.labels[i] : "")
            .font(.system(size: 10, weight: i == entry.today ? .bold : .medium))
            .foregroundStyle(i == entry.today ? .primary : .secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
      }
    }
  }
}

struct WeekWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: WeekEntry

  private var progress: String {
    entry.total > 0 ? "\(entry.done) / \(entry.total)" : "\(entry.done)"
  }

  var body: some View {
    switch family {
    case .accessoryCircular:
      Gauge(value: Double(entry.done), in: 0...Double(max(entry.total, 1))) {
        Image(systemName: "figure.strengthtraining.traditional")
      } currentValueLabel: {
        Text("\(entry.done)").font(.system(.title3, weight: .bold))
      }
      .gaugeStyle(.accessoryCircularCapacity)
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 4) {
        Text("\(entry.weekLabel) · \(progress)").font(.headline)
        HStack(spacing: 5) {
          ForEach(0..<7, id: \.self) { i in
            DayDot(
              trained: entry.trained[i], planned: entry.planned[i], today: i == entry.today,
              size: 12, accent: entry.accent)
          }
        }
      }
    case .systemMedium:
      VStack(alignment: .leading, spacing: 10) {
        header
        WeekRow(entry: entry, dot: 22)
        if !entry.nextTitle.isEmpty {
          Text("\(entry.nextLabel) · \(entry.nextTitle)")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    default:
      VStack(alignment: .leading, spacing: 10) {
        header
        WeekRow(entry: entry, dot: 14)
      }
    }
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(entry.weekLabel).font(.system(size: 14, weight: .semibold))
      Spacer()
      Text(progress)
        .font(.system(size: 22, weight: .heavy, design: .rounded))
        .foregroundStyle(entry.accent)
        .widgetAccentable()
    }
  }
}

struct IronPathWidget: Widget {
  let kind = "IronPathWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WeekProvider()) { entry in
      WeekWidgetView(entry: entry)
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
    .configurationDisplayName("This week")
    .description("Your workouts this week, day by day.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
  }
}

@main
struct IronPathWidgetBundle: WidgetBundle {
  var body: some Widget { IronPathWidget() }
}
