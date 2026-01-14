//
//  TransactionUpdateTracker.swift
//  ssmartr
//
//  Created to track transaction categorization updates
//

import Foundation
import Combine

@MainActor
class TransactionUpdateTracker: ObservableObject {
    @Published var updateTrigger: UUID = UUID()
    
    static let shared = TransactionUpdateTracker()
    
    private init() {}
    
    func triggerUpdate() {
        updateTrigger = UUID()
    }
}

