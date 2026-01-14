//
//  DebugMenu.swift
//  ssmartr
//
//  Created by Karen Guo on 11/14/25.
//

#if DEBUG
import SwiftUI
import SwiftData

struct DebugMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Transactions") {
                    Button("Generate 10 uncategorized transactions") {
                        generateSampleTransactions(count: 10)
                        dismiss()
                    }
                    Button("Reset demo data (delete all + seed 12)") {
                        resetDemoDataAndSeed()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Debug Menu")
        }
    }

    private func generateSampleTransactions(count: Int) {
        let vendors = ["Peet's Coffee", "Costco", "Lyft", "Spotify", "Whole Foods", "REI", "Target"]
        for i in 0..<count {
            let tx = Transaction(
                id: UUID(),
                vendor: vendors.randomElement() ?? "Vendor \(i)",
                amountCents: Int64(Int.random(in: 199...5999)),
                transactionDate: daysAgo(10),
                postedDate: Calendar.current.date(byAdding: .day, value: -i, to: Date()),
                source: "Credit Card",
                categoryID: nil // keep uncategorized
            )
            modelContext.insert(tx)
        }
        try? modelContext.save()
    }

    private func resetDemoDataAndSeed() {
        do {
            // Delete all transactions
            let descriptor = FetchDescriptor<Transaction>()
            let all = try modelContext.fetch(descriptor)
            all.forEach(modelContext.delete)
            try modelContext.save()

            // Seed 12 fresh uncategorized
            generateSampleTransactions(count: 12)
        } catch {
            // For debug UI, a simple print is fine
            print("Failed to reset demo data: \(error)")
        }
    }
}

// MARK: - Helper for Dates
private func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: Date())!
}

#endif

