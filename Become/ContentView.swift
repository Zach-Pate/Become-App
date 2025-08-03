import SwiftUI

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
        let colorName = try container.decode(String.self, forKey: .color)
        color = Color(colorName)
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

// Extension to convert Color to and from a simple string representation.
extension Color {
    func toCodable() -> String {
        switch self {
        case .blue: return "blue"
        case .green: return "green"
        case .orange: return "orange"
        case .purple: return "purple"
        case .teal: return "teal"
        default: return "gray"
        }
    }
    
    init(_ colorName: String) {
        switch colorName {
        case "blue": self = .blue
        case "green": self = .green
        case "orange": self = .orange
        case "purple": self = .purple
        case "teal": self = .teal
        default: self = .gray
        }
    }
}


// MARK: - Main Content View

/// The main view of the application, displaying the daily schedule.
struct ContentView: View {
    // MARK: - State Properties
    
    /// The array of events for the day.
    @State private var events: [DayEvent] = []
    /// The event currently being dragged by the user.
    @State private var draggingEvent: DayEvent?
    /// The offset of the drag gesture.
    @State private var dragOffset: CGSize = .zero

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
                    EventTileView(event: $event, hourHeight: hourHeight, snapIncrement: snapIncrement, saveEvents: saveEvents)
                        // Position the event tile based on its start time and any drag offset.
                        .offset(y: yOffset(for: event))
                        // Set the height of the tile based on its duration.
                        .frame(height: height(for: event.duration))
                        // Add padding to avoid overlapping the time labels.
                        .padding(.leading, 60)
                        // Add a drag gesture to allow moving the event.
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    // When the drag starts, record the event being dragged.
                                    if draggingEvent == nil {
                                        draggingEvent = event
                                    }
                                    // Update the drag offset as the user moves their finger.
                                    dragOffset = gesture.translation
                                }
                                .onEnded { gesture in
                                    // When the drag ends, update the event's start time.
                                    if let draggingEvent = draggingEvent {
                                        // Calculate the time offset based on the drag distance.
                                        let timeOffset = Double(gesture.translation.height / hourHeight) * 3600
                                        let newStartTime = draggingEvent.startTime + timeOffset
                                        
                                        // Snap the new start time to the nearest 15-minute increment.
                                        let snappedStartTime = round(newStartTime / snapIncrement) * snapIncrement
                                        
                                        // Find the event in the array and update its start time.
                                        if let index = events.firstIndex(where: { $0.id == draggingEvent.id }) {
                                            events[index].startTime = snappedStartTime
                                            saveEvents()
                                        }
                                    }
                                    // Reset the dragging state.
                                    draggingEvent = nil
                                    dragOffset = .zero
                                }
                        )
                }
            }
        }
        .navigationTitle("Today's Plan")
        .onAppear(perform: loadEvents)
    }

    // MARK: - Helper Functions
    
    /// Calculates the vertical offset for an event tile.
    /// - Parameter event: The event to calculate the offset for.
    /// - Returns: The vertical offset in points.
    private func yOffset(for event: DayEvent) -> CGFloat {
        // If this event is being dragged, calculate the offset based on the drag position.
        if event.id == draggingEvent?.id {
            let hours = (draggingEvent?.startTime ?? 0) / 3600
            return CGFloat(hours) * hourHeight + dragOffset.height
        }
        // Otherwise, calculate the offset based on the event's start time.
        let hours = event.startTime / 3600
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
    
    @State private var isResizingTop = false
    @State private var isResizingBottom = false
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack(alignment: .topLeading) {
            // The background of the tile.
            RoundedRectangle(cornerRadius: 8)
                .fill(event.color.opacity(0.8))
            
            // The content of the tile.
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(formattedTime(event.startTime)) - \(formattedTime(event.startTime + event.duration))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(8)
            
            // Top resize handle
            VStack {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(height: 4)
                    .cornerRadius(2)
                    .padding(.horizontal, 20)
                Spacer()
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if !isResizingTop {
                            isResizingTop = true
                            feedbackGenerator.impactOccurred()
                        }
                        let timeOffset = Double(gesture.translation.height / hourHeight) * 3600
                        let newStartTime = event.startTime + timeOffset
                        let snappedStartTime = round(newStartTime / snapIncrement) * snapIncrement
                        
                        let durationOffset = event.startTime - snappedStartTime
                        let newDuration = event.duration + durationOffset
                        
                        if newDuration >= snapIncrement {
                            event.startTime = snappedStartTime
                            event.duration = newDuration
                        }
                    }
                    .onEnded { _ in
                        isResizingTop = false
                        saveEvents()
                    }
            )
            
            // Bottom resize handle
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(height: 4)
                    .cornerRadius(2)
                    .padding(.horizontal, 20)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if !isResizingBottom {
                            isResizingBottom = true
                            feedbackGenerator.impactOccurred()
                        }
                        let timeOffset = Double(gesture.translation.height / hourHeight) * 3600
                        let newDuration = event.duration + timeOffset
                        let snappedDuration = round(newDuration / snapIncrement) * snapIncrement
                        
                        if snappedDuration >= snapIncrement {
                            event.duration = snappedDuration
                        }
                    }
                    .onEnded { _ in
                        isResizingBottom = false
                        saveEvents()
                    }
            )
        }
        .padding(.trailing, 10)
    }

    /// Formats a time interval into a human-readable time string.
    /// - Parameter timeInterval: The time interval to format, in seconds from midnight.
    /// - Returns: A formatted time string (e.g., "9:00 AM").
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        // Get the start of the current day.
        let startOfDay = Calendar.current.startOfDay(for: Date())
        // Add the time interval to the start of the day to get the correct date.
        let date = startOfDay.addingTimeInterval(timeInterval)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


#Preview {
    NavigationView {
        ContentView()
    }
}
