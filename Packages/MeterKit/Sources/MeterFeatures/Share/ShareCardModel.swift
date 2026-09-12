import Observation
import MeterCore
import MeterDesign
#if canImport(Photos)
import Photos
import MeterModules
#endif

/// 分享面板的状态。渲图、存相册、系统分享都从这里出。
@MainActor
@Observable
final class ShareCardModel {
    enum Outcome: Hashable {
        case savedToPhotos
        case savedToFile
        case copied
        case photosDenied
        case failed
    }

    /// 面板里显示的就是**将要分享的那张图本身**，不是一个近似的缩放视图。
    ///
    /// 早先用 `scaleEffect` 缩 `ShareCardView`：`scaleEffect` 不改变布局尺寸，
    /// 外层 frame 把仍然声明 1080 宽的视图居中，可见内容被推到屏幕外，预览一片空白。
    /// 渲一次图既躲开这个坑，又顺带保证「看到的就是发出去的」。
    private(set) var previewImage: CGImage?
    private(set) var outcome: Outcome?
    private(set) var isBusy = false

    private let dashboard: DashboardModel

    init(dashboard: DashboardModel) {
        self.dashboard = dashboard
    }

    func refreshPreview() {
        previewImage = renderImage()
    }

    /// 构成关掉时，卡上也没有环和那两张方卡——它们在仪表盘上是构成那一块的一部分
    /// （`DashboardView` 同一条件）。卡跟着版式走，不自己决定画什么。
    private var showsComposition: Bool {
        DashboardModuleRegion.hasComposition(in: dashboard.visibleModuleIDs)
    }

    var content: ShareCardContent {
        ShareCardBuilder.content(
            monthToDate: dashboard.monthToDate,
            composition: showsComposition ? dashboard.compositionSegmentsForShare : [],
            comparison: showsComposition ? dashboard.comparisonContent : nil,
            trend: showsComposition ? dashboard.trendContent : nil,
            // 锚点，不是此刻：回看七月时卡上要写「七月」。
            now: dashboard.filter.anchor(
                now: dashboard.clock.now,
                calendar: dashboard.clock.calendar
            ),
            calendar: dashboard.clock.calendar,
            presentation: dashboard.moneyPresentation,
            connections: dashboard.connectionStates()
        )
    }

    /// 1080 宽的位图，高度按内容。按仪表栏宽排完再放大，不要在这里另设 scale。
    ///
    /// 模块区是**仪表盘那一批模块视图本身**（`ShareCardModules`），不是另攒的摘要：
    /// 用户开了几块、排成什么顺序，图上就是几块、那个顺序。
    func renderImage() -> CGImage? {
        ShareCardView.rasterize(content) {
            ShareCardModules(model: dashboard)
        }
    }

    func saveToPhotos() async {
        #if os(macOS)
        outcome = .failed
        #else
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        outcome = nil

        // 只申请「添加」权限，不要读权限——这个 App 没有任何理由读用户的相册。
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            outcome = .photosDenied
            return
        }
        guard let image = previewImage ?? renderImage(),
              let data = RasterImage.pngData(from: image) else {
            outcome = .failed
            return
        }
        do {
            try await Self.persistPNG(data)
            outcome = .savedToPhotos
        } catch {
            outcome = .failed
        }
        #endif
    }

    /// Photos 把 change block 丢到自己的串行队列上跑（文档：arbitrary serial queue）。
    /// 在 `@MainActor` 方法里写的闭包会继承主 actor 隔离，Swift 6 运行时在入口
    /// 核对 executor，对不上就 EXC_BREAKPOINT——「存到相册」崩的就是这一下。
    /// 提到 nonisolated 里、闭包标 `@Sendable`，隔离才不会跟着走。
    #if !os(macOS)
    nonisolated private static func persistPNG(_ data: Data) async throws {
        try await PHPhotoLibrary.shared().performChanges { @Sendable in
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
        }
    }
    #endif

    func markSavedToFile() {
        outcome = .savedToFile
    }

    func copyToClipboard() {
        guard let image = renderImage(), let data = RasterImage.pngData(from: image) else {
            outcome = .failed
            return
        }
        SystemClipboard.copyPNG(data)
        outcome = .copied
    }

    static func preview() -> ShareCardModel {
        ShareCardModel(dashboard: .preview)
    }
}
