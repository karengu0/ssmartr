//
//  TransactionsInCategory.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData
import Combine

struct TransactionsInCategory: View {
    let category: Category
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var updateTracker = TransactionUpdateTracker.shared
    @State private var refreshID = UUID()
    @State private var forceRefresh = false
    
    // Use @State with manual fetching instead of @Query to get fresh data after property changes
    @State private var allTransactions: [Transaction] = []
    
    // Manually fetch transactions to get fresh data after property changes
    // SwiftData's @Query doesn't detect when properties of existing transactions change
    @MainActor
    private func refreshTransactions() async {
        // Small delay to ensure save has propagated to the persistent store
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds (increased)
        
        // Process any pending changes
        modelContext.processPendingChanges()
        
        // Fetch fresh data from the model context
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.postedDate, order: .reverse)]
        )
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        
        // Force state update by explicitly creating a new array reference
        // This ensures SwiftUI detects the change even if objects are the same
        allTransactions = Array(fetched)
        
        // Force forceRefresh toggle to ensure stats recalculates
        forceRefresh.toggle()
        
        print("Refreshed transactions in category view: \(fetched.count) total, in category: \(fetched.filter { $0.categoryID == category.id }.count)")
    }

    // Filter down to just this category's transactions in plain Swift
    private var transactions: [Transaction] {
        allTransactions.filter { $0.categoryID == category.id }
    }
    
    // Calculate stats based on current transactions
    // The forceRefresh variable ensures recalculation even when SwiftData doesn't detect changes
    private var stats: (budgeted: Double, spent: Double, left: Double) {
        // Access forceRefresh to ensure this computed property recalculates when it changes
        let _ = forceRefresh
        let fakeMonthlyIncome = 2000.0
        
        // Budgeted amount for this category (monthly)
        let budgeted = fakeMonthlyIncome * category.percent
        
        // Filter transactions for this category - ALL categorized transactions
        // Only count spending (negative amounts), not income
        // Note: transactions already filtered by categoryID, so we just need to filter by amount
        // Sum ALL transactions regardless of date
        let txs = transactions.filter { tx in
            tx.amountCents < 0
        }
        
        // Sum up the absolute values of spending amounts
        // This is the total amount spent in this category (all categorized transactions)
        let spent = txs.reduce(0.0) { partial, tx in
            partial + Double(abs(tx.amountCents)) / 100.0
        }
        
        // Calculate amount left to spend = Budgeted - Spent
        let left = budgeted - spent
        
        return (budgeted, spent, left)
    }

    var body: some View {
        List {
            Section(header: headerView) { }

            Section("Transactions") {
                // Use enumerated() → Array so ForEach is happy with the type
                ForEach(Array(transactions.enumerated()), id: \.element.id) { _, tx in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tx.vendor)
                            .font(.headline)

                        // postedDate is optional → safely unwrap
                        if let posted = tx.postedDate {
                            Text(posted.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text("$\(formatCents(Int(tx.amountCents)))")
                            .font(.body)
                            .foregroundColor(tx.amountCents < 0 ? .red : .green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("\(category.emoji) \(category.name)")
        .id(refreshID)
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
        .onReceive(NotificationCenter.default.publisher(for: .transactionCategorized)) { _ in
            // Force refresh when a transaction is categorized - manually fetch fresh data
            Task { @MainActor in
                await refreshTransactions()
                // Force view refresh - refreshTransactions already toggled forceRefresh
                refreshID = UUID()
            }
        }
        .onChange(of: allTransactions.count) { _ in
            // Update when transaction count changes
            forceRefresh.toggle()
            refreshID = UUID()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(category.emoji) \(category.name)")
                .font(.largeTitle)
                .bold()

            Text("Budgeted: $\(Int(stats.budgeted))")
            Text("Spent: $\(Int(stats.spent))")
            Text("Left: $\(Int(stats.left))")
                .foregroundStyle(stats.left >= 0 ? .green : .red)
        }
        .padding(.vertical)
    }

    // MARK: - Helpers

    private func formatCents(_ cents: Int) -> String {
        String(format: "%.2f", Double(cents) / 100.0)
    }
}
