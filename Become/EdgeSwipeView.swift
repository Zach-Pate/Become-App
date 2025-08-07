import SwiftUI

/// A view that provides invisible edge areas for swipe gestures.
struct EdgeSwipeView: View {
    @Binding var selectedDate: Date
    let dateRange: [Date]
    @Binding var swipeDirection: Edge
    
    // The width of the area on the screen edges that will detect the swipe.
    private let edgeWidth: CGFloat = 40.0
    // The minimum drag distance required to trigger a swipe.
    private let minDragDistance: CGFloat = 50.0
    
    var body: some View {
        HStack {
            // Left edge for swiping to the previous day.
            Color.black.opacity(0.001)
                .frame(width: edgeWidth)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width > minDragDistance {
                                if let currentIndex = dateRange.firstIndex(of: selectedDate), currentIndex > 0 {
                                    withAnimation(.easeInOut) {
                                        swipeDirection = .trailing
                                        selectedDate = dateRange[currentIndex - 1]
                                    }
                                }
                            }
                        }
                )
            
            Spacer()
            
            // Right edge for swiping to the next day.
            Color.black.opacity(0.001)
                .frame(width: edgeWidth)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -minDragDistance {
                                if let currentIndex = dateRange.firstIndex(of: selectedDate), currentIndex < dateRange.count - 1 {
                                    withAnimation(.easeInOut) {
                                        swipeDirection = .leading
                                        selectedDate = dateRange[currentIndex + 1]
                                    }
                                }
                            }
                        }
                )
        }
    }
}
