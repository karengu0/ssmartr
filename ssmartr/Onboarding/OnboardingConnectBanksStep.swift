//
//  OnboardingConnectBanksStep.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI

struct OnboardingConnectBanksStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Connect your banks")
                .font(.title)
                .bold()

            Text("In the future, this is where we’ll show the Plaid flow so you can link your credit cards and checking accounts.")
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
