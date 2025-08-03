import SwiftUI

// MARK: - Models

/// Represents a single event in the daily schedule.
struct DayEvent: Identifiable, Equatable {
    /// A unique identifier for the event.
    let id = UUID()
    /// The title or name of the event.
    var title: String
    /// The start time of the event, stored as seconds from midnight.
    var startTime: TimeInterval
    /// The duration of the event, stored in seconds.
    var duration: TimeInterval
    /// The color used to display the event tile.
    var color: Color
}

// MARK: - Main Content View

/// The main view of the application, displaying the daily schedule.
struct ContentView: View {
    // MARK: - State Properties
    
    /// The array of events for the day. This is sample data.
    @State private var events: [DayEvent] = [
        DayEvent(title: "Morning Standup", startTime: 9 * 3600, duration: 1800, color: .blue),
        DayEvent(title: "Design Review", startTime: 11 * 3600, duration: 3600, color: .green),
        DayEvent(title: "Lunch", startTime: 12.5 * 3600, duration: 3600, color: .orange),
        DayEvent(title: "Focused Work", startTime: 14 * 3600, duration: 7200, color: .purple),
        DayEvent(title: "Team Sync", startTime: 16.5 * 3600, duration: 1800, color: .teal)
    ]
    /// The event currently being dragged by the user.
    @State private var draggingEvent: DayEvent?
    /// The offset of the drag gesture.
    @State private var dragOffset: CGSize = .zero

    // MARK: - View Constants
    
    /// The height of a single hour in the timeline view.
    private let hourHeight: CGFloat = 80.0
    /// The total number of hours to display in the timeline.
    private let totalHours = 24

    // MARK: - Body
    
    var body: some View {
        ScrollView {
            // The ZStack layers the event tiles on top of the timeline background.
            ZStack(alignment: .topLeading) {
                // The background timeline view.
                TimelineView()
                    .frame(height: hourHeight * CGFloat(totalHours))

                // Iterate over the events and create a view for each one.
                ForEach(events) { event in
                    EventTileView(event: event)
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
                                        
                                        // Find the event in the array and update its start time.
                                        if let index = events.firstIndex(where: { $0.id == draggingEvent.id }) {
                                            events[index].startTime = newStartTime
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
    let event: DayEvent

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
        }
        .padding(.trailing, 10)
    }

    /// Formats a time interval into a human-readable time string.
    /// - Parameter timeInterval: The time interval to format, in seconds from midnight.
    /// - Returns: A formatted time string (e.g., "9:00 AM").
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        // Note: This time formatting is simplified and may not be perfect across all timezones.
        let date = Date(timeIntervalSinceReferenceDate: timeInterval - 3600 * 7) // Adjust for timezone if needed
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
