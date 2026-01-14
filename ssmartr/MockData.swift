//
//  MockData.swift
//  ssmartr
//
//  Created by ChatGPT on 11/14/2025.
//

import Foundation
import SwiftData

struct MockData {

    // MARK: - Mock Categories
    static let food = Category(
        name: "Food",
        emoji: "🍔",
        colorHex: "#FF8A65",
        percent: 0.30
    )

    static let shopping = Category(
        name: "Shopping",
        emoji: "🛍️",
        colorHex: "#BA68C8",
        percent: 0.20
    )

    static let travel = Category(
        name: "Travel",
        emoji: "✈️",
        colorHex: "#4FC3F7",
        percent: 0.25
    )

    static let bills = Category(
        name: "Bills",
        emoji: "💡",
        colorHex: "#FFD54F",
        percent: 0.15
    )

    static let fun = Category(
        name: "Fun",
        emoji: "🎮",
        colorHex: "#81C784",
        percent: 0.10
    )

    static let allCategories: [Category] = [food, shopping, travel, bills, fun]


    // MARK: - Helper for Dates
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }


    // MARK: - Mock Transactions
    static let transactions: [Transaction] = [

        // --- UNCATEGORIZED: these should show up in your "to categorize" flows ---

        Transaction(
            vendor: "Din Tai Fung",
            amountCents: -3500,
            transactionDate: daysAgo(1),
            postedDate: daysAgo(1),
            cardName: "Chase Sapphire Preferred",
            source: "Credit Card",
            categoryID: nil      // 👈 uncategorized
        ),
        Transaction(
            vendor: "Trader Joe's",
            amountCents: -7200,
            transactionDate: daysAgo(2),
            postedDate: daysAgo(2),
            cardName: "Amex Gold",
            source: "Credit Card",
            categoryID: nil      // 👈 uncategorized
        ),
        Transaction(
            vendor: "Uber",
            amountCents: -1899,
            transactionDate: daysAgo(0),
            postedDate: daysAgo(0),
            cardName: "Chase Sapphire Preferred",
            source: "Credit Card",
            categoryID: nil      // 👈 uncategorized
        ),

        // Income example (positive amount, uncategorized for now)
        Transaction(
            vendor: "Microsoft Paycheck",
            amountCents: 420000, // $4200
            transactionDate: daysAgo(10),
            postedDate: daysAgo(9),
            cardName: "Direct Deposit",
            source: "Income",
            categoryID: nil      // 👈 uncategorized income
        ),

        // --- CATEGORIZED: these give Overview real numbers per category ---

        // Food 🍔
        Transaction(
            vendor: "Chipotle",
            amountCents: -1299,
            transactionDate: daysAgo(3),
            postedDate: daysAgo(3),
            cardName: "Chase Sapphire Preferred",
            source: "Credit Card",
            categoryID: food.id
        ),
        Transaction(
            vendor: "Starbucks",
            amountCents: -645,
            transactionDate: daysAgo(4),
            postedDate: daysAgo(4),
            cardName: "Amex Gold",
            source: "Credit Card",
            categoryID: food.id
        ),
        Transaction(
            vendor: "Whole Foods",
            amountCents: -4890,
            transactionDate: daysAgo(5),
            postedDate: daysAgo(5),
            cardName: "Chase Sapphire Preferred",
            source: "Credit Card",
            categoryID: food.id
        ),

        // Shopping 🛍️
        Transaction(
            vendor: "Uniqlo",
            amountCents: -3990,
            transactionDate: daysAgo(6),
            postedDate: daysAgo(6),
            cardName: "Amex Gold",
            source: "Credit Card",
            categoryID: shopping.id
        ),
        Transaction(
            vendor: "Apple Store",
            amountCents: -129900,
            transactionDate: daysAgo(7),
            postedDate: daysAgo(7),
            cardName: "Chase Sapphire Preferred",
            source: "Credit Card",
            categoryID: shopping.id
        ),

        // Travel ✈️
        Transaction(
            vendor: "Delta Airlines",
            amountCents: -32000,
            transactionDate: daysAgo(12),
            postedDate: daysAgo(11),
            cardName: "Chase Sapphire Preferred",
            source: "Credit Card",
            categoryID: travel.id
        ),
        Transaction(
            vendor: "Marriott Hotel",
            amountCents: -18900,
            transactionDate: daysAgo(14),
            postedDate: daysAgo(13),
            cardName: "Amex Platinum",
            source: "Credit Card",
            categoryID: travel.id
        ),

        // Bills 💡
        Transaction(
            vendor: "T-Mobile",
            amountCents: -7000,
            transactionDate: daysAgo(8),
            postedDate: daysAgo(7),
            cardName: "Checking Account",
            source: "Checking",
            categoryID: bills.id
        ),
        Transaction(
            vendor: "Seattle City Light",
            amountCents: -9500,
            transactionDate: daysAgo(9),
            postedDate: daysAgo(8),
            cardName: "Checking Account",
            source: "Checking",
            categoryID: bills.id
        ),

        // Fun 🎮
        Transaction(
            vendor: "AMC Theater",
            amountCents: -1599,
            transactionDate: daysAgo(4),
            postedDate: daysAgo(4),
            cardName: "Chase Sapphire Preferred",
            source: "Credit Card",
            categoryID: fun.id
        ),
        Transaction(
            vendor: "Steam Games",
            amountCents: -2999,
            transactionDate: daysAgo(6),
            postedDate: daysAgo(6),
            cardName: "Chase Sapphire Preferred",
            source: "Credit Card",
            categoryID: fun.id
        )
    ]
}
