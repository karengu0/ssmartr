//
//  Color+Hex.swift
//  ssmartr
//
//  Created by Karen Guo on 11/14/25.
//

import SwiftUI

extension Color {
    func toHexString() -> String {
        let uiColor = UIColor(self)

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}
