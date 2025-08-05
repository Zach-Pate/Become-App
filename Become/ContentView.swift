import SwiftUI
import UIKit

// MARK: - Models

// Added Hashable conformance for use in SwiftUI Pickers.
enum RepeatOption: Codable, Equatable, Hashable {
    case none
    case daily
    case weekly(Set<Weekday>)
}

enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var id: Int { self.rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}

enum EventCategory: String, CaseIterable, Codable {
    case appointment, errands, exercise, family, meal, meeting, personal, rest, social, study, travel, work, other
    
    var color: Color {
        switch self {
        case .appointment: return .red
        case .errands: return .yellow
        case .exercise: return .green
        case .family: return .pink
        case .meal: return .orange
        case .meeting: return .blue
        case .personal: return .purple
        case .rest: return .mint
        case .social: return .teal
        case .study: return .brown
        case .travel: return .cyan
        case .work: return .indigo
        case .other: return .gray
        }
    }
}

/// Represents a single event in the daily schedule.
struct DayEvent: Identifiable, Equatable, Codable {
    /// A unique identifier for the event.
    let id: UUID
    /// A unique identifier for a series of repeating events
    var seriesId: UUID?
    /// The title or name of the event.
    var title: String
    /// The start time of the event, stored as seconds from midnight.
    var startTime: TimeInterval
    /// The duration of the event, stored in seconds.
    var duration: TimeInterval
    /// The category of the event.
    var category: EventCategory
    /// The rule for repeating the event.
    var repeatOption: RepeatOption = .none
    /// A set of dates on which a repeating event should not appear.
    var exceptionDates: Set<Date> = []
    
    var color: Color {
        return category.color
    }
    
    // Coding keys used for encoding/decoding properties (Color is excluded as it's a computed property).
    enum CodingKeys: String, CodingKey {
        case id, seriesId, title, startTime, duration, category, repeatOption, exceptionDates
    }
    
    // Custom encoding to convert Color to a Codable format.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(seriesId, forKey: .seriesId)
        try container.encode(title, forKey: .title)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(category, forKey: .category)
        try container.encode(repeatOption, forKey: .repeatOption)
        try container.encode(exceptionDates, forKey: .exceptionDates)
    }
    
    // Custom decoding to convert from a Codable format back to Color.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        seriesId = try container.decodeIfPresent(UUID.self, forKey: .seriesId)
        title = try container.decode(String.self, forKey: .title)
        startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        category = try container.decode(EventCategory.self, forKey: .category)
        repeatOption = try container.decode(RepeatOption.self, forKey: .repeatOption)
        exceptionDates = try container.decode(Set<Date>.self, forKey: .exceptionDates)
    }
    
    // Initializer for creating events without decoding.
    init(id: UUID = UUID(), seriesId: UUID? = nil, title: String, startTime: TimeInterval, duration: TimeInterval, category: EventCategory, repeatOption: RepeatOption = .none, exceptionDates: Set<Date> = []) {
        self.id = id
        self.seriesId = seriesId
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.category = category
        self.repeatOption = repeatOption
        self.exceptionDates = exceptionDates
    }
}

// MARK: - Subviews

struct WeekdaySelectorView: View {
    @Binding var selectedDays: Set<Weekday>
    
    var body: some View {
        HStack {
            ForEach(Weekday.allCases) { day in
                Text(day.shortName)
                    .fontWeight(.bold)
                    .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                    .frame(width: 40, height: 40)
                    .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                    .clipShape(Circle())
                    .onTapGesture {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }
            }
        }
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
    private let hourHeight: CGFloat = 52.8
    /// The total number of hours to display in the timeline.
    private let totalHours = 24
    /// The time increment for snapping events, in seconds (10 minutes).
    private let snapIncrement: TimeInterval = 10 * 60

    // MARK: - Body
    
    var body: some View {
        let swipeGesture = DragGesture()
            .onEnded { value in
                withAnimation(.spring) {
                    if value.translation.width < -50 {
                        // Swipe left to go to the next day
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    } else if value.translation.width > 50 {
                        // Swipe right to go to the previous day
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    }
                }
            }

        return VStack {
            DateSelectorView(selectedDate: $selectedDate, isAddingEvent: $isAddingEvent)
            ScrollViewReader { proxy in
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
                .onAppear {
                    proxy.scrollTo(6, anchor: .top)
                }
                .onChange(of: selectedDate) { oldValue, newValue in
                    loadEvents(for: newValue)
                    proxy.scrollTo(6, anchor: .top)
                }
            }
        }
        .gesture(swipeGesture)
        .navigationTitle(dateFormatter.string(from: selectedDate))
        .onAppear(perform: setup)
        .onDisappear(perform: cancelTimer)
        .sheet(isPresented: $isAddingEvent, onDismiss: {
            loadEvents(for: selectedDate)
        }) {
            NewEventView(selectedDate: selectedDate)
                .presentationDetents([.medium])
        }
        .sheet(item: $editingEvent, onDismiss: {
            loadEvents(for: selectedDate)
        }) { event in
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                EditEventView(event: $events[index], events: $events, selectedDate: selectedDate, saveEvents: { _ in saveEvents(for: selectedDate) })
                    .presentationDetents([.medium])
            }
        }
        .transition(.slide)
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
    
    private func loadMasterRepeatingEvents() -> [DayEvent] {
        guard let data = UserDefaults.standard.data(forKey: "masterRepeatingEvents"),
              let decodedEvents = try? JSONDecoder().decode([DayEvent].self, from: data) else {
            return []
        }
        return decodedEvents
    }
    
    private func saveMasterRepeatingEvents(_ events: [DayEvent]) {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "masterRepeatingEvents")
        }
    }
    
    /// Saves the current events to UserDefaults.
    private func saveEvents(for date: Date) {
        let key = dateKey(for: date)
        
        // Separate single-day and repeating events.
        let singleDayEvents = events.filter { $0.repeatOption == .none }
        let repeatingEvents = events.filter { $0.repeatOption != .none }
        
        // Save single-day events to their specific date key.
        if let encoded = try? JSONEncoder().encode(singleDayEvents) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
        
        // Update the master list of repeating events.
        var masterRepeatingEvents = loadMasterRepeatingEvents()
        for event in repeatingEvents {
            if let index = masterRepeatingEvents.firstIndex(where: { $0.id == event.id }) {
                masterRepeatingEvents[index] = event
            } else {
                masterRepeatingEvents.append(event)
            }
        }
        saveMasterRepeatingEvents(masterRepeatingEvents)
    }
    
    /// Loads events from UserDefaults. If no data is found, it initializes an empty array.
    private func loadEvents(for date: Date) {
        let key = dateKey(for: date)
        var allEvents: [DayEvent] = []
        
        // Load single-day events
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decodedEvents = try JSONDecoder().decode([DayEvent].self, from: data)
                allEvents.append(contentsOf: decodedEvents)
            } catch {
                print("Failed to decode single-day events for key '\(key)': \(error)")
            }
        }
        
        // Load and filter repeating events
        if let data = UserDefaults.standard.data(forKey: "masterRepeatingEvents") {
            do {
                let repeatingEvents = try JSONDecoder().decode([DayEvent].self, from: data)
                let occurrences = repeatingEvents.filter { event in
                    shouldEventOccur(event, on: date)
                }
                allEvents.append(contentsOf: occurrences)
            } catch {
                print("Failed to decode repeating events: \(error)")
            }
        }
        
        events = allEvents
    }

    private func shouldEventOccur(_ event: DayEvent, on date: Date) -> Bool {
        let calendar = Calendar.current
        
        // If the date is in the exception list, don't show the event.
        if event.exceptionDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
            return false
        }
        
        let weekday = calendar.component(.weekday, from: date)
        
        switch event.repeatOption {
        case .none:
            return false
        case .daily:
            return true
        case .weekly(let selectedDays):
            if let currentWeekday = Weekday(rawValue: weekday) {
                return selectedDays.contains(currentWeekday)
            }
            return false
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Calendar.current.isDateInToday(date) ? Color.red : Color.clear, lineWidth: 2)
                            )
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
    private let hourHeight: CGFloat = 52.8
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
    private let hourHeight: CGFloat = 52.8
    private let totalHours = 24

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<totalHours, id: \.self) { hour in
                Text(timeString(for: hour))
                    .font(.caption)
                    .frame(height: hourHeight, alignment: .top)
                    .foregroundColor(.secondary)
                    .id(hour)
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
    private let hourHeight: CGFloat = 52.8
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
    @State private var isLongPressing = false
    
    private var tileHeight: CGFloat {
        CGFloat(event.duration / 3600) * hourHeight
    }
    
    var body: some View {
        let drag = DragGesture()
            .updating($dragOffset) { value, state, _ in
                if !isLongPressing {
                    state = value.translation
                }
            }
            .onEnded { value in
                if !isLongPressing {
                    let timeOffset = (value.translation.height / hourHeight) * 3600
                    let newStartTime = event.startTime + timeOffset
                    
                    // Always snap to the nearest 5-minute increment.
                    let snappedStartTime = round(newStartTime / snapIncrement) * snapIncrement
                    event.startTime = snappedStartTime
                    
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    saveEvents()
                }
                isLongPressing = false
            }

        let longPress = LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                isLongPressing = true
                editingEvent = event
            }

        let combined = longPress.simultaneously(with: drag)

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
            
            // This VStack contains the drag handles for resizing the event.
            VStack {
                // Top handle for resizing.
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 10)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let heightChange = value.translation.height
                                let timeChange = (heightChange / hourHeight) * 3600
                                
                                // Update the start time and duration based on the drag.
                                let newStartTime = event.startTime + timeChange
                                let newDuration = event.duration - timeChange
                                
                                event.startTime = round(newStartTime / snapIncrement) * snapIncrement
                                event.duration = round(newDuration / snapIncrement) * snapIncrement
                            }
                            .onEnded { _ in
                                // When the drag ends, provide haptic feedback and save the changes.
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                saveEvents()
                            }
                    )
                
                Spacer()
                
                // Bottom handle for resizing.
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 10)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let heightChange = value.translation.height
                                let timeChange = (heightChange / hourHeight) * 3600
                                
                                // Update the duration based on the drag.
                                let newDuration = event.duration + timeChange
                                event.duration = round(newDuration / snapIncrement) * snapIncrement
                            }
                            .onEnded { _ in
                                // When the drag ends, provide haptic feedback and save the changes.
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                saveEvents()
                            }
                    )
            }
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
    let selectedDate: Date
    
    @State private var title = ""
    @State private var eventDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var category: EventCategory = .work
    @State private var repeatOption: RepeatOption = .none
    @State private var selectedWeekdays: Set<Weekday> = []
    
    @Environment(\.dismiss) var dismiss
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        _eventDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                Picker("Category", selection: $category) {
                    ForEach(EventCategory.allCases.sorted(by: { $0.rawValue < $1.rawValue }).filter { $0 != .other } + [.other], id: \.self) { category in
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)
                            Text(category.rawValue.capitalized)
                        }.tag(category)
                    }
                }
                
                Picker("Repeats", selection: $repeatOption) {
                    Text("Never").tag(RepeatOption.none)
                    Text("Daily").tag(RepeatOption.daily)
                    Text("Weekly").tag(RepeatOption.weekly(selectedWeekdays))
                }
                
                if case .weekly = repeatOption {
                    WeekdaySelectorView(selectedDays: $selectedWeekdays)
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
                        
                        var finalRepeatOption = repeatOption
                        if case .weekly = finalRepeatOption {
                            finalRepeatOption = .weekly(selectedWeekdays)
                        }

                        let startOfDay = Calendar.current.startOfDay(for: eventDate)
                        let startTimeInterval = startTime.timeIntervalSince(startOfDay)
                        let endTimeInterval = endTime.timeIntervalSince(startOfDay)
                        
                        let newEvent = DayEvent(
                            seriesId: finalRepeatOption == .none ? nil : UUID(),
                            title: title,
                            startTime: startTimeInterval,
                            duration: endTimeInterval - startTimeInterval,
                            category: category,
                            repeatOption: finalRepeatOption
                        )
                        
                        save(event: newEvent)
                        
                        dismiss()
                    }
                    .disabled(endTime <= startTime)
                }
            }
        }
    }

    private func save(event: DayEvent) {
        if event.repeatOption == .none {
            var dayEvents = loadEventsForDate(eventDate)
            dayEvents.append(event)
            saveEventsForDate(dayEvents, for: eventDate)
        } else {
            var repeatingEvents = loadMasterRepeatingEvents()
            repeatingEvents.append(event)
            saveMasterRepeatingEvents(repeatingEvents)
        }
    }
    
    private func loadEventsForDate(_ date: Date) -> [DayEvent] {
        let key = dateKey(for: date)
        guard let data = UserDefaults.standard.data(forKey: key),
              let decodedEvents = try? JSONDecoder().decode([DayEvent].self, from: data) else {
            return []
        }
        return decodedEvents
    }

    private func saveEventsForDate(_ events: [DayEvent], for date: Date) {
        let key = dateKey(for: date)
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func loadMasterRepeatingEvents() -> [DayEvent] {
        guard let data = UserDefaults.standard.data(forKey: "masterRepeatingEvents"),
              let decodedEvents = try? JSONDecoder().decode([DayEvent].self, from: data) else {
            return []
        }
        return decodedEvents
    }
    
    private func saveMasterRepeatingEvents(_ events: [DayEvent]) {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "masterRepeatingEvents")
        }
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct EditEventView: View {
    @Binding var event: DayEvent
    @Binding var events: [DayEvent]
    let selectedDate: Date
    let saveEvents: (Date) -> Void
    
    @State private var title: String
    @State private var eventDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var category: EventCategory
    @State private var repeatOption: RepeatOption
    @State private var selectedWeekdays: Set<Weekday>
    @State private var showDeleteAlert = false
    
    @Environment(\.dismiss) var dismiss
    
    init(event: Binding<DayEvent>, events: Binding<[DayEvent]>, selectedDate: Date, saveEvents: @escaping (Date) -> Void) {
        self._event = event
        self._events = events
        self.selectedDate = selectedDate
        self.saveEvents = saveEvents
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        _title = State(initialValue: event.wrappedValue.title)
        _eventDate = State(initialValue: selectedDate)
        _startTime = State(initialValue: startOfDay.addingTimeInterval(event.wrappedValue.startTime))
        _endTime = State(initialValue: startOfDay.addingTimeInterval(event.wrappedValue.startTime + event.wrappedValue.duration))
        _category = State(initialValue: event.wrappedValue.category)
        _repeatOption = State(initialValue: event.wrappedValue.repeatOption)
        
        if case .weekly(let weekdays) = event.wrappedValue.repeatOption {
            _selectedWeekdays = State(initialValue: weekdays)
        } else {
            _selectedWeekdays = State(initialValue: [])
        }
    }
    
    // Breaking the body into smaller components to avoid compiler timeouts.
    var body: some View {
        NavigationView {
            eventForm
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
            .alert("Delete Event", isPresented: $showDeleteAlert) {
                deleteAlertButtons
            } message: {
                if event.repeatOption != .none {
                    Text("Do you want to delete only this event or all future occurrences?")
                } else {
                    Text("Are you sure you want to delete this event?")
                }
            }
        }
    }
    
    private var eventForm: some View {
        Form {
            TextField("Title", text: $title)
            DatePicker("Date", selection: $eventDate, displayedComponents: .date)
            DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
            DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
            categoryPicker
            repeatPicker
            
            if case .weekly = repeatOption {
                WeekdaySelectorView(selectedDays: $selectedWeekdays)
            }
            
            deleteButton
        }
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $category) {
            ForEach(EventCategory.allCases.sorted(by: { $0.rawValue < $1.rawValue }).filter { $0 != .other } + [.other], id: \.self) { category in
                HStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 12, height: 12)
                    Text(category.rawValue.capitalized)
                }.tag(category)
            }
        }
    }

    private var repeatPicker: some View {
        Picker("Repeats", selection: $repeatOption) {
            Text("Never").tag(RepeatOption.none)
            Text("Daily").tag(RepeatOption.daily)
            Text("Weekly").tag(RepeatOption.weekly(selectedWeekdays))
        }
    }

    private var deleteButton: some View {
        Button("Delete Event") {
            showDeleteAlert = true
        }
        .foregroundColor(.red)
    }

    private var saveButton: some View {
        Button("Save") {
            guard endTime > startTime else { return }
            
            let startOfDay = Calendar.current.startOfDay(for: eventDate)
            let startTimeInterval = startTime.timeIntervalSince(startOfDay)
            let endTimeInterval = endTime.timeIntervalSince(startOfDay)
            
            event.title = title
            event.startTime = startTimeInterval
            event.duration = endTimeInterval - startTimeInterval
            event.category = category
            
            if case .weekly = repeatOption {
                event.repeatOption = .weekly(selectedWeekdays)
            } else {
                event.repeatOption = repeatOption
            }
            
            saveEvents(selectedDate)
            dismiss()
        }
        .disabled(endTime <= startTime)
    }

    private var deleteAlertButtons: some View {
        Group {
            if event.repeatOption != .none {
                Button("Delete This Event Only", role: .destructive) {
                    addExceptionDate()
                    dismiss()
                }
                Button("Delete All Future Events", role: .destructive) {
                    if let seriesId = event.seriesId {
                        removeMasterRepeatingEvent(with: seriesId)
                    }
                    dismiss()
                }
            } else {
                Button("Delete", role: .destructive) {
                    removeSingleEvent()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func addExceptionDate() {
        var repeatingEvents = loadMasterRepeatingEvents()
        if let index = repeatingEvents.firstIndex(where: { $0.seriesId == event.seriesId }) {
            repeatingEvents[index].exceptionDates.insert(selectedDate)
            saveMasterRepeatingEvents(repeatingEvents)
        }
    }
    
    private func removeMasterRepeatingEvent(with seriesId: UUID) {
        var repeatingEvents = loadMasterRepeatingEvents()
        repeatingEvents.removeAll { $0.seriesId == seriesId }
        saveMasterRepeatingEvents(repeatingEvents)
    }
    
    private func removeSingleEvent() {
        events.removeAll { $0.id == event.id }
        saveEvents(selectedDate)
    }
    
    private func loadMasterRepeatingEvents() -> [DayEvent] {
        guard let data = UserDefaults.standard.data(forKey: "masterRepeatingEvents"),
              let decodedEvents = try? JSONDecoder().decode([DayEvent].self, from: data) else {
            return []
        }
        return decodedEvents
    }
    
    private func saveMasterRepeatingEvents(_ events: [DayEvent]) {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "masterRepeatingEvents")
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
