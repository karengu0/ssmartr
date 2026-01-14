//
//  OverviewTabView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct OverviewTabView: View {
    @Query(sort: \Category.createdAt) private var categories: [Category]
    @Query private var transactions: [Transaction]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.id) { cat in
                    let stats = statsFor(category: cat)

                    NavigationLink {
                        TransactionsInCategory(category: cat, stats: stats)
                    } label: {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("\(cat.emoji) \(cat.name)")
                                    .font(.headline)
                                Spacer()
                                Text("$\(Int(stats.left)) left")
                                    .foregroundStyle(.green)
                            }

                            Text("Spent $\(Int(stats.spent)) of $\(Int(stats.budgeted))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Overview")
        }
    }

    private func statsFor(category: Category) -> (budgeted: Double, spent: Double, left: Double) {
        // For now, fake budget as a fixed monthly income * percent
        let fakeMonthlyIncome = 5000.0
        let budgeted = fakeMonthlyIncome * category.percent

        let txs = transactions.filter {
            $0.categoryID == category.id && $0.amountCents < 0
        }

        let spent = txs.reduce(0.0) { partial, tx in
            partial + Double(abs(tx.amountCents)) / 100.0
        }

        return (budgeted, spent, budgeted - spent)
    }
}

