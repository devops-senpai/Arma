import SwiftUI

// MARK: - Types

struct BrowserEngineBenefit {
    let title: LocalizedStringResource
    let symbol: String
}

/// An engine's mark: its own artwork, or a symbol for one without any.
enum BrowserEngineArtwork {
    case asset(String)
    case symbol(String)

    /// The artwork's name in the app's assets; a symbol has none.
    var assetName: String? {
        if case .asset(let name) = self { return name }
        return nil
    }
}

/// Describes a selectable engine with its own artwork and capabilities.
struct BrowserEngineOption: Identifiable {
    // MARK: - Static Variables

    static let all: [BrowserEngineOption] = [
        BrowserEngineOption(
            engine: .chromium, logo: .asset("EngineChromium"),
            summary: "Chromium without Google’s data collection. Smooth browsing and extensions.",
            benefits: [
                BrowserEngineBenefit(title: "Smooth webpage performance", symbol: "speedometer"),
                BrowserEngineBenefit(title: "Chrome Web Store extensions", symbol: "puzzlepiece.extension"),
                BrowserEngineBenefit(title: "Protected video, with WebKit fallback", symbol: "play.rectangle"),
            ]),
        BrowserEngineOption(
            engine: .webKit, logo: .asset("EngineWebKit"),
            summary: "Apple’s native web engine, with system integration and protected media playback.",
            benefits: [
                BrowserEngineBenefit(title: "Native macOS handling", symbol: "macwindow"),
                BrowserEngineBenefit(title: "FairPlay protected video", symbol: "play.rectangle"),
                BrowserEngineBenefit(title: "Reader Mode", symbol: "doc.text"),
            ]),
        BrowserEngineOption(
            engine: .servo, logo: .symbol("gearshape.2.fill"),
            summary: "Servo, the independent engine written in Rust. Experimental.",
            benefits: [
                BrowserEngineBenefit(title: "Independent Rust engine", symbol: "gearshape.2"),
                BrowserEngineBenefit(title: "Firefox add-on page scripts", symbol: "puzzlepiece.extension"),
            ]),
    ]

    // MARK: - Variables

    let engine: EngineKind
    let logo: BrowserEngineArtwork
    let summary: LocalizedStringResource
    let benefits: [BrowserEngineBenefit]
    var id: EngineKind { engine }

    // MARK: - Actions - Lookup

    /// The name of `engine`'s logo in the app's assets, or nil for an engine
    /// this list does not show or marks with a symbol.
    static func logo(of engine: EngineKind) -> String? {
        all.first { $0.engine == engine }?.logo.assetName
    }
}
