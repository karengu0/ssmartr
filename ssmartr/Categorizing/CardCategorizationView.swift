//
//  CardCategorizationView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct CardCategorizationView: View {
    let transactions: [Transaction]
    let categories: [Category]
    let onCategorize: (_ transactionIDs: [UUID], _ category: Category) -> Void

    var body: some View {
        // TEMP: just show the first uncategorized transaction as text
        if let tx = transactions.first {
            VStack(spacing: 12) {
                Text("Card view placeholder")
                    .font(.headline)

                Text("Next transaction:")
                Text("\(tx.vendor) • $\(Double(tx.amountCents) / 100.0, specifier: "%.2f")")
                    .font(.title3)

                Text("Later we’ll put the map + card design here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            Text("No uncategorized transactions 🎉")
                .padding()
        }
    }
}
