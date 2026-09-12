#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign

/// 更新说明抽屉的试验台。
///
/// 抽屉一年只有几次机会自己出现（更新后第一次冷启动），而模拟器上的库永远是
/// 新装的——判据永远不成立。所以真正能验收的方式是**改写「看到哪一版」**，
/// 让真判据成立，而不是找个后门强行弹一张。
///
/// 上半页改状态、按真判据弹；下半页才是强行弹，只用来看版式。
struct DeveloperWhatsNewView: View {
    @Bindable var dashboard: DashboardModel

    /// nil = 没在弹。强行弹的那几个入口也走这里，抽屉只有一份。
    @State private var presented: [WhatsNewEntry]?
    /// 按真判据弹但判据不成立时，说一声——静默什么都不发生最难查。
    @State private var quietNote: String?

    private var currentVersion: String { DeveloperBuildInfo.shortVersion }

    private var lastSeen: String { dashboard.shell.lastSeenWhatsNewVersion }

    /// 和 `RootView.considerWhatsNewIfNeeded()` 同一个调用，参数也一样。
    private var pending: [WhatsNewEntry] {
        WhatsNewLaunch.pending(
            currentVersion: currentVersion,
            lastSeenVersion: lastSeen,
            hasCompletedOnboarding: dashboard.shell.hasCompletedOnboarding,
            completedOnboardingThisLaunch: false,
            skipDrawer: false
        )
    }

    private var history: [WhatsNewEntry] { WhatsNewLaunch.history() }

    var body: some View {
        MeterGroupedList {
            state
            rewrite
            fire
            list
        }
        .navigationTitle(L("更新说明"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { presented != nil },
            set: { if !$0 { presented = nil } }
        )) {
            WhatsNewDrawerView(entries: presented ?? []) {
                dashboard.shell.markWhatsNewSeen(currentVersion: currentVersion)
            }
        }
        .alert(
            L("这次不弹"),
            isPresented: Binding(
                get: { quietNote != nil },
                set: { if !$0 { quietNote = nil } }
            )
        ) {
            Button(L("知道了")) { quietNote = nil }
        } message: {
            Text(quietNote ?? "")
        }
    }

    private var state: some View {
        Section {
            LabeledContent(L("当前版本")) {
                Text(verbatim: currentVersion)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .monospacedDigit()
            }
            LabeledContent(L("看到哪一版")) {
                Text(lastSeen.isEmpty ? String(localized: L("还没记过（首装）")) : lastSeen)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .monospacedDigit()
            }
            LabeledContent(L("按真判据会弹")) {
                Text(verbatim: pending.isEmpty
                    ? String(localized: L("不弹"))
                    : pending.map(\.version).joined(separator: " · "))
                    .foregroundStyle(pending.isEmpty ? Color.meterSecondaryLabel : Color.accentColor)
            }
            LabeledContent(L("这一端有几条")) {
                Text(verbatim: "\(history.count)")
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .monospacedDigit()
            }
        } header: {
            Text(L("现在的状态"))
        } footer: {
            Text(L("`shared/changelog.json` 的 entries 是空的时候，「这一端有几条」就是 0，抽屉自然永远不弹——那不是 bug。"))
        }
    }

    private var rewrite: some View {
        Section {
            Button(L("清空（当成首装）")) { write("") }
            Button(L("设成 0.0.0（一定会弹）")) { write("0.0.0") }
            Button(L("设成当前版本（一定不弹）")) { write(currentVersion) }
        } header: {
            Text(L("改写「看到哪一版」"))
        } footer: {
            Text(L("这是唯一能验收正常路径的办法：把它改老，真判据就成立了。改完可以直接按下面那条「按真判据弹一次」，不用等冷启动。"))
        }
    }

    private var fire: some View {
        Section {
            Button(L("按真判据弹一次")) {
                let entries = pending
                if entries.isEmpty {
                    quietNote = String(
                        localized: L("判据不成立，线上这时候也不会弹。先把「看到哪一版」改老一点。")
                    )
                } else {
                    presented = entries
                }
            }
            Button(L("强行弹：这一端的真数据")) {
                fireForced(Array(history.prefix(1)))
            }
            Button(L("强行弹：样例一条")) {
                presented = [.preview]
            }
            Button(L("强行弹：样例两条（跳版合并）")) {
                presented = [.preview, .previewOlder]
            }
        } header: {
            Text(L("弹一次"))
        } footer: {
            Text(L("强行弹那几条不经过判据，只用来看版式。关掉抽屉会把「看到哪一版」推到当前版本，和线上一样。"))
        }
    }

    private var list: some View {
        Section {
            MeterColumnLink(
                value: DeveloperWhatsNewRoute.list,
                title: Text(L("更新说明")),
                destination: { WhatsNewListView() }
            ) {
                Text(L("全量列表"))
                    .foregroundStyle(Color.meterLabel)
            }
        } footer: {
            Text(L("设置里那一页，读同一份数据。安静发布的条目在这里也在。"))
        }
    }

    private func write(_ version: String) {
        dashboard.shell.overrideLastSeenWhatsNewVersion(version)
    }

    private func fireForced(_ entries: [WhatsNewEntry]) {
        if entries.isEmpty {
            quietNote = String(localized: L("这一端一条都没有。往 shared/changelog.json 加一条再来。"))
        } else {
            presented = entries
        }
    }
}

/// 只为了给列内推进一个稳定的 Hashable，不进偏好也不进迁移包。
enum DeveloperWhatsNewRoute: Hashable {
    case list
}

#Preview("Light") {
    NavigationStack {
        DeveloperWhatsNewView(dashboard: .preview)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DeveloperWhatsNewView(dashboard: .preview)
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    NavigationStack {
        DeveloperWhatsNewView(dashboard: .preview)
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
