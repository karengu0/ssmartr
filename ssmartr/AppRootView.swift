//
//  AppRootView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/14/25.
//

import SwiftUI
import SwiftData

struct AppRootView: View {
#if DEBUG
    @State private var showDebugMenu = false
#endif
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var hasSeededMockData = false

    var body: some View {
        NavigationStack {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingFlowView()
                }
            }
        }
#if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Debug") { showDebugMenu = true }
            }
        }
        .sheet(isPresented: $showDebugMenu) {
            DebugMenuView()
        }
#endif
        .task {
            // only run once per app launch
            guard !hasSeededMockData else { return }
            hasSeededMockData = true

            // 👇 call your mock seeding here (adjust to your MockData API)
            await seedMockDataIfNeeded()
        }
    }

    @MainActor
    private func seedMockDataIfNeeded() async {
        do {
            // Only seed if there are no categories yet
            let existingCategories = try modelContext.fetch(FetchDescriptor<Category>())
            if existingCategories.isEmpty {
                MockData.allCategories.forEach { modelContext.insert($0) }
                MockData.transactions.forEach { modelContext.insert($0) }
                try modelContext.save()
            }
        } catch {
            print("Failed to seed mock data: \(error)")
        }
    }

}
