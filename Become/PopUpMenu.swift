import SwiftUI

/// A view that displays a set of buttons for a pop-up menu.
struct PopUpMenuButtons: View {
    var onCancel: () -> Void
    var onSave: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            // The cancel button.
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .shadow(radius: 4)
            
            // The save button.
            Button(action: onSave) {
                Image(systemName: "checkmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            .shadow(radius: 4)
        }
        .padding(.trailing)
    }
}

/// A view that displays a pop-up menu with custom content.
struct PopUpMenu<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        if isPresented {
            ZStack {
                // A semi-transparent background that covers the entire screen.
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Dismiss the pop-up when the background is tapped.
                        isPresented = false
                    }
                
                // The main content of the pop-up.
                VStack {
                    content
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 20)
                .padding(.horizontal, 20)
            }
            .zIndex(1) // Ensure the pop-up is on top of other views.
        }
    }
}
