import SwiftUI
import UIKit

// MARK: - Models

/// Represents a single event in the daily schedule.
struct DayEvent: Identifiable, Equatable, Codable {
    /// A unique identifier for the event.
    let id: UUID
    /// The title or name of the event.
    var title: String
    /// The start time of the event, stored as seconds from midnight.
    var startTime: TimeInterval
    /// The duration of the event, stored in seconds.
    var duration: TimeInterval
    /// The color used to display the event tile.
    var color: Color
    
    // Custom coding keys to handle the non-Codable Color type.
    enum CodingKeys: String, CodingKey {
        case id, title, startTime, duration, color
    }
    
    // Custom encoding to convert Color to a Codable format.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(color.toCodable(), forKey: .color)
    }
    
    // Custom decoding to convert from a Codable format back to Color.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        let codableColor = try container.decode(CodableColor.self, forKey: .color)
        color = Color(codableColor)
    }
    
    // Initializer for creating events without decoding.
    init(id: UUID = UUID(), title: String, startTime: TimeInterval, duration: TimeInterval, color: Color) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.color = color
    }
}

/// A Codable representation of a SwiftUI Color.
struct CodableColor: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
}

// Extension to convert Color to and from the CodableColor representation.
extension Color {
    func toCodable() -> CodableColor {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return CodableColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    init(_ codableColor: CodableColor) {
        self.init(.sRGB, red: Double(codableColor.red), green: Double(codableColor.green), blue: Double(codableColor.blue), opacity: Double(codableColor.alpha))
    }
}


// MARK: - Main Content View

/// The main view of the application, displaying the daily schedule.
struct ContentView: View {
    // MARK: - State Properties
    
    /// The array of events for the day.
    @State private var events: [DayEvent] = []
    @State private var currentTime: TimeInterval = 0

    // MARK: - View Constants
    
    /// The height of a single hour in the timeline view.
    private let hourHeight: CGFloat = 80.0
    /// The total number of hours to display in the timeline.
    private let totalHours = 24
    /// The time increment for snapping events, in seconds (15 minutes).
    private let snapIncrement: TimeInterval = 15 * 60

    // MARK: - Body
    
    var body: some View {
        ScrollView {
            // The ZStack layers the event tiles on top of the timeline background.
            ZStack(alignment: .topLeading) {
                // The background timeline view.
                TimelineView()
                    .frame(height: hourHeight * CGFloat(totalHours))

                // Iterate over the events and create a view for each one.
                ForEach($events) { $event in
                    let tileHeight = height(for: event.duration)
                    EventTileView(event: $event, hourHeight: hourHeight, snapIncrement: snapIncrement, saveEvents: saveEvents, tileHeight: tileHeight)
                        // Position the event tile based on its start time.
                        .offset(y: yOffset(for: event.startTime))
                        // Set the height of the tile based on its duration.
                        .frame(height: tileHeight)
                        // Add padding to avoid overlapping the time labels.
                        .padding(.leading, 60)
                }
                
                CurrentTimeIndicator(hourHeight: hourHeight)
                    .offset(y: yOffset(for: currentTime))
            }
        }
        .navigationTitle("Today's Plan")
        .onAppear(perform: setup)
    }

    // MARK: - Helper Functions
    
    private func setup() {
        loadEvents()
        // Set up a timer to update the current time every minute.
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateCurrentTime()
        }
        updateCurrentTime()
    }
    
    private func updateCurrentTime() {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        currentTime = TimeInterval(components.hour! * 3600 + components.minute! * 60)
    }
    
    /// Calculates the vertical offset for an event tile.
    /// - Parameter startTime: The start time of the event.
    /// - Returns: The vertical offset in points.
    private func yOffset(for startTime: TimeInterval) -> CGFloat {
        let hours = startTime / 3600
        return CGFloat(hours) * hourHeight
    }
    
    /// Calculates the height for an event tile.
    /// - Parameter duration: The duration of the event in seconds.
    /// - Returns: The height of the tile in points.
    private func height(for duration: TimeInterval) -> CGFloat {
        let hours = duration / 3600
        return CGFloat(hours) * hourHeight
    }
    
    // MARK: - Data Persistence
    
    /// Saves the current events to UserDefaults.
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "events")
        }
    }
    
    /// Loads events from UserDefaults, or uses sample data if none are found.
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "events") {
            if let decoded = try? JSONDecoder().decode([DayEvent].self, from: data) {
                events = decoded
                return
            }
        }
        // If no saved data is found, load the sample data.
        events = [
            DayEvent(title: "Morning Standup", startTime: 9 * 3600, duration: 1800, color: .blue),
            DayEvent(title: "Design Review", startTime: 11 * 3600, duration: 1800, color: .green),
            DayEvent(title: "Lunch", startTime: 12.5 * 3600, duration: 3600, color: .orange),
            DayEvent(title: "Focused Work", startTime: 14 * 3600, duration: 7200, color: .purple),
            DayEvent(title: "Team Sync", startTime: 16.5 * 3600, duration: 1800, color: .teal)
        ]
    }
}

// MARK: - Subviews

/// A view that draws the background of the timeline, including the time labels and hour lines.
struct TimelineView: View {
    private let hourHeight: CGFloat = 80.0
    private let totalHours = 24

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            TimeLabelsView()
                .frame(width: 60)
            
            HourLinesView()
        }
    }
}

/// A view that displays the time labels for each hour of the day.
struct TimeLabelsView: View {
    private let hourHeight: CGFloat = 80.0
    private let totalHours = 24

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<totalHours, id: \.self) { hour in
                Text(timeString(for: hour))
                    .font(.caption)
                    .frame(height: hourHeight, alignment: .top)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Formats the hour into a 12-hour time string (e.g., "9 AM").
    /// - Parameter hour: The hour to format (0-23).
    /// - Returns: A formatted time string.
    private func timeString(for hour: Int) -> String {
        let ampm = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(displayHour) \(ampm)"
    }
}

/// A view that draws the horizontal lines for each hour of the day.
struct HourLinesView: View {
    private let hourHeight: CGFloat = 80.0
    private let totalHours = 24

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<totalHours, id: \.self) { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                Spacer()
            }
        }
    }
}

/// A view that displays a single event tile.
struct EventTileView: View {
    @Binding var event: DayEvent
    let hourHeight: CGFloat
    let snapIncrement: TimeInterval
    let saveEvents: () -> Void
    let tileHeight: CGFloat
    
    enum DragType {
        case inactive, moving, resizingTop, resizingBottom
    }
    
    @State private var dragType: DragType = .inactive
    @State private var initialEvent: DayEvent?
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let fineSnapIncrement: TimeInterval = 60 // 1 minute
    private let velocityThreshold: CGFloat = 100 // Threshold for slow vs. fast drag

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(event.color.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 4) {
                if tileHeight >= 20 {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                if tileHeight >= 40 {
                    Text("\(formattedTime(event.startTime)) - \(formattedTime(event.startTime + event.duration))")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(8)
        }
        .padding(.trailing, 10)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    if dragType == .inactive {
                        feedbackGenerator.impactOccurred()
                        initialEvent = event
                        
                        let location = gesture.startLocation
                        if location.y < 15 {
                            dragType = .resizingTop
                        } else if location.y > tileHeight - 15 {
                            dragType = .resizingBottom
                        } else {
                            dragType = .moving
                        }
                    }
                    
                    guard let initialEvent = initialEvent else { return }

                    switch dragType {
                    case .moving:
                        let timeOffset = (gesture.translation.height / hourHeight) * 3600
                        event.startTime = initialEvent.startTime + timeOffset
                    case .resizingTop:
                        let timeOffset = (gesture.translation.height / hourHeight) * 3600
                        let newStartTime = initialEvent.startTime + timeOffset
                        let durationOffset = initialEvent.startTime - newStartTime
                        let newDuration = initialEvent.duration + durationOffset
                        
                        if newDuration >= snapIncrement {
                            event.startTime = newStartTime
                            event.duration = newDuration
                        }
                    case .resizingBottom:
                        let timeOffset = (gesture.translation.height / hourHeight) * 3600
                        let newDuration = initialEvent.duration + timeOffset
                        if newDuration >= snapIncrement {
                            event.duration = newDuration
                        }
                    case .inactive:
                        break
                    }
                }
                .onEnded { gesture in
                    guard let initialEvent = initialEvent else { return }
                    
                    let velocity = gesture.predictedEndTranslation.height
                    let currentSnap = abs(velocity) < velocityThreshold ? fineSnapIncrement : snapIncrement

                    switch dragType {
                    case .moving:
                        let timeOffset = (gesture.translation.height / hourHeight) * 3600
                        let newStartTime = initialEvent.startTime + timeOffset
                        event.startTime = round(newStartTime / currentSnap) * currentSnap
                    case .resizingTop:
                        let timeOffset = (gesture.translation.height / hourHeight) * 3600
                        let newStartTime = initialEvent.startTime + timeOffset
                        let snappedStartTime = round(newStartTime / currentSnap) * currentSnap
                        let durationOffset = initialEvent.startTime - snappedStartTime
                        let newDuration = initialEvent.duration + durationOffset
                        
                        if newDuration >= currentSnap {
                            event.startTime = snappedStartTime
                            event.duration = round(newDuration / currentSnap) * currentSnap
                        } else {
                            event.startTime = initialEvent.startTime
                            event.duration = initialEvent.duration
                        }
                    case .resizingBottom:
                        let timeOffset = (gesture.translation.height / hourHeight) * 3600
                        let newDuration = initialEvent.duration + timeOffset
                        let snappedDuration = round(newDuration / currentSnap) * currentSnap
                        
                        if snappedDuration >= currentSnap {
                            event.duration = snappedDuration
                        } else {
                            event.duration = initialEvent.duration
                        }
                    case .inactive:
                        break
                    }
                    
                    dragType = .inactive
                    self.initialEvent = nil
                    saveEvents()
                }
        )
    }
    
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let date = startOfDay.addingTimeInterval(timeInterval)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CurrentTimeIndicator: View {
    let hourHeight: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
        }
    }
}


#Preview {
    NavigationView {
        ContentView()
    }
}
