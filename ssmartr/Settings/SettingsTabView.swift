//
//  SettingsTabView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct SettingsTabView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.createdAt) private var categories: [Category]
    @Query(sort: \BankAccount.institutionName) private var accounts: [BankAccount]

    var body: some View {
        NavigationStack {
            Form {
                Section("Categories") {
                    ForEach(categories) { cat in
                        NavigationLink {
                            EditCategoryView(category: cat)
                        } label: {
                            Text("\(cat.emoji) \(cat.name)")
                        }
                    }
                    .onDelete { indexSet in
                        // delete categories here
                    }

                    NavigationLink("Add Category") {
                        NewCategoryView(onDone: {})
                    }
                }

                Section("Banks") {
                    ForEach(accounts) { acct in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(acct.institutionName)
                                Text("\(acct.displayName) ••••\(acct.mask)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if !acct.isActive {
                                Text("Inactive").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button("Connect another bank") {
                        // present Plaid Link here
                    }
                }

            }
            .navigationTitle("Settings")
        }
    }
}
