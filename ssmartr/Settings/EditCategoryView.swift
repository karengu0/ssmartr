//
//  EditCategoryView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct EditCategoryView: View {
    @Bindable var category: Category   // <-- this lets us edit the Category

    var body: some View {
        Form {
            Section("Category") {
                TextField("Name", text: $category.name)
                TextField("Emoji", text: $category.emoji)
                TextField("Color (hex)", text: $category.colorHex)
                Slider(value: $category.percent, in: 0...100, step: 1) {
                    Text("Paycheck %")
                }
                Text("\(Int(category.percent))% of each paycheck")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Edit Category")
    }
}
