import SwiftUI
import WorldEngine

/// Empty shell: no 3D world yet. The map view replaces the placeholder in the rendering step.
struct ContentView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 8) {
                Text("WorldLab")
                    .font(.largeTitle.weight(.semibold))
                Text("No world loaded yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            WorldAttributionView()
                .padding(8)
        }
    }
}

#Preview {
    ContentView()
}
