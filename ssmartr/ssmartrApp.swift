//
//  ssmartrApp.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import SwiftUI
import SwiftData

@main
struct ssmartrApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: [Category.self, Transaction.self, BankAccount.self])
    }
}
