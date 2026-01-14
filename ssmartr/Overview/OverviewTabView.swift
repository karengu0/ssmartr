//
//  OverviewTabView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData
import Combine

private func colorFromHex(_ hex: String) -> Color {
    var hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hexSanitized.count {
    case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
        return Color(.systemGray5)
    }
    return Color(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
}

struct OverviewTabView: View {
    @Query(sort: \Category.createdAt) private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var updateTracker = TransactionUpdateTracker.shared
    
    // Use @State with manual fetching instead of @Query to get fresh data after property changes
    @State private var transactions: [Transaction] = []
    @State private var refreshID = UUID()
    @State private var forceRefresh = false
    
    private var categoryList: [Category] {
        Array(categories)
    }
    
    // Manually fetch transactions to get fresh data after property changes
    // SwiftData's @Query doesn't detect when properties of existing transactions change
    @MainActor
    private func refreshTransactions() async {
        // Small delay to ensure save has propagated to the persistent store
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds (increased)
        
        // Process any pending changes
        modelContext.processPendingChanges()
        
        // Calculate signature before update to detect if anything changed
        let oldSignature = categoryIDSignature
        
        // Fetch fresh data from the model context
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.transactionDate, order: .reverse)]
        )
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        
        // Calculate new signature
        let newSignature = fetched.map { "\($0.id.uuidString):\($0.categoryID?.uuidString ?? "nil")" }.sorted().joined(separator: "|")
        
        // Force state update by explicitly creating a new array reference
        // This ensures SwiftUI detects the change even if objects are the same
        transactions = Array(fetched)
        
        // Force forceRefresh toggle to ensure categoryStats recalculates
        forceRefresh.toggle()
        
        print("Refreshed transactions: \(fetched.count) total, categorized: \(fetched.filter { $0.categoryID != nil }.count)")
        print("Signature changed: \(oldSignature != newSignature)")
        
        // If signature changed, we've already updated transactions and toggled forceRefresh
        // The refreshID update will happen in the onChange handler
    }
    
    // Create a signature of categoryIDs to detect changes
    // This helps SwiftUI detect when transaction categoryIDs change
    private var categoryIDSignature: String {
        // Create a hash of all transaction IDs and their categoryIDs
        let signature = transactions.map { tx in
            "\(tx.id.uuidString):\(tx.categoryID?.uuidString ?? "nil")"
        }.sorted().joined(separator: "|")
        return signature
    }
    
    // Computed property to ensure SwiftUI tracks the dependency on transactions
    // This will automatically recalculate when transactions change (e.g., when categoryID is updated)
    // The forceRefresh variable ensures recalculation even when SwiftData doesn't detect changes
    private var categoryStats: [UUID: (budgeted: Double, spent: Double, left: Double)] {
        // Access forceRefresh to ensure this computed property recalculates when it changes
        // Also explicitly access transactions to ensure dependency tracking
        let _ = forceRefresh
        let _ = transactions.count // Ensure we track transactions dependency
        let fakeMonthlyIncome = 2000.0
        
        var stats: [UUID: (budgeted: Double, spent: Double, left: Double)] = [:]
        
        // Explicitly iterate through categories to ensure dependency tracking
        for category in categories {
            // Budgeted amount for this category (monthly)
            let budgeted = fakeMonthlyIncome * category.percent
            
            // Filter transactions for this category - ALL categorized transactions
            // Only count spending (negative amounts), not income
            // Sum ALL transactions regardless of date
            let txs = transactions.filter { tx in
                tx.categoryID == category.id 
                && tx.amountCents < 0
            }
            
            // Sum up the absolute values of spending amounts
            // This is the total amount spent in this category (all categorized transactions)
            let spent = txs.reduce(0.0) { partial, tx in
                partial + Double(abs(tx.amountCents)) / 100.0
            }
            
            // Calculate amount left to spend = Budgeted - Spent
            let left = budgeted - spent
            
            stats[category.id] = (budgeted, spent, left)
        }
        
        return stats
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(currentMonthString)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(categoryList, id: \.id) { (cat: Category) in
                            let stats = categoryStats[cat.id] ?? (budgeted: 0, spent: 0, left: 0)
                            
                            NavigationLink {
                                TransactionsInCategory(category: cat)
                            } label: {
                                CategoryCard(category: cat, stats: stats)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .navigationTitle("Overview")
            .id(refreshID) // Force view refresh when refreshID changes
            .task {
                // Initial load of transactions
                await refreshTransactions()
            }
            .onChange(of: updateTracker.updateTrigger) { _ in
                // Update when tracker triggers an update - manually fetch fresh data
                Task { @MainActor in
                    await refreshTransactions()
                    // Force view refresh - refreshTransactions already toggled forceRefresh
                    refreshID = UUID()
                }
            }
            .onChange(of: categoryIDSignature) { _ in
                // Update when any transaction's categoryID changes
                forceRefresh.toggle()
                refreshID = UUID()
            }
            .onChange(of: transactions.count) { _ in
                // Also update when transaction count changes (transactions added/removed)
                forceRefresh.toggle()
                refreshID = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionCategorized)) { _ in
                // Force refresh when a transaction is categorized - manually fetch fresh data
                Task { @MainActor in
                    await refreshTransactions()
                    // Force view refresh - refreshTransactions already toggled forceRefresh
                    refreshID = UUID()
                }
            }
        }
    }

    // MARK: - Helpers
    
    private var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: Date())
    }
}

struct CategoryCard: View {
    let category: Category
    let stats: (budgeted: Double, spent: Double, left: Double)
    
    var body: some View {
        GeometryReader { geo in
            let total = max(stats.budgeted, 0.01)
            let left = max(stats.left, 0)
            let spent = max(stats.spent, 0)
            let spentRatio = min(max(spent / total, 0), 1)
            let leftRatio = min(max(left / total, 0), 1)
            let cardColor = colorFromHex(category.colorHex)
            let greyHeight = geo.size.height * spentRatio
            // Colored height fills remaining space to ensure no gaps
            let coloredHeight = geo.size.height - greyHeight
            
            ZStack(alignment: .topLeading) {
                // Vertical bar graph: grey (spent) at top, colored (left) at bottom
                VStack(spacing: 0) {
                    // Grey portion for spent amount
                    if greyHeight > 0 {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: greyHeight)
                    }
                    
                    // Colored portion for money left - fills remaining space to ensure total height
                    Rectangle()
                        .fill(cardColor)
                        .frame(height: coloredHeight)
                }
                .frame(height: geo.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Category emoji and name at upper left
                HStack(spacing: 6) {
                    Text(category.emoji)
                        .font(.title3)
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.leading, 12)
                .padding(.top, 12)
                
                // White text showing dollar amount left - vertically centered, left-aligned
                VStack {
                    Spacer()
                    HStack {
                        Text("$\(Int(left))")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.leading, 12)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
        .frame(height: 156)
    }
}

