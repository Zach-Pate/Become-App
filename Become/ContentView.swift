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
        case .travel: return Color(red: 0.72, green: 0.25, blue: 0.05) // Rust
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

// Add a notification name for when events are updated.
extension Notification.Name {
    static let eventsDidChange = Notification.Name("eventsDidChange")
}

// MARK: - Main Content View

/// The main view of the application, displaying the daily schedule.
struct ContentView: View {
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var isAddingEvent = false
    @State private var editingEvent: DayEvent?
    @State private var isDragging = false

    // A date range for the TabView, covering one year past and one year future.
    private var dateRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []
        for i in -365...365 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }

    @State private var swipeDirection: Edge = .leading

    var body: some View {
        ZStack {
            VStack {
                DateSelectorView(selectedDate: $selectedDate, isAddingEvent: $isAddingEvent)
                
                ZStack {
                    DayView(
                        date: selectedDate,
                        editingEvent: $editingEvent,
                        isDragging: $isDragging
                    )
                    .id(selectedDate)
                    .transition(.asymmetric(
                        insertion: .move(edge: swipeDirection),
                        removal: .move(edge: swipeDirection == .leading ? .trailing : .leading)
                    ))
                    
                    EdgeSwipeView(
                        selectedDate: $selectedDate,
                        dateRange: dateRange,
                        swipeDirection: $swipeDirection
                    )
                }
            }
            .navigationTitle(dateFormatter.string(from: selectedDate))
            
            PopUpMenu(isPresented: $isAddingEvent) {
                NewEventView(selectedDate: selectedDate, isPresented: $isAddingEvent)
            }
            
            if editingEvent != nil {
                PopUpMenu(isPresented: Binding(
                    get: { editingEvent != nil },
                    set: { if !$0 { editingEvent = nil } }
                )) {
                    EditEventView(event: editingEvent!, selectedDate: selectedDate, editingEvent: $editingEvent)
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Day View

struct DayView: View {
    let date: Date
    @Binding var editingEvent: DayEvent?
    @Binding var isDragging: Bool
    
    @State private var events: [DayEvent] = []
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?

    private let hourHeight: CGFloat = 52.8
    private let totalHours = 24
    private let snapIncrement: TimeInterval = 10 * 60

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Add invisible views with IDs for the ScrollViewReader to target.
                    ForEach(0..<totalHours, id: \.self) { hour in
                        Color.clear
                            .frame(height: 0)
                            .id(hour)
                            .offset(y: CGFloat(hour) * hourHeight)
                    }
                    
                    TimelineView()
                        .frame(height: hourHeight * CGFloat(totalHours))
                    
                    SnapGridView(hourHeight: hourHeight, snapIncrement: snapIncrement)
                        .frame(height: hourHeight * CGFloat(totalHours))

                    ForEach($events) { $event in
                        EventTileView(
                            event: $event,
                            hourHeight: hourHeight,
                            snapIncrement: snapIncrement,
                            saveEvents: { saveEvents(for: date) },
                            editingEvent: $editingEvent,
                            isDragging: $isDragging
                        )
                        .offset(y: yOffset(for: event.startTime))
                        .frame(height: height(for: event.duration))
                        .padding(.leading, 60)
                    }
                    
                    if Calendar.current.isDateInToday(date) {
                        CurrentTimeIndicator(hourHeight: hourHeight)
                            .offset(y: yOffset(for: currentTime))
                    }
                }
            }
            .scrollDisabled(isDragging)
            .onAppear {
                setup()
                // Delay the scroll action to ensure the view has rendered.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    proxy.scrollTo(6, anchor: .top)
                }
            }
            .onDisappear(perform: cancelTimer)
            .onReceive(NotificationCenter.default.publisher(for: .eventsDidChange)) { _ in
                loadEvents(for: date)
            }
        }
    }

    // MARK: - Helper Functions
    
    private func setup() {
        loadEvents(for: date)
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
    
    private func yOffset(for startTime: TimeInterval) -> CGFloat {
        let hours = startTime / 3600
        return CGFloat(hours) * hourHeight
    }
    
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
    
    private func saveEvents(for date: Date) {
        var masterRepeatingEvents = loadMasterRepeatingEvents()
        let originalMasterEvents = masterRepeatingEvents

        var singleEventsForDay = self.events.filter { $0.repeatOption == .none }
        let repeatingOccurrences = self.events.filter { $0.repeatOption != .none }
        var mastersNeedSaving = false

        for occurrence in repeatingOccurrences {
            if let masterEvent = originalMasterEvents.first(where: { $0.seriesId == occurrence.seriesId }) {
                if occurrence.startTime != masterEvent.startTime || occurrence.duration != masterEvent.duration {
                    if let masterIndex = masterRepeatingEvents.firstIndex(where: { $0.seriesId == occurrence.seriesId }) {
                        masterRepeatingEvents[masterIndex].exceptionDates.insert(date)
                        mastersNeedSaving = true
                    }
                    var newSingleEvent = occurrence
                    newSingleEvent.repeatOption = .none
                    newSingleEvent.seriesId = nil
                    singleEventsForDay.append(newSingleEvent)
                }
            }
        }

        saveEventsForDate(singleEventsForDay, for: date)

        if mastersNeedSaving {
            saveMasterRepeatingEvents(masterRepeatingEvents)
        }

        NotificationCenter.default.post(name: .eventsDidChange, object: nil)
    }
    
    private func saveEventsForDate(_ events: [DayEvent], for date: Date) {
        let key = dateKey(for: date)
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func loadEvents(for date: Date) {
        let key = dateKey(for: date)
        var allEvents: [DayEvent] = []
        
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decodedEvents = try JSONDecoder().decode([DayEvent].self, from: data)
                allEvents.append(contentsOf: decodedEvents)
            } catch {
                print("Failed to decode single-day events for key '\(key)': \(error)")
            }
        }
        
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
                                if Calendar.current.isDateInToday(date) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 5, height: 5)
                                }
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
        ZStack(alignment: .top) {
            ForEach(0..<totalHours, id: \.self) { hour in
                Text(timeString(for: hour))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .position(x: 30, y: CGFloat(hour) * hourHeight)
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
    @Binding var isDragging: Bool

    // --- Gesture States ---
    @GestureState private var isLongPressing = false
    @State private var dragOffset: CGSize = .zero

    private var tileHeight: CGFloat {
        CGFloat(event.duration / 3600) * hourHeight
    }
    
    private var draggedStartTime: TimeInterval {
        let timeOffset = (dragOffset.height / hourHeight) * 3600
        let newStartTime = event.startTime + timeOffset
        return round(newStartTime / snapIncrement) * snapIncrement
    }
    
    private var draggedEndTime: TimeInterval {
        draggedStartTime + event.duration
    }
    
    var body: some View {
        let longPressDragGesture = LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .updating($isLongPressing) { value, state, transaction in
                switch value {
                case .first(true):
                    state = true
                    // Use a transaction to disable the default animation.
                    // This prevents the tile from animating to its new position.
                    transaction.disablesAnimations = true
                default:
                    break
                }
            }
            .onChanged { value in
                switch value {
                case .first(true):
                    // This is the moment the long press is recognized.
                    isDragging = true // Disables the main ScrollView.
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                case .second(true, let drag):
                    // This is when the user is actively dragging.
                    dragOffset = drag?.translation ?? .zero
                default:
                    break
                }
            }
            .onEnded { value in
                if case .second(true, let drag?) = value {
                    let dragDistance = sqrt(pow(drag.translation.width, 2) + pow(drag.translation.height, 2))
                    
                    // Only act if the gesture was a drag (moved more than 10 points).
                    if dragDistance > 10 {
                        event.startTime = draggedStartTime
                        saveEvents()
                    } else {
                        // Otherwise, it was a long press without a drag - trigger the edit view.
                        editingEvent = event
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                } else {
                    // This handles the case of a long press without any drag attempt.
                    editingEvent = event
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
                
                // Reset all gesture-related states.
                isDragging = false
                dragOffset = .zero
            }

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(event.color.opacity(0.8))
            
            if event.duration >= 1800 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.white)

                    // Display time only for events that are tall enough (roughly 45+ minutes).
                    if tileHeight >= 40 {
                        Text("\(formattedTime(draggedStartTime)) - \(formattedTime(draggedEndTime))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                // Use smaller padding for events under an hour to give text more space.
                .padding(event.duration < 3600 ? 4 : 8)
            }
            
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
        .clipped()
        .padding(.trailing, 10)
        .offset(y: dragOffset.height)
        .gesture(longPressDragGesture)
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
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var eventDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var category: EventCategory = .work
    @State private var repeatOption: RepeatOption = .none
    @State private var selectedWeekdays: Set<Weekday> = []
    
    init(selectedDate: Date, isPresented: Binding<Bool>) {
        self.selectedDate = selectedDate
        self._isPresented = isPresented
        _eventDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 15) {
                TextField("Title", text: $title)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                
                DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                
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
                .pickerStyle(.menu)
                
                Picker("Repeats", selection: $repeatOption) {
                    Text("Never").tag(RepeatOption.none)
                    Text("Daily").tag(RepeatOption.daily)
                    Text("Weekly").tag(RepeatOption.weekly(selectedWeekdays))
                }
                .pickerStyle(.menu)
                
                if case .weekly = repeatOption {
                    WeekdaySelectorView(selectedDays: $selectedWeekdays)
                }
            }
            .padding(.vertical)
            
            PopUpMenuButtons(
                onCancel: { isPresented = false },
                onSave: {
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
                    isPresented = false
                }
            )
        }
        .onAppear(perform: setupInitialTimes)
        .onChange(of: eventDate) {
            updateTimeDates(with: eventDate)
        }
    }
    
    /// Sets the initial start and end times when the view appears.
    /// This ensures that the time pickers are initialized with the currently selected date from the main view
    /// and a sensible default time (the current time).
    private func setupInitialTimes() {
        let calendar = Calendar.current
        
        let now = Date()
        var components = calendar.dateComponents([.hour, .minute], from: now)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        
        if let initialStartTime = calendar.date(from: components) {
            startTime = initialStartTime
            endTime = calendar.date(byAdding: .hour, value: 1, to: initialStartTime) ?? initialStartTime
        }
    }

    /// Updates the `startTime` and `endTime` dates to reflect a new date selected in the `eventDate` picker.
    /// This keeps the time component the same while changing the date component, preventing events from being
    /// scheduled on the wrong day.
    /// - Parameter newDate: The new date to apply to the start and end times.
    private func updateTimeDates(with newDate: Date) {
        let calendar = Calendar.current
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        var newDateComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
        newDateComponents.hour = timeComponents.hour
        newDateComponents.minute = timeComponents.minute
        
        if let updatedStartTime = calendar.date(from: newDateComponents) {
            let duration = endTime.timeIntervalSince(startTime)
            startTime = updatedStartTime
            endTime = updatedStartTime.addingTimeInterval(duration)
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
        NotificationCenter.default.post(name: .eventsDidChange, object: nil)
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
    @State var event: DayEvent
    let selectedDate: Date
    @Binding var editingEvent: DayEvent?
    
    @State private var title: String
    @State private var eventDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var category: EventCategory
    @State private var repeatOption: RepeatOption
    @State private var selectedWeekdays: Set<Weekday>
    @State private var showDeleteAlert = false
    
    init(event: DayEvent, selectedDate: Date, editingEvent: Binding<DayEvent?>) {
        self._event = State(initialValue: event)
        self.selectedDate = selectedDate
        self._editingEvent = editingEvent
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        _title = State(initialValue: event.title)
        _eventDate = State(initialValue: selectedDate)
        _startTime = State(initialValue: startOfDay.addingTimeInterval(event.startTime))
        _endTime = State(initialValue: startOfDay.addingTimeInterval(event.startTime + event.duration))
        _category = State(initialValue: event.category)
        _repeatOption = State(initialValue: event.repeatOption)
        
        if case .weekly(let weekdays) = event.repeatOption {
            _selectedWeekdays = State(initialValue: weekdays)
        } else {
            _selectedWeekdays = State(initialValue: [])
        }
    }
    
    // Breaking the body into smaller components to avoid compiler timeouts.
    var body: some View {
        VStack {
            eventForm
            
            PopUpMenuButtons(
                onCancel: { editingEvent = nil },
                onSave: {
                    if event.seriesId != nil {
                        showSaveAlert = true
                    } else {
                        updateEvent()
                        editingEvent = nil
                    }
                }
            )
        }
        .alert("Save Repeating Event", isPresented: $showSaveAlert) {
            Button("This Event Only") {
                updateSingleInstanceOfRepeatingEvent()
                editingEvent = nil
            }
            Button("All Future Events") {
                updateAllFutureEvents()
                editingEvent = nil
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you want to save changes for this event only, or for all future events in the series?")
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
    
    private var eventForm: some View {
        VStack(spacing: 15) {
            TextField("Title", text: $title)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            
            DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                .datePickerStyle(.compact)
            DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
            DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
            
            categoryPicker
            repeatPicker
            
            if case .weekly = repeatOption {
                WeekdaySelectorView(selectedDays: $selectedWeekdays)
            }
            
            deleteButton
        }
        .padding(.vertical)
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
    
    @State private var showSaveAlert = false
    private var saveButton: some View {
        Button("Save") {
            if event.seriesId != nil {
                showSaveAlert = true
            } else {
                updateEvent()
                editingEvent = nil
            }
        }
        .disabled(endTime <= startTime)
    }
    
    private var deleteAlertButtons: some View {
        Group {
            if event.repeatOption != .none {
                Button("Delete This Event Only", role: .destructive) {
                    addExceptionDate()
                    editingEvent = nil
                }
                Button("Delete All Future Events", role: .destructive) {
                    if let seriesId = event.seriesId {
                        removeMasterRepeatingEvent(with: seriesId)
                    }
                    editingEvent = nil
                }
            } else {
                Button("Delete", role: .destructive) {
                    removeSingleEvent()
                    editingEvent = nil
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Data Persistence
    
    private func updateSingleInstanceOfRepeatingEvent() {
        // This is an instance of a repeating event.
        // 1. Add an exception to the master event.
        var masterEvents = loadMasterRepeatingEvents()
        if let index = masterEvents.firstIndex(where: { $0.seriesId == event.seriesId }) {
            masterEvents[index].exceptionDates.insert(selectedDate)
            saveMasterRepeatingEvents(masterEvents)
        }
        
        // 2. Create a new, non-repeating event with the changes.
        var newEvent = event
        let startOfDay = Calendar.current.startOfDay(for: eventDate)
        newEvent.startTime = startTime.timeIntervalSince(startOfDay)
        newEvent.duration = endTime.timeIntervalSince(startTime)
        newEvent.title = title
        newEvent.category = category
        newEvent.repeatOption = .none
        newEvent.seriesId = nil // It's now a standalone event.
        
        var dayEvents = loadEventsForDate(eventDate)
        dayEvents.append(newEvent)
        saveEventsForDate(dayEvents, for: eventDate)
        
        NotificationCenter.default.post(name: .eventsDidChange, object: nil)
    }

    private func updateAllFutureEvents() {
        var masterEvents = loadMasterRepeatingEvents()
        if let index = masterEvents.firstIndex(where: { $0.seriesId == event.seriesId }) {
            let startOfDay = Calendar.current.startOfDay(for: eventDate)
            masterEvents[index].startTime = startTime.timeIntervalSince(startOfDay)
            masterEvents[index].duration = endTime.timeIntervalSince(startTime)
            masterEvents[index].title = title
            masterEvents[index].category = category
            if case .weekly = repeatOption {
                masterEvents[index].repeatOption = .weekly(selectedWeekdays)
            } else {
                masterEvents[index].repeatOption = repeatOption
            }
            saveMasterRepeatingEvents(masterEvents)
            NotificationCenter.default.post(name: .eventsDidChange, object: nil)
        }
    }

    private func updateEvent() {
        // This function now only handles single events or creating new repeating events.
        let startOfDay = Calendar.current.startOfDay(for: eventDate)
        event.startTime = startTime.timeIntervalSince(startOfDay)
        event.duration = endTime.timeIntervalSince(startTime)
        event.title = title
        event.category = category
        if case .weekly = repeatOption {
            event.repeatOption = .weekly(selectedWeekdays)
        } else {
            event.repeatOption = repeatOption
        }

        if event.repeatOption != .none && event.seriesId == nil {
            // This was a single event that is now a repeating event.
            event.seriesId = UUID()
            var masterEvents = loadMasterRepeatingEvents()
            masterEvents.append(event)
            saveMasterRepeatingEvents(masterEvents)
            
            // Remove the old single event
            var dayEvents = loadEventsForDate(selectedDate)
            dayEvents.removeAll { $0.id == event.id }
            saveEventsForDate(dayEvents, for: selectedDate)

        } else {
            // This is a single event that was and remains a single event.
            var dayEvents = loadEventsForDate(eventDate)
            if let index = dayEvents.firstIndex(where: { $0.id == event.id }) {
                dayEvents[index] = event
                saveEventsForDate(dayEvents, for: eventDate)
            }
        }
        
        NotificationCenter.default.post(name: .eventsDidChange, object: nil)
    }

    private func addExceptionDate() {
        var repeatingEvents = loadMasterRepeatingEvents()
        if let index = repeatingEvents.firstIndex(where: { $0.seriesId == event.seriesId }) {
            repeatingEvents[index].exceptionDates.insert(selectedDate)
            saveMasterRepeatingEvents(repeatingEvents)
            NotificationCenter.default.post(name: .eventsDidChange, object: nil)
        }
    }
    
    private func removeMasterRepeatingEvent(with seriesId: UUID) {
        var repeatingEvents = loadMasterRepeatingEvents()
        repeatingEvents.removeAll { $0.seriesId == seriesId }
        saveMasterRepeatingEvents(repeatingEvents)
        NotificationCenter.default.post(name: .eventsDidChange, object: nil)
    }
    
    private func removeSingleEvent() {
        var dayEvents = loadEventsForDate(selectedDate)
        dayEvents.removeAll { $0.id == event.id }
        saveEventsForDate(dayEvents, for: selectedDate)
        NotificationCenter.default.post(name: .eventsDidChange, object: nil)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}
