import MeterCore
import SwiftUI
import MeterDesign
import MeterPersistence
import MeterProviders

/// 向导一步的正文：加粗关键词，可点片段前面跟系统 safari 符号。
///
/// 链接字和下文（常见是「的」）之间再留一丝空隙。下划线贴着下一个字会糊成一块；
/// 全角空格又太宽，像把中文句子切开。空隙不进链接范围，下划线不会跟着伸过去。
struct SetupStepText: View {
    var step: SetupStep
    var linkURL: URL?
    var onOpenLink: ((URL) -> Void)? = nil

    /// 图标和可点字不断行。
    private static let iconGap = "\u{00A0}"
    /// 窄不换行空格：比普通空格窄一截，跟着链接走、不甩到下一行行首。
    private static let trailingGap = "\u{202F}"

    var body: some View {
        composed
            .font(MeterFont.body)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                if let onOpenLink {
                    onOpenLink(url)
                    return .handled
                }
                return .systemAction
            })
    }

    private var composed: Text {
        let pieces = SetupStepMarkup.pieces(step)
        var composed = Text(verbatim: "")
        for (index, piece) in pieces.enumerated() {
            let next = pieces.dropFirst(index + 1).first
            composed = Text("\(composed)\(text(for: piece, next: next))")
        }
        return composed
    }

    private func text(for piece: SetupStepMarkup.Piece, next: SetupStepMarkup.Piece?) -> Text {
        switch piece {
        case .plain(let string):
            return Text(string)
        case .emphasis(let string):
            return Text(string).fontWeight(.semibold)
        case .link(let string):
            guard let linkURL else {
                return Text(string)
            }
            var linked = AttributedString(string)
            linked.link = linkURL
            let linkedText = Text(
                "\(Text(Image(systemName: "safari")).foregroundStyle(.tint))\(Text(Self.iconGap))\(Text(linked))"
            )
            guard Self.needsTrailingGap(before: next) else {
                return linkedText
            }
            return Text("\(linkedText)\(Text(Self.trailingGap))")
        }
    }

    /// 后面还有非空白正文时才加。原文已经空一格、或链接收在句末，都不再垫。
    private static func needsTrailingGap(before next: SetupStepMarkup.Piece?) -> Bool {
        guard let first = firstCharacter(of: next) else { return false }
        return !first.isWhitespace
    }

    private static func firstCharacter(of piece: SetupStepMarkup.Piece?) -> Character? {
        switch piece {
        case .plain(let string), .emphasis(let string), .link(let string):
            return string.first
        case nil:
            return nil
        }
    }
}

#Preview("Light") {
    List {
        SetupStepText(
            step: SetupStep(
                text: "打开 Cloudflare 控制台的 API Tokens 页面，点 Create Token。",
                emphasized: ["API Tokens", "Create Token"],
                linkPhrases: ["Cloudflare 控制台"]
            ),
            linkURL: ProviderCatalog.cloudflare.credentialSetupURL
        )
        SetupStepText(
            step: SetupStep(
                text: "请查阅 查找 Account ID",
                linkPhrases: ["查找 Account ID"]
            ),
            linkURL: ProviderCatalog.cloudflare.setupLinkURL(target: "findAccountAndZoneIDs")
        )
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        SetupStepText(
            step: SetupStep(
                text: "打开 Cloudflare 控制台的 API Tokens 页面，点 Create Token。",
                emphasized: ["API Tokens", "Create Token"],
                linkPhrases: ["Cloudflare 控制台"]
            ),
            linkURL: ProviderCatalog.cloudflare.credentialSetupURL
        )
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.dark)
}
