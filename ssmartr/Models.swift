//
//  Models.swift
//  ssmartr
//
//  Created by Karen Guo on 11/12/25.
//

import Foundation
import SwiftData

extension Notification.Name {
    static let transactionCategorized = Notification.Name("transactionCategorized")
}

@Model
final class Category: Identifiable {
    @Attribute(.unique) var id: UUID    // 👈 add this line
    var name: String
    var emoji: String
    var colorHex: String
    var percent: Double
    var createdAt: Date

    init(
        name: String,
        emoji: String,
        colorHex: String,
        percent: Double,
        createdAt: Date = .now
    ) {
        self.id = UUID()                // 👈 and this
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.percent = percent
        self.createdAt = createdAt
    }
}



@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var plaidTransactionId: String?
    var accountId: String?          // Plaid account id
    var vendor: String              // merchant name
    var amountCents: Int64          // negative = spend, positive = income
    var transactionDate: Date       // date of purchase
    var postedDate: Date?           // date posted to card
    var cardName: String?           // e.g. "Chase Sapphire", "Amex Gold"
    var address: String?            // full address text
    var latitude: Double?
    var longitude: Double?
    var source: String?              // "Credit Card", "Checking", etc.
    var categoryID: UUID?           // your budget category, nil = uncategorized
    var isIgnored: Bool?             // “ignore” feature
    var createdAt: Date?

    init(
        id: UUID = UUID(),
        plaidTransactionId: String? = nil,
        accountId: String? = nil,
        vendor: String,
        amountCents: Int64,
        transactionDate: Date,
        postedDate: Date? = nil,
        cardName: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        source: String,
        categoryID: UUID? = nil,
        isIgnored: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.plaidTransactionId = plaidTransactionId
        self.accountId = accountId
        self.vendor = vendor
        self.amountCents = amountCents
        self.transactionDate = transactionDate
        self.postedDate = postedDate
        self.cardName = cardName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.source = source
        self.categoryID = categoryID
        self.isIgnored = isIgnored
        self.createdAt = createdAt
    }
}

@Model
final class BankAccount {
    @Attribute(.unique) var id: UUID
    var plaidAccountId: String      // from Plaid
    var institutionName: String     // "Chase", "Bank of America"
    var displayName: String         // "Sapphire Preferred", "Checking"
    var mask: String                // last 2–4 digits, e.g. "1234"
    var type: String                // "credit", "depository"
    var isActive: Bool

    init(
        id: UUID = UUID(),
        plaidAccountId: String,
        institutionName: String,
        displayName: String,
        mask: String,
        type: String,
        isActive: Bool = true
    ) {
        self.id = id
        self.plaidAccountId = plaidAccountId
        self.institutionName = institutionName
        self.displayName = displayName
        self.mask = mask
        self.type = type
        self.isActive = isActive
    }
}


