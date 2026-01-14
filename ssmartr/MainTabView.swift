//
//  MainTabView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
#if DEBUG
    @State private var showDebugMenu = false
#endif

    var body: some View {
        NavigationStack {
            TabView {

                OverviewTabView()
                    .tabItem {
                        Image(systemName: "chart.pie")
                        Text("Overview")
                    }
                
                TransactionTabView()
                    .tabItem {
                        Image(systemName: "square.and.pencil")
                        Text("Categorize")
                    }

                SettingsTabView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
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
    }
}
