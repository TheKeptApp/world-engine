import SwiftUI

/// The required OpenStreetMap attribution. `WorldView` draws it automatically; apps that render
/// the world in their own view must show this whenever the world is visible.
public struct WorldAttributionView: View {
    public static let text = "© OpenStreetMap contributors"
    public static let url = URL(string: "https://www.openstreetmap.org/copyright")!

    public init() {}

    public var body: some View {
        Link(destination: Self.url) {
            // Fixed colors so it stays legible over any map and in light or dark mode.
            Text(Self.text)
                .font(.caption2)
                .foregroundStyle(Color.black.opacity(0.85))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
        }
        .tint(.black)
        .accessibilityLabel("Map data © OpenStreetMap contributors")
    }
}
