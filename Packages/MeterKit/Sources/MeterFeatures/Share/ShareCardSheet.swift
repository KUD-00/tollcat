import SwiftUI
import MeterDesign
import MeterUsage

/// 分享面板。**卡片是主角，所以不用系统分享面板当第一层。**
///
/// 系统那张只给一个小缩略图，用户在按下之前看不清自己要发什么；而这张卡的
/// 全部价值就在它长什么样。所以自己画一层：那张卡的预览 + 三行动作。
/// 真要发到别的 App 时才把系统面板叫出来——那时候图已经渲好了。
///
/// **预览是中间那一档，不跟着卡的长短伸缩**：宽度钉在 `shareCardPreviewWidth`
/// （约卡本身的六成，数字还读得出），高度封顶 `shareCardPreview`。9:16 那一档正好
/// 整张装下；模块多、卡长成一条时**在这一格里上下滚**，不缩成一条细缝，也不裁掉。
///
/// 动作是三行图标 + 一行字，一张分组卡（`ShareActionCard`），**不跟着预览滚**：
/// 宽壳上它钉在右边一列，手机上钉在预览下面。自造一排彩色圆钮那版删了——
/// 一面 sheet 里三颗平级的动作就是系统行的活。
///
/// 面板尺寸：宽壳走 `.fitted`，对话框只占内容要的那么大（`.page` 会给一张固定大页，
/// 里面一大片空）；手机仍是满屏 sheet。
struct ShareCardSheet: View {
    @State private var model: ShareCardModel
    @State private var isExporting = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.usesPadChrome) private var usesPadChrome

    init(model: ShareCardModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            Group {
                if usesPadChrome {
                    wide
                } else {
                    stacked
                }
            }
            .background(Color.meterGroupedBackground)
            .recordsUsageScreen(.share)
            .meterSheetTitle(Text(L("分享")))
            .meterSheetClose { dismiss() }
            .task { model.refreshPreview() }
            .fileExporter(
                isPresented: $isExporting,
                document: ShareCardPNGFile(data: exportPNGData),
                contentType: .png,
                defaultFilename: model.content.periodTitle
            ) { result in
                if case .success = result {
                    model.markSavedToFile()
                }
            }
        }
        // 尺寸自己算：里面套着 `NavigationStack`（iOS 的关闭钮要进导航栏），
        // 而 NavigationStack 报不出有意义的理想尺寸——只写 `.fitted` 的话 iPad 上
        // 会收成一条几十点的窄缝（试过 `.fitted` 和 form fitted，两种都缩）。
        .frame(
            width: usesPadChrome ? wideWidth : nil,
            height: usesPadChrome ? wideSheetHeight : nil
        )
        .meterDrawerChrome(usesPadChrome ? .fitted : .page, usesPadChrome: usesPadChrome)
    }

    /// 手机：预览在上、动作在下。两者之间只隔一档 `md`。
    private var stacked: some View {
        VStack(spacing: MeterSpacing.md) {
            preview
            actions
        }
        .padding(.horizontal, MeterSpacing.pageHorizontal)
        .padding(.top, MeterSpacing.md)
        .padding(.bottom, MeterSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 宽壳：左预览、右动作，顶对齐。间距一档 `lg`——横向排开不等于要拉开一条走廊。
    ///
    /// 尺寸写死给 `.fitted` 用：`NavigationStack` 报不出有意义的理想尺寸
    /// （只给 `.fixedSize()` 的话 iPad 上收成一条几十点宽的窄缝），
    /// 所以这一块自己把宽高算出来——两栏都是定宽，高度就是预览那一格。
    private var wide: some View {
        HStack(alignment: .top, spacing: MeterSpacing.lg) {
            preview
            actions
                .frame(width: MeterSpacing.shareActionColumn)
        }
        .padding(MeterSpacing.lg)
        .frame(width: wideWidth, alignment: .topLeading)
    }

    private var wideWidth: CGFloat {
        MeterSpacing.shareCardPreviewWidth
            + MeterSpacing.lg
            + MeterSpacing.shareActionColumn
            + MeterSpacing.lg * 2
    }

    /// 整面 sheet 的高：预览那一格 + 内边距 + sheet 自己的头尾。
    private var wideSheetHeight: CGFloat {
        previewHeight + MeterSpacing.lg * 2 + MeterSpacing.sheetChrome
    }

    /// 预览那一格的高：卡在预览宽度下的高，封顶。
    private var previewHeight: CGFloat {
        min(cardHeight, MeterSpacing.shareCardPreview)
    }

    private var exportPNGData: Data {
        guard let image = model.previewImage else { return Data() }
        return RasterImage.pngData(from: image) ?? Data()
    }

    /// 显示的就是将要分享的那张位图本身，按预览宽等比放，长了在格子里滚。
    private var preview: some View {
        ScrollView(.vertical) {
            card
        }
        .scrollBounceBehavior(.basedOnSize)
        // 高度用 maxHeight：sheet 头尾占掉一截之后这一格跟着矮一点，不顶出去。
        .frame(width: MeterSpacing.shareCardPreviewWidth)
        .frame(maxHeight: previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: MeterRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }

    @ViewBuilder
    private var card: some View {
        if let image = model.previewImage {
            Image(decorative: image, scale: 1)
                .resizable()
                .frame(width: MeterSpacing.shareCardPreviewWidth, height: cardHeight)
                .accessibilityLabel(L("分享卡片预览"))
        } else {
            Color.meterSecondaryGroupedBackground
                .frame(width: MeterSpacing.shareCardPreviewWidth, height: cardHeight)
                .overlay { ProgressView() }
        }
    }

    /// 卡在预览宽度下的高。没渲好时按 9:16 占位，免得面板尺寸在图出来的一瞬间跳。
    private var cardHeight: CGFloat {
        let ratio: CGFloat
        if let image = model.previewImage, image.width > 0 {
            ratio = CGFloat(image.height) / CGFloat(image.width)
        } else {
            ratio = ShareCardView.size.height / ShareCardView.size.width
        }
        return MeterSpacing.shareCardPreviewWidth * ratio
    }

    /// 三行动作 + 结果那一行小字。一张分组卡，不是 List——
    /// 这面要按内容定尺寸，而 `List` / `Form` 报的理想高是 0。
    private var actions: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            ShareActionCard {
                #if os(macOS)
                actionRow(L("存储…"), symbol: "square.and.arrow.down") {
                    isExporting = true
                }
                #else
                actionRow(L("存到相册"), symbol: "square.and.arrow.down") {
                    Task { await model.saveToPhotos() }
                }
                #endif
                Divider().padding(.leading, MeterSpacing.md)
                actionRow(L("拷贝图片"), symbol: "doc.on.doc") {
                    model.copyToClipboard()
                }
                Divider().padding(.leading, MeterSpacing.md)
                shareRow
            }
            .disabled(model.isBusy)
            if let outcome = model.outcome {
                Text(caption(for: outcome))
                    .font(MeterFont.footnote)
                    .foregroundStyle(isGood(outcome) ? Color.meterSecondaryLabel : MeterColor.crit)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, MeterSpacing.md)
            }
        }
    }

    @ViewBuilder
    private var shareRow: some View {
        if let image = model.previewImage {
            ShareLink(
                item: Image(decorative: image, scale: 1),
                preview: SharePreview(
                    model.content.periodTitle,
                    image: Image(decorative: image, scale: 1)
                )
            ) {
                actionLabel(L("分享到…"), symbol: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("用系统分享面板送出这张图"))
        } else {
            // 图还没渲好时留一行灰的，不要让这张卡渲完再长出第三行。
            actionLabel(L("分享到…"), symbol: "square.and.arrow.up")
                .foregroundStyle(Color.meterTertiaryLabel)
        }
    }

    private func actionRow(
        _ title: LocalizedStringResource,
        symbol: String,
        run: @escaping () -> Void
    ) -> some View {
        Button(action: run) {
            actionLabel(title, symbol: symbol)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func actionLabel(_ title: LocalizedStringResource, symbol: String) -> some View {
        Label {
            Text(title)
                .font(MeterFont.body)
        } icon: {
            Image(systemName: symbol)
                .font(MeterFont.body)
        }
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, MeterSpacing.md)
        .frame(minHeight: MeterSpacing.minTap)
        .meterListRowHitTarget()
    }

    private func isGood(_ outcome: ShareCardModel.Outcome) -> Bool {
        switch outcome {
        case .savedToPhotos, .savedToFile, .copied: true
        case .photosDenied, .failed: false
        }
    }

    private func caption(for outcome: ShareCardModel.Outcome) -> LocalizedStringResource {
        switch outcome {
        case .savedToPhotos: L("已存到相册")
        case .savedToFile: L("已存到文件")
        case .copied: L("图片已拷贝，可以直接粘到聊天里")
        case .photosDenied: L("没有相册添加权限。可以改用「拷贝图片」或「分享到…」。")
        case .failed: L("这张卡没渲出来，再试一次。")
        }
    }
}

/// 分组卡：一叠行 + 一张卡面。行的样子和 `MeterGroupedList` 的一节一样，
/// 但它报得出理想高——这面要按内容定尺寸，`List` / `Form` 报 0。
private struct ShareActionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
    }
}

#Preview("Light") {
    ShareCardSheet(model: .preview())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ShareCardSheet(model: .preview())
        .preferredColorScheme(.dark)
}
