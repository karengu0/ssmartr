//
//  OnboardingCategoriesStep.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct OnboardingCategoriesStep: View {
    let onContinue: () -> Void

    // Later this will show real category creation UI.
    var body: some View {
        VStack(spacing: 24) {
            Text("Set up your categories")
                .font(.title)
                .bold()

            Text("Here you’ll create categories, pick emojis and colors, and assign paycheck percentages.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
