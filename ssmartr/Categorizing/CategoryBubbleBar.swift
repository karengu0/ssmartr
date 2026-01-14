//
//  CategoryBubbleBar.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct CategoryBubbleBar: View {
    let categories: [Category]
    let onTapCategory: (Category) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    Button {
                        onTapCategory(category)
                    } label: {
                        Text(category.emoji)
                            .font(.title2)
                            .padding(10)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
