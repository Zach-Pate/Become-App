import SwiftUI
import UIKit

// MARK: - Models

enum EventCategory: String, CaseIterable, Codable {
    case meeting, meal, exercise, work, personal, family, social, errands, appointment, travel, rest, other
    
    var color: Color {
        switch self {
        case .meeting: return .blue
        case .meal: return .orange
        case .exercise: return .green
        case .work: return .indigo
        case .personal: return .purple
        case .family: return .pink
        case .social: return .teal
        case .errands: return .yellow
        case .appointment: return .red
        case .travel: return .cyan
        case .rest: return .mint
        case .other: return .gray
        }
    }
}

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
    /// The category of the event.
    var category: EventCategory
    
    var color: Color {
        return category.color
    }
    
    // Coding keys used for encoding/decoding properties (Color is excluded as it's a computed property).
    enum CodingKeys: String, CodingKey {
        case id, title, startTime, duration, category
    }
    
    // Custom encoding to convert Color to a Codable format.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(category, forKey: .category)
    }
    
    // Custom decoding to convert from a Codable format back to Color.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        category = try container.decode(EventCategory.self, forKey: .category)
    }
    
    // Initializer for creating events without decoding.
    init(id: UUID = UUID(), title: String, startTime: TimeInterval, duration: TimeInterval, category: EventCategory) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.category = category
    }
}

// MARK: - Main Content View

/// The main view of the application, displaying the daily schedule.
struct ContentView: View {
    // MARK: - State Properties
    
    /// The array of events for the day.
    @State private var events: [DayEvent] = []
    @State private var currentTime: TimeInterval = 0
    @State private var selectedDate: Date = Date()
    @State private var isAddingEvent = false
    @State private var editingEvent: DayEvent?
    @State private var timer: Timer?

    // MARK: - View Constants
    
    /// The height of a single hour in the timeline view.
    private let hourHeight: CGFloat = 80.0
    /// The total number of hours to display in the timeline.
    private let totalHours = 24
    /// The time increment for snapping events, in seconds (5 minutes).
    private let snapIncrement: TimeInterval = 5 * 60

    // MARK: - Body
    
    var body: some View {
        VStack {
            DateSelectorView(selectedDate: $selectedDate, isAddingEvent: $isAddingEvent)
            ScrollView {
                // The ZStack layers the event tiles on top of the timeline background.
                ZStack(alignment: .topLeading) {
                    // The background timeline view.
                    TimelineView()
                        .frame(height: hourHeight * CGFloat(totalHours))
                    
                    SnapGridView(hourHeight: hourHeight, snapIncrement: snapIncrement)
                        .frame(height: hourHeight * CGFloat(totalHours))

                    // Iterate over the events and create a view for each one.
                    ForEach($events) { $event in
                        EventTileView(event: $event, hourHeight: hourHeight, snapIncrement: snapIncrement, saveEvents: { saveEvents(for: selectedDate) }, editingEvent: $editingEvent)
                            .offset(y: yOffset(for: event.startTime))
                            .frame(height: height(for: event.duration))
                            .padding(.leading, 60)
                    }
                    
                    if Calendar.current.isDateInToday(selectedDate) {
                        CurrentTimeIndicator(hourHeight: hourHeight)
                            .offset(y: yOffset(for: currentTime))
                    }
                }
            }
        }
        .navigationTitle(dateFormatter.string(from: selectedDate))
        .onAppear(perform: setup)
        .onDisappear(perform: cancelTimer)
        .onChange(of: selectedDate) {
            loadEvents(for: $0)
        }
        .sheet(isPresented: $isAddingEvent) {
            NewEventView(events: $events, selectedDate: selectedDate, saveEvents: { saveEvents(for: selectedDate) })
                .presentationDetents([.medium])
        }
        .sheet(item: $editingEvent) { event in
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                EditEventView(event: $events[index], events: $events, selectedDate: selectedDate, saveEvents: { saveEvents(for: selectedDate) })
                    .presentationDetents([.medium])
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    // MARK: - Helper Functions
    
    private func setup() {
        loadEvents(for: selectedDate)
        // Set up a timer to update the current time every minute.
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateCurrentTime()
        }
        updateCurrentTime()
    }
    
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
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
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Saves the current events to UserDefaults.
    private func saveEvents(for date: Date) {
        let key = dateKey(for: date)
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    /// Loads events from UserDefaults. If no data is found, it initializes an empty array.
    private func loadEvents(for date: Date) {
        let key = dateKey(for: date)
        guard let data = UserDefaults.standard.data(forKey: key) else {
            // No data found for this date, so we'll start with an empty schedule.
            events = []
            return
        }
        
        do {
            // Attempt to decode the saved events from UserDefaults.
            let decodedEvents = try JSONDecoder().decode([DayEvent].self, from: data)
            events = decodedEvents
        } catch {
            // If decoding fails, log the error and start with an empty schedule to prevent data loss.
            print("Failed to decode events for key '\(key)': \(error)")
            events = []
        }
    }
}

// MARK: - Subviews

struct DateSelectorView: View {
    @Binding var selectedDate: Date
    @Binding var isAddingEvent: Bool
    
    private var dates: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        // Create a range of dates centered around the selected date.
        for i in -30...30 {
            if let date = calendar.date(byAdding: .day, value: i, to: selectedDate) {
                dates.append(date)
            }
        }
        return dates
    }
    
    var body: some View {
        HStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(dates, id: \.self) { date in
                            VStack {
                                Text(dayOfWeek(for: date))
                                    .font(.caption)
                                Text(dayOfMonth(for: date))
                                    .font(.headline)
                            }
                            .id(date)
                            .padding(8)
                            .background(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedDate = date
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    proxy.scrollTo(selectedDate, anchor: .center)
                }
                // Add this modifier to scroll to the selected date whenever it changes.
                .onChange(of: selectedDate) {
                    withAnimation {
                        proxy.scrollTo(selectedDate, anchor: .center)
                    }
                }
            }
            Button(action: { isAddingEvent = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.largeTitle)
            }
            .padding(.trailing)
        }
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func dayOfMonth(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}


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

struct SnapGridView: View {
    let hourHeight: CGFloat
    let snapIncrement: TimeInterval
    
    var body: some View {
        let fiveMinuteIncrements = Int(3600 / snapIncrement)
        let totalLines = 24 * fiveMinuteIncrements
        let lineHeight = hourHeight / CGFloat(fiveMinuteIncrements)

        VStack(spacing: 0) {
            ForEach(0..<totalLines, id: \.self) { _ in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 1)
                    Spacer(minLength: 0)
                }
                .frame(height: lineHeight)
            }
        }
        .padding(.leading, 60)
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
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
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
    @Binding var editingEvent: DayEvent?
    
    @GestureState private var dragOffset: CGSize = .zero
    
    private var tileHeight: CGFloat {
        CGFloat(event.duration / 3600) * hourHeight
    }
    
    var body: some View {
        let drag = DragGesture()
            .updating($dragOffset) { value, state, _ in
                // As the user drags, this closure is called.
                // We update the `dragOffset` gesture state, which temporarily
                // changes the visual offset of the event tile.
                state = value.translation
            }
            .onEnded { value in
                let timeOffset = (value.translation.height / hourHeight) * 3600
                let newStartTime = event.startTime + timeOffset
                
                // Check the velocity of the drag to determine if we should snap.
                let velocity = value.predictedEndTranslation.height
                if abs(velocity) > 500 { // Threshold for a "fast" drag
                    // Snap to the nearest 5-minute increment.
                    let snappedStartTime = round(newStartTime / snapIncrement) * snapIncrement
                    event.startTime = snappedStartTime
                } else {
                    // For a slow drag, allow for 1-minute precision.
                    let preciseStartTime = round(newStartTime / 60) * 60
                    event.startTime = preciseStartTime
                }
                
                // Provide haptic feedback when the event is moved.
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                
                saveEvents()
            }

        let longPress = LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                editingEvent = event
            }

        // By combining the long-press and drag gestures, we allow the user to either
        // long-press to edit or drag to move the event.
        let combined = longPress.sequenced(before: drag)

        return ZStack {
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
        .offset(y: dragOffset.height)
        .gesture(combined)
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
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
        }
    }
}

struct NewEventView: View {
    @Binding var events: [DayEvent]
    let selectedDate: Date
    let saveEvents: () -> Void
    
    @State private var title = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var category: EventCategory = .work
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                Picker("Category", selection: $category) {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)
                            Text(category.rawValue.capitalized)
                        }.tag(category)
                    }
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard endTime > startTime else { return }
                        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
                        let startTimeInterval = startTime.timeIntervalSince(startOfDay)
                        let endTimeInterval = endTime.timeIntervalSince(startOfDay)
                        
                        let newEvent = DayEvent(title: title, startTime: startTimeInterval, duration: endTimeInterval - startTimeInterval, category: category)
                        events.append(newEvent)
                        saveEvents()
                        dismiss()
                    }
                    .disabled(endTime <= startTime)
                }
            }
        }
    }
}

struct EditEventView: View {
    @Binding var event: DayEvent
    @Binding var events: [DayEvent]
    let selectedDate: Date
    let saveEvents: () -> Void
    
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var category: EventCategory
    
    @Environment(\.dismiss) var dismiss
    
    init(event: Binding<DayEvent>, events: Binding<[DayEvent]>, selectedDate: Date, saveEvents: @escaping () -> Void) {
        self._event = event
        self._events = events
        self.selectedDate = selectedDate
        self.saveEvents = saveEvents
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        _title = State(initialValue: event.wrappedValue.title)
        _startTime = State(initialValue: startOfDay.addingTimeInterval(event.wrappedValue.startTime))
        _endTime = State(initialValue: startOfDay.addingTimeInterval(event.wrappedValue.startTime + event.wrappedValue.duration))
        _category = State(initialValue: event.wrappedValue.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                Picker("Category", selection: $category) {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)
                            Text(category.rawValue.capitalized)
                        }.tag(category)
                    }
                }
                Button("Delete Event") {
                    events.removeAll { $0.id == event.id }
                    saveEvents()
                    dismiss()
                }
                .foregroundColor(.red)
            }
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard endTime > startTime else { return }
                        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
                        let startTimeInterval = startTime.timeIntervalSince(startOfDay)
                        let endTimeInterval = endTime.timeIntervalSince(startOfDay)
                        
                        event.title = title
                        event.startTime = startTimeInterval
                        event.duration = endTimeInterval - startTimeInterval
                        event.category = category
                        
                        saveEvents()
                        dismiss()
                    }
                    .disabled(endTime <= startTime)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}