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

    // Closures to report bubble frames for hit-testing
    var onLeftBubbleFrames: (([UUID: CGRect]) -> Void)?
    var onRightBubbleFrames: (([UUID: CGRect]) -> Void)?

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
                    // Filter to only left category frames
                    let filtered = frames.filter { categories.contains(where: { $0.id == $0.key && left.contains(where: { $0.id == $0.key }) }) }
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
                    // Filter to only right category frames
                    let filtered = frames.filter { categories.contains(where: { $0.id == $0.key && right.contains(where: { $0.id == $0.key }) }) }
                    onRightBubbleFrames?(filtered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 20)
        }
    }

    private func bubble(for category: Category, highlighted: Bool) -> some View {
        Text(category.emoji)
            .font(.system(size: 36))
            .frame(width: 72, height: 72)
            .background(
                Circle()
                    .fill(highlighted ? Color.accentColor.opacity(0.4) : Color(.systemGray5))
                    .scaleEffect(highlighted ? 1.1 : 1)
                    .animation(.easeInOut(duration: 0.2), value: highlighted)
            )
            .overlay(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: BubbleFramePreferenceKey.self, value: [category.id: proxy.frame(in: .global)])
                }
            )
            .contentShape(Circle())
    }
}

extension View {
    func onCategoryBubbleFrames(_ action: @escaping ([UUID: CGRect]) -> Void) -> some View {
        self.onPreferenceChange(BubbleFramePreferenceKey.self) { frames in
            action(frames)
        }
    }
}
