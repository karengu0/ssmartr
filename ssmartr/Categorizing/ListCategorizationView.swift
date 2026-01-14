//
//  ListCategorizationView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct ListCategorizationView: View {
    let transactions: [Transaction]
    let categories: [Category]
    @Binding var selected: Set<UUID>
    let onCategorize: (_ transactionIDs: [UUID], _ category: Category) -> Void

    var body: some View {
        List(transactions, id: \.id, selection: $selected) { tx in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tx.vendor)
                        .font(.headline)
                    Spacer()
                    Text("$\(Double(tx.amountCents) / 100.0, specifier: "%.2f")")
                        .font(.subheadline)
                }
                Text(tx.transactionDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Toggle selection on tap (single-select or multi-select)
                if selected.contains(tx.id) {
                    selected.remove(tx.id)
                } else {
                    selected.insert(tx.id)
                }
            }
        }
        .environment(\.editMode, .constant(.active))
    }
}
