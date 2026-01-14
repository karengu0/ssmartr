import SwiftUI
import SwiftData

private struct BubbleFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct SideCategoryBubbles: View {
    let categories: [Category]
    // Split categories roughly half left, half right
    private var left: [Category] { Array(categories.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }) }
    private var right: [Category] { Array(categories.enumerated().filter { $0.offset % 2 == 1 }.map { $0.element }) }

    // Coordinate space name used for measuring frames
    var coordinateSpaceName: String = "HitSpace"

    // Closures to report bubble frames for hit-testing
    var onLeftBubbleFrames: (([UUID: CGRect]) -> Void)?
    var onRightBubbleFrames: (([UUID: CGRect]) -> Void)?

    // Tap handler to categorize by tapping a bubble
    var onTapCategory: ((Category) -> Void)?

    // Optional highlighting state passed in to indicate which bubble is highlighted
    var highlightedLeftIDs: Set<UUID> = []
    var highlightedRightIDs: Set<UUID> = []

    var body: some View {
        GeometryReader { geo in
            HStack {
                VStack(spacing: 24) {
                    ForEach(left) { category in
                        bubble(for: category, highlighted: highlightedLeftIDs.contains(category.id))
                    }
                    Spacer()
                }
                .frame(width: 100)
                .onPreferenceChange(BubbleFramePreferenceKey.self) { frames in
                    var filtered: [UUID: CGRect] = [:]
                    for (key, rect) in frames {
                        if left.contains(where: { $0.id == key }) {
                            filtered[key] = rect
                        }
                    }
                    onLeftBubbleFrames?(filtered)
                }

                Spacer()

                VStack(spacing: 24) {
                    ForEach(right) { category in
                        bubble(for: category, highlighted: highlightedRightIDs.contains(category.id))
                    }
                    Spacer()
                }
                .frame(width: 100)
                .onPreferenceChange(BubbleFramePreferenceKey.self) { frames in
                    var filtered: [UUID: CGRect] = [:]
                    for (key, rect) in frames {
                        if right.contains(where: { $0.id == key }) {
                            filtered[key] = rect
                        }
                    }
                    onRightBubbleFrames?(filtered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 20)
        }
    }

    private func bubble(for category: Category, highlighted: Bool) -> some View {
        let categoryColor = colorFromHex(category.colorHex)
        let bubbleCore = ZStack {
            Text(category.emoji)
                .font(.system(size: 36))
        }
        .frame(width: 72, height: 72)
        .background(
            Circle()
                .fill(highlighted ? categoryColor : Color(.systemGray5))
        )
        .overlay(
            Circle()
                .stroke(highlighted ? categoryColor.opacity(0.8) : Color.clear, lineWidth: highlighted ? 3 : 0)
        )
        .scaleEffect(highlighted ? 1.20 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: highlighted)
        .overlay(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: BubbleFramePreferenceKey.self, value: [category.id: proxy.frame(in: .named(coordinateSpaceName))])
            }
        )
        .contentShape(Circle())

        if let onTap = onTapCategory {
            return AnyView(
                Button(action: {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onTap(category)
                }) {
                    bubbleCore
                }
                .buttonStyle(.plain)
            )
        } else {
            return AnyView(bubbleCore)
        }
    }
}

extension View {
    func onCategoryBubbleFrames(_ action: @escaping ([UUID: CGRect]) -> Void) -> some View {
        self.onPreferenceChange(BubbleFramePreferenceKey.self) { frames in
            action(frames)
        }
    }
}

private func colorFromHex(_ hex: String) -> Color {
    var hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hexSanitized.count {
    case 3: // RGB (12-bit)
        (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
        (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
        (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
        return Color(.systemGray5)
    }
    return Color(
        .sRGB,
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue: Double(b) / 255,
        opacity: Double(a) / 255
    )
}
