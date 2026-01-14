//
//  OnboardingTabView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var step: Int = 0

    var body: some View {
        TabView(selection: $step) {
            OnboardingConnectBanksStep(onContinue: { step = 1 })
                .tag(0)
            OnboardingCategoriesStep(onContinue: { step = 2 })
                .tag(1)
            OnboardingDoneStep(onFinish: {
                hasCompletedOnboarding = true
            })
                .tag(2)
        }
        .tabViewStyle(.page)
    }
}
