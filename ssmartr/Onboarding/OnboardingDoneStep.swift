//
//  OnboardingDoneStep.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI

struct OnboardingDoneStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("You’re all set!")
                .font(.title)
                .bold()

            Text("Next you’ll start categorizing your transactions and watching your budgets in action.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button("Start using ssmartr") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
