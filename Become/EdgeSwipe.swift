import SwiftUI

/// A view modifier that detects horizontal drag gestures starting from the screen edges.
struct EdgeSwipe: ViewModifier {
    @Binding var selectedDate: Date
    let dateRange: [Date]
    
    // The width of the area on the screen edges that will detect the swipe.
    private let edgeWidth: CGFloat = 30.0
    // The minimum drag distance required to trigger a swipe.
    private let minDragDistance: CGFloat = 50.0
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // Check if the drag started on the left or right edge of the screen.
                        let startX = value.startLocation.x
                        let screenWidth = UIScreen.main.bounds.width
                        
                        guard startX < edgeWidth || startX > screenWidth - edgeWidth else {
                            return
                        }
                        
                        // Check if the drag was far enough to be considered a swipe.
                        let dragDistance = value.translation.width
                        
                        if dragDistance > minDragDistance {
                            // Swipe right (previous day).
                            if let currentIndex = dateRange.firstIndex(of: selectedDate), currentIndex > 0 {
                                selectedDate = dateRange[currentIndex - 1]
                            }
                        } else if dragDistance < -minDragDistance {
                            // Swipe left (next day).
                            if let currentIndex = dateRange.firstIndex(of: selectedDate), currentIndex < dateRange.count - 1 {
                                selectedDate = dateRange[currentIndex + 1]
                            }
                        }
                    }
            )
    }
}

extension View {
    /// Adds an edge swipe gesture to the view.
    /// - Parameters:
    ///   - selectedDate: A binding to the currently selected date.
    ///   - dateRange: The range of dates to swipe through.
    func onEdgeSwipe(selectedDate: Binding<Date>, dateRange: [Date]) -> some View {
        self.modifier(EdgeSwipe(selectedDate: selectedDate, dateRange: dateRange))
    }
}
