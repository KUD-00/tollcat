#if DEBUG
import SwiftUI
import MeterDesign
import MeterProviders

struct GalleryGlyphStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section("Light") {
                glyphLibrary
                    .environment(\.colorScheme, .light)
                    .listRowBackground(Color.meterGroupedBackground)
            }
            Section("Dark") {
                // listRowBackground 不吃子视图的 colorScheme，要先把系统色解析成 dark。
                // 不要归零 inset：section 圆角会把最左边的 tile 剃掉一角。
                glyphLibrary
                    .environment(\.colorScheme, .dark)
                    .listRowBackground(Self.forcedDarkGrouped)
            }
        }
        .navigationTitle("ProviderGlyph")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// listRowBackground 不吃子视图的 colorScheme，只能写死深色 grouped 底。
    private static let forcedDarkGrouped = Color(
        red: 28 / 255,
        green: 28 / 255,
        blue: 30 / 255
    )

    private var glyphLibrary: some View {
        GlyphLibraryLayout(spacing: MeterSpacing.sm, minCellWidth: MeterSpacing.minTap) {
            ForEach(ProviderCatalog.all, id: \.id) { descriptor in
                VStack(spacing: MeterSpacing.xxs) {
                    ProviderGlyph(
                        colorKey: descriptor.colorKey,
                        accessibilityName: descriptor.displayName
                    )
                    Text(descriptor.displayName)
                        .font(MeterFont.caption2)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.vertical, MeterSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// List 套 LazyVGrid 两层都 lazy，高度只会按第一行报。图标库要按行宽折行，只能自己量。
private struct GlyphLibraryLayout: Layout {
    var spacing: CGFloat
    var minCellWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let arrangement = arrange(width: bounds.width, subviews: subviews)
        for index in subviews.indices {
            let frame = arrangement.frames[index]
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(width proposedWidth: CGFloat?, subviews: Subviews) -> Arrangement {
        guard !subviews.isEmpty else { return Arrangement(size: .zero, frames: []) }

        let width: CGFloat
        if let proposedWidth, proposedWidth > 0, proposedWidth.isFinite {
            width = proposedWidth
        } else {
            width = CGFloat(subviews.count) * minCellWidth
                + CGFloat(max(subviews.count - 1, 0)) * spacing
        }

        let columns = max(1, Int((width + spacing) / (minCellWidth + spacing)))
        let cellWidth = max(
            minCellWidth,
            (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        )

        var frames: [CGRect] = []
        frames.reserveCapacity(subviews.count)
        var originY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var column = 0

        for subview in subviews {
            if column == columns {
                originY += rowHeight + spacing
                rowHeight = 0
                column = 0
            }
            let size = subview.sizeThatFits(ProposedViewSize(width: cellWidth, height: nil))
            let originX = CGFloat(column) * (cellWidth + spacing)
            frames.append(CGRect(x: originX, y: originY, width: cellWidth, height: size.height))
            rowHeight = max(rowHeight, size.height)
            column += 1
        }

        return Arrangement(
            size: CGSize(width: width, height: originY + rowHeight),
            frames: frames
        )
    }

    private struct Arrangement {
        var size: CGSize
        var frames: [CGRect]
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryGlyphStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryGlyphStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
