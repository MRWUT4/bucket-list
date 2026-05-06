//
//  MinimalDesign.swift
//  bucket-list
//

#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

enum MinimalDesign {
    static let accent = Color("AppColor")
    static let warmBg = Color("WarmBg")
    static let horizontalMargin: CGFloat = 28

    static let tintColors: [Color] = [
        Color(red: 0xFF/255, green: 0x3B/255, blue: 0x30/255), // red
        Color(red: 0xFF/255, green: 0x95/255, blue: 0x00/255), // orange
        Color(red: 0xE2/255, green: 0xA9/255, blue: 0x00/255), // yellow
        Color(red: 0x2E/255, green: 0x9E/255, blue: 0x45/255), // green
        Color(red: 0x00/255, green: 0xA6/255, blue: 0x8A/255), // mint
        Color(red: 0x1E/255, green: 0x8C/255, blue: 0xA8/255), // teal
        Color(red: 0x00/255, green: 0x7A/255, blue: 0xFF/255), // blue
        Color(red: 0x5E/255, green: 0x5C/255, blue: 0xE6/255), // indigo
        Color(red: 0xAF/255, green: 0x52/255, blue: 0xDE/255), // purple
        Color(red: 0xE0/255, green: 0x3D/255, blue: 0x6B/255), // pink
        Color(red: 0x8B/255, green: 0x6F/255, blue: 0x47/255), // brown
    ]

    static let tintSymbols: [String] = [
        "book.closed", "gift", "film", "fork.knife", "airplane",
        "sparkles", "tray", "bookmark", "folder", "star", "tag", "pin",
    ]

    // Deterministic, string-stable hash so icon/tint don't flip across app launches.
    private static func stableHash(_ s: String) -> Int {
        var h: UInt64 = 0xcbf29ce484222325
        for byte in s.utf8 {
            h ^= UInt64(byte)
            h &*= 0x100000001b3
        }
        return Int(truncatingIfNeeded: h)
    }

    static func tint(for name: String) -> Color {
        let n = abs(stableHash(name)) % tintColors.count
        return tintColors[n]
    }

    static func symbol(for name: String) -> String {
        let n = abs(stableHash(name)) % tintSymbols.count
        return tintSymbols[n]
    }

    static func resolvedTint(for name: String, customIndex: Int) -> Color {
        if customIndex >= 0, customIndex < tintColors.count {
            return tintColors[customIndex]
        }
        return tint(for: name)
    }

    static func resolvedSymbol(for name: String, customIndex: Int) -> String {
        if customIndex >= 0, customIndex < tintSymbols.count {
            return tintSymbols[customIndex]
        }
        return symbol(for: name)
    }

    // MARK: - Navigation bar appearance

    static func configureNavigationBar() {
        // On iOS 26+ UINavigationBarAppearance is unavailable;
        // navigation bar typography is handled via SwiftUI modifiers.
    }
}

// MARK: - Typography

struct KickerStyle: ViewModifier {
    let symbol: String?
    let tint: Color?
    
    func body(content: Content) -> some View {
        HStack(alignment: .center)
        {
            if let symbol,
               let tint
            {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(tint)
            }
            
            content
                .font(.system(size: 12))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .fontWeight(.light)
        .offset(y: -4)
//        .padding(.top, -16)
    }
}

struct DisplayTitleStyle: ViewModifier {
    var size: CGFloat = 44
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .light))
            .tracking(-0.034 * size)
            .lineSpacing(0)
    }
}

extension View {
    func kickerStyle(symbol: String? = nil, tint: Color? = nil) -> some View { modifier(KickerStyle(symbol: symbol, tint: tint)) }
    func displayTitle(size: CGFloat = 44) -> some View { modifier(DisplayTitleStyle(size: size)) }
}

// MARK: - Hero header

struct MinimalHeroHeader: View {
    let kicker: String
    let title: String
    var meta: String? = nil
    var titleSize: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
//            Text(kicker).kickerStyle()
//                .padding(.bottom, 6)
//            Text(title).displayTitle(size: titleSize)
//                .foregroundStyle(.primary)
            if let meta {
                Text(meta)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
//                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MinimalDesign.horizontalMargin)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }
}
