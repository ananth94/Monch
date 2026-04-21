//
//  MonchIcon.swift
//  monch
//
//  Shared icon abstraction for custom assets and SF Symbols.
//

import SwiftUI

enum MonchIconToken: Equatable {
    case asset(String)
    case symbol(String)
}

struct MonchIconView: View {
    let token: MonchIconToken
    var size: CGFloat = 28
    var tint: Color? = nil

    var body: some View {
        switch token {
        case .asset(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(tint ?? .primary)
                .frame(width: size, height: size)
        }
    }
}
