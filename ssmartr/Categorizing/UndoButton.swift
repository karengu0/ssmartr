//
//  UndoButton.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI

struct UndoButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text("Undo")
                .padding(6)
        }
    }
}
