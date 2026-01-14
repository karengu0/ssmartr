//
//  MainTabView.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
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
}
