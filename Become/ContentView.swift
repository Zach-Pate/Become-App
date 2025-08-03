import SwiftUI

// MARK: - Models

struct DayEvent: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var startTime: TimeInterval // Stored as seconds from midnight
    var duration: TimeInterval // Stored in seconds
    var color: Color
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var events: [DayEvent] = [
        DayEvent(title: "Morning Standup", startTime: 9 * 3600, duration: 1800, color: .blue),
        DayEvent(title: "Design Review", startTime: 11 * 3600, duration: 3600, color: .green),
        DayEvent(title: "Lunch", startTime: 12.5 * 3600, duration: 3600, color: .orange),
        DayEvent(title: "Focused Work", startTime: 14 * 3600, duration: 7200, color: .purple),
        DayEvent(title: "Team Sync", startTime: 16.5 * 3600, duration: 1800, color: .teal)
    ]
    @State private var draggingEvent: DayEvent?
    @State private var dragOffset: CGSize = .zero

    private let hourHeight: CGFloat = 80.0
    private let totalHours = 24

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                TimelineView()
                    .frame(height: hourHeight * CGFloat(totalHours))

                ForEach(events) { event in
                    EventTileView(event: event)
                        .offset(y: yOffset(for: event))
                        .frame(height: height(for: event.duration))
                        .padding(.leading, 60)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if draggingEvent == nil {
                                        draggingEvent = event
                                    }
                                    dragOffset = gesture.translation
                                }
                                .onEnded { gesture in
                                    if let draggingEvent = draggingEvent {
                                        let timeOffset = Double(gesture.translation.height / hourHeight) * 3600
                                        let newStartTime = draggingEvent.startTime + timeOffset
                                        
                                        if let index = events.firstIndex(where: { $0.id == draggingEvent.id }) {
                                            events[index].startTime = newStartTime
                                        }
                                    }
                                    draggingEvent = nil
                                    dragOffset = .zero
                                }
                        )
                }
            }
        }
        .navigationTitle("Today's Plan")
    }

    private func yOffset(for event: DayEvent) -> CGFloat {
        if event.id == draggingEvent?.id {
            let hours = (draggingEvent?.startTime ?? 0) / 3600
            return CGFloat(hours) * hourHeight + dragOffset.height
        }
        let hours = event.startTime / 3600
        return CGFloat(hours) * hourHeight
    }
    
    private func yOffset(for startTime: TimeInterval) -> CGFloat {
        let hours = startTime / 3600
        return CGFloat(hours) * hourHeight
    }

    private func height(for duration: TimeInterval) -> CGFloat {
        let hours = duration / 3600
        return CGFloat(hours) * hourHeight
    }
}

// MARK: - Subviews

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

    private func timeString(for hour: Int) -> String {
        let ampm = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(displayHour) \(ampm)"
    }
}

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

struct EventTileView: View {
    let event: DayEvent

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(event.color.opacity(0.8))
            
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

    private func formattedTime(_ timeInterval: TimeInterval) -> String {
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