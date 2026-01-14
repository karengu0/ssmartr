//
//  NewCategoryView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct NewCategoryView: View {
    @Environment(\.modelContext) private var modelContext

    // Fields the user edits
    @State private var name: String = ""
    @State private var emoji: String = "📁"
    @State private var color: Color = .blue
    @State private var percent: Double = 0.1   // 10%

    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Name") {
                TextField("Category name", text: $name)
            }

            Section("Emoji") {
                TextField("Emoji", text: $emoji)
                    .font(.largeTitle)
            }

            Section("Color") {
                ColorPicker("Pick a color", selection: $color)
            }

            Section("Percent of Paycheck") {
                VStack(alignment: .leading) {
                    Slider(value: $percent, in: 0...1, step: 0.01)
                    Text("\(Int(percent * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Create Category") {
                    createCategory()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("New Category")
    }

    // MARK: - Logic

    private func createCategory() {
        let newCat = Category(
            name: name,
            emoji: emoji,
            colorHex: color.toHexString(),
            percent: percent
        )

        modelContext.insert(newCat)

        // Save to SwiftData
        do {
            try modelContext.save()
        } catch {
            print("Failed to save category: \(error)")
        }

        onDone()
    }
}
