//
//  TransactionTabView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//  The middle page in the bottom menu. Land on per-card view to ctegorize. Can toggle to list-view.

import SwiftUI
import SwiftData

private struct CardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

enum TransactionViewMode: String, CaseIterable {
    case card = "Card"
    case list = "List"
}

struct TransactionTabView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Transaction> { tx in
            tx.categoryID == nil && (tx.isIgnored ?? false) == false
        },
        sort: \Transaction.transactionDate,
        order: .reverse
    )

    private var uncategorized: [Transaction]

    @Query(sort: \Category.createdAt) private var categories: [Category]

    @State private var mode: TransactionViewMode = .card
    @State private var searchText = ""
    @State private var selectedTransactions = Set<UUID>()
    @State private var lastCategorized: (transactionIDs: [UUID], categoryID: UUID)? = nil

    // Drag state for card mode
    @State private var cardDrag: CGSize = .zero
    @State private var bubbleFrames: [UUID: CGRect] = [:]
    @State private var leftBubbleFrames: [UUID: CGRect] = [:]
    @State private var rightBubbleFrames: [UUID: CGRect] = [:]
    @State private var highlightedBubbleID: UUID? = nil
    @State private var isHoveringBubble: Bool = false
    @State private var lastHoverBubbleID: UUID? = nil

    @State private var lastCardGlobalRect: CGRect = .zero

    var body: some View {
        NavigationStack {
            VStack {
                // Toggle: Card / List
                Picker("", selection: $mode) {
                    ForEach(TransactionViewMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if mode == .card {
                    let coordinateSpaceName = "HitSpace"
                    ZStack {
                        // Side bubbles in the background that report their frames
                        SideCategoryBubbles(
                            categories: categories,
                            coordinateSpaceName: coordinateSpaceName,
                            onLeftBubbleFrames: { frames in
                                leftBubbleFrames = frames
                                bubbleFrames = frames.merging(rightBubbleFrames, uniquingKeysWith: { $1 })
                            },
                            onRightBubbleFrames: { frames in
                                rightBubbleFrames = frames
                                bubbleFrames = leftBubbleFrames.merging(frames, uniquingKeysWith: { $1 })
                            },
                            onTapCategory: { category in
                                let ids = filteredTransactions.first.map { [$0.id] } ?? []
                                categorizeTransactions(transactionIDs: ids, into: category)
                            },
                            highlightedLeftIDs: highlightedBubbleID.map { Set([$0]) } ?? [],
                            highlightedRightIDs: highlightedBubbleID.map { Set([$0]) } ?? []
                        )

                        GeometryReader { geo in
                            // Account for bubble areas on left and right (reduced spacing)
                            let bubbleAreaWidth: CGFloat = 100
                            let availableWidth = geo.size.width - (bubbleAreaWidth * 2)
                            let centerX = geo.size.width / 2
                            let centerY = geo.size.height / 2
                            let center = CGPoint(x: centerX, y: centerY)
                            
                            // Vertical rectangle dimensions - wider card with less horizontal space from bubbles
                            let cardWidth = min(availableWidth * 0.85, 320)
                            let cardHeight = min(geo.size.height * 0.5, 320)

                            ZStack {
                                CardCategorizationView(
                                    transactions: Array(filteredTransactions.prefix(1)),
                                    categories: categories,
                                    onCategorize: categorizeTransactions
                                )
                                .frame(width: cardWidth, height: cardHeight)
                            }
                            .position(
                                x: centerX + cardDrag.width,
                                y: centerY + cardDrag.height
                            )
                            .scaleEffect(highlightedBubbleID != nil ? 1.05 : 1.0)
                            .background(
                                GeometryReader { cardGeo in
                                    Color.clear
                                        .preference(key: CardFramePreferenceKey.self, value: cardGeo.frame(in: .named(coordinateSpaceName)))
                                }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Allow free dragging so card can be dragged over bubbles for categorization
                                        cardDrag = value.translation
                                    }
                                    .onEnded { _ in
                                        // Only do hit testing if we have valid bubble frames
                                        guard !bubbleFrames.isEmpty else {
                                            // No valid data - float back to center smoothly
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                cardDrag = .zero
                                            }
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                highlightedBubbleID = nil
                                                lastHoverBubbleID = nil
                                            }
                                            return
                                        }
                                        
                                        // Calculate actual card center during drag for hit testing
                                        // Use the known center position + drag offset
                                        let actualCardCenter = CGPoint(
                                            x: centerX + cardDrag.width,
                                            y: centerY + cardDrag.height
                                        )

                                        // 1) Prefer nearest bubble by distance within a threshold
                                        let nearest = bubbleFrames.min { a, b in
                                            let ac = CGPoint(x: a.value.midX, y: a.value.midY)
                                            let bc = CGPoint(x: b.value.midX, y: b.value.midY)
                                            let adx = ac.x - actualCardCenter.x
                                            let ady = ac.y - actualCardCenter.y
                                            let bdx = bc.x - actualCardCenter.x
                                            let bdy = bc.y - actualCardCenter.y
                                            return (adx*adx + ady*ady) < (bdx*bdx + bdy*bdy)
                                        }

                                        var chosenID: UUID? = nil
                                        if let nearest = nearest {
                                            let ac = CGPoint(x: nearest.value.midX, y: nearest.value.midY)
                                            let dx = ac.x - actualCardCenter.x
                                            let dy = ac.y - actualCardCenter.y
                                            let distance = sqrt(dx*dx + dy*dy)
                                            if distance <= 120 { // threshold radius
                                                chosenID = nearest.key
                                            }
                                        }

                                        // 2) Fallback: inflated rect intersection (using actual dragged position)
                                        if chosenID == nil {
                                            let cardHalfWidth = cardWidth / 2
                                            let cardHalfHeight = cardHeight / 2
                                            let draggedCardRect = CGRect(
                                                x: actualCardCenter.x - cardHalfWidth,
                                                y: actualCardCenter.y - cardHalfHeight,
                                                width: cardWidth,
                                                height: cardHeight
                                            )
                                            chosenID = bubbleFrames.first { (_, frame) in
                                                frame.insetBy(dx: -24, dy: -24).intersects(draggedCardRect)
                                            }?.key
                                        }

                                        // Only categorize and provide haptic if a bubble was actually hit
                                        if let hitCategoryID = chosenID,
                                           let bubbleRect = bubbleFrames[hitCategoryID] {
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            
                                            // Animate card toward bubble briefly, then categorize
                                            let bubbleCenter = CGPoint(x: bubbleRect.midX, y: bubbleRect.midY)
                                            let cardCenter = actualCardCenter
                                            let direction = CGSize(
                                                width: bubbleCenter.x - cardCenter.x,
                                                height: bubbleCenter.y - cardCenter.y
                                            )
                                            
                                            withAnimation(.easeIn(duration: 0.15)) {
                                                cardDrag.width += direction.width * 0.3
                                                cardDrag.height += direction.height * 0.3
                                            }
                                            
                                            // Categorize the transaction
                                            if let category = categories.first(where: { $0.id == hitCategoryID }) {
                                                let ids = filteredTransactions.first.map { [$0.id] } ?? []
                                                categorizeTransactions(transactionIDs: ids, into: category)
                                            }
                                            
                                            // Reset drag after categorization (card will disappear from list)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    cardDrag = .zero
                                                }
                                            }
                                            
                                            // Reset highlighting immediately
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                highlightedBubbleID = nil
                                                lastHoverBubbleID = nil
                                            }
                                        } else {
                                            // No bubble hit - float back to center smoothly
                                            // No haptic feedback
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                cardDrag = .zero
                                            }
                                            
                                            // Reset highlighting
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                highlightedBubbleID = nil
                                                lastHoverBubbleID = nil
                                            }
                                        }
                                    }
                            )
                            .onPreferenceChange(CardFramePreferenceKey.self) { rect in
                                lastCardGlobalRect = rect
                            }
                            .onChange(of: cardDrag) { _ in
                                // Only check proximity if we have valid bubble frames
                                guard !bubbleFrames.isEmpty else {
                                    // Clear highlighting if we don't have valid data
                                    if highlightedBubbleID != nil {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            highlightedBubbleID = nil
                                            lastHoverBubbleID = nil
                                        }
                                    }
                                    return
                                }
                                
                                // Check bubble proximity during drag
                                // Calculate actual card center using known center position + drag
                                let actualCardCenter = CGPoint(
                                    x: centerX + cardDrag.width,
                                    y: centerY + cardDrag.height
                                )
                                
                                // Find the nearest bubble within threshold
                                let proximityThreshold: CGFloat = 100 // Increased threshold for better UX
                                var nearestBubble: (id: UUID, distance: CGFloat)? = nil
                                
                                for (bubbleID, frame) in bubbleFrames {
                                    let bubbleCenter = CGPoint(x: frame.midX, y: frame.midY)
                                    let dx = bubbleCenter.x - actualCardCenter.x
                                    let dy = bubbleCenter.y - actualCardCenter.y
                                    let distance = sqrt(dx*dx + dy*dy)
                                    
                                    if distance <= proximityThreshold {
                                        if nearestBubble == nil || distance < nearestBubble!.distance {
                                            nearestBubble = (bubbleID, distance)
                                        }
                                    }
                                }
                                
                                if let nearest = nearestBubble {
                                    if highlightedBubbleID != nearest.id {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            highlightedBubbleID = nearest.id
                                        }
                                        if lastHoverBubbleID != nearest.id {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            lastHoverBubbleID = nearest.id
                                        }
                                    }
                                } else {
                                    if highlightedBubbleID != nil {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            highlightedBubbleID = nil
                                            lastHoverBubbleID = nil
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .coordinateSpace(name: coordinateSpaceName)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Status: N selected (only if more than 1)
                    if selectedTransactions.count > 1 {
                        HStack {
                            Text("\(selectedTransactions.count) transactions selected")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }

                    ListCategorizationView(
                        transactions: filteredTransactions,
                        categories: categories,
                        selected: $selectedTransactions,
                        onCategorize: categorizeTransactions
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }

                Text("Uncategorized count: \(uncategorized.count)")
                    .padding(.vertical, 8)

                if mode == .list {
                    CategoryBubbleBar(categories: categories) { category in
                        let ids = Array(selectedTransactions)
                        categorizeTransactions(transactionIDs: ids, into: category)
                    }
                    .padding(.bottom, 8)
                }
            }
            .onChange(of: mode) { newMode in
                if newMode == .list { ensureDefaultSelection() }
            }
            .onChange(of: filteredTransactions) { _ in
                ensureDefaultSelection()
            }
            .navigationTitle("Categorize")
            .searchable(text: $searchText, prompt: "Vendor or amount")
            .toolbar {
                if mode == .list && !selectedTransactions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear selection") {
                            selectedTransactions.removeAll()
                        }
                    }
                }
                if lastCategorized != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        UndoButton {
                            undoLastCategorization()
                        }
                    }
                }
            }
            .task {
                ensureDefaultSelection()
            }
        }
        .onChange(of: bubbleFrames) { newValue in
            // Removed debug prints; logic remains the same if any.
        }
    }

    private var filteredTransactions: [Transaction] {
        guard !searchText.isEmpty else { return uncategorized }

        return uncategorized.filter { tx in
            let amt = Double(tx.amountCents) / 100.0
            return tx.vendor.localizedCaseInsensitiveContains(searchText)
                || String(format: "%.2f", abs(amt)).contains(searchText)
        }
    }

    private func categorizeTransactions(transactionIDs: [UUID], into category: Category) {
        guard !transactionIDs.isEmpty else { return }

        let toUpdate = uncategorized.filter { transactionIDs.contains($0.id) }
        for tx in toUpdate {
            tx.categoryID = category.id
        }
        
        // Process pending changes and save to SwiftData
        modelContext.processPendingChanges()
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
        
        // Trigger update immediately and via notification
        Task { @MainActor in
            // Small delay to ensure SwiftData save has propagated to all queries
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            TransactionUpdateTracker.shared.triggerUpdate()
            NotificationCenter.default.post(name: .transactionCategorized, object: nil)
        }
        
        lastCategorized = (transactionIDs, category.id)
        selectedTransactions.removeAll()
        
        // Reset highlighting state
        highlightedBubbleID = nil
        lastHoverBubbleID = nil

        // haptics placeholder: real haptics later
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func undoLastCategorization() {
        guard let info = lastCategorized else { return }

        // 1. Fetch all transactions from SwiftData
        let descriptor = FetchDescriptor<Transaction>()   // requires `import SwiftData` at top
        let allTransactions = (try? modelContext.fetch(descriptor)) ?? []

        // 2. Keep only the ones whose IDs we last categorized
        let toUpdate = allTransactions.filter { info.transactionIDs.contains($0.id) }

        // 3. Clear their category and reset the "last" info
        for tx in toUpdate {
            tx.categoryID = nil
        }
        
        // Process pending changes and save to SwiftData
        modelContext.processPendingChanges()
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
        
        // Trigger update immediately and via notification
        Task { @MainActor in
            // Small delay to ensure SwiftData save has propagated to all queries
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            TransactionUpdateTracker.shared.triggerUpdate()
            NotificationCenter.default.post(name: .transactionCategorized, object: nil)
        }
        
        lastCategorized = nil
    }

    private func ensureDefaultSelection() {
        guard mode == .list else { return }
        guard selectedTransactions.isEmpty else { return }
        if let first = filteredTransactions.first {
            selectedTransactions.insert(first.id)
        }
    }
}

