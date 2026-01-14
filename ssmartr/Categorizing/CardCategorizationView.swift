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
        VStack(spacing: 16) {
            if transactions.isEmpty {
                Text("No uncategorized transactions 🎉")
                    .padding()
            } else {
                let tx = transactions.first!
                VStack(alignment: .center, spacing: 12) {
                    // Vendor (top)
                    Text(tx.vendor)
                        .font(.title3)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Dollar amount (middle)
                    Text("$\(Double(tx.amountCents) / 100.0, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Date (bottom)
                    if let date = tx.postedDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(tx.transactionDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 6, y: 3)
            }
        }
    }
}

