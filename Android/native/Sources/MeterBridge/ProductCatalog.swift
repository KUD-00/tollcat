import Foundation
import MeterCore
import MeterProviders

package enum ProductCatalog {
    /// 打包目录。字段与教程的权威在 catalog.json（symlink 进本 target 的 Resources，
    /// 和 iOS 打包、worker 部署是同一份文件）；计费模式和 URL 的权威在编译期 descriptor。
    ///
    /// Android / Windows 上 `Bundle.module` 的访问器找不到 bundle 会直接 fatalError——
    /// 不要碰它。平台皮把 SwiftPM 的 resource bundle 解压到私有目录后经
    /// `setResourceRoot` 注入，唯一合法的读取路径是那里。
    package static let bundled: Catalog? = {
        // setResourceRoot 注入的是 fixtures 根（历史原因指到 MeterProviders 的
        // resources 里），本 target 的 bundle 在它的邻层——向上找两级。
        guard let root = JNIResourceRoot.url else { return nil }
        let bundleNames = [
            "MeterCoreAndroid_MeterBridge.resources",
            "MeterCoreWindows_MeterBridge.resources",
            // 桥拆出来之前 APK 里还叫这个名字；解压缓存对得上就继续用。
            "MeterCoreAndroid_MeterCoreJNI.resources",
        ]
        var candidates = [root.appendingPathComponent("catalog.json")]
        for name in bundleNames {
            candidates.append(root.appendingPathComponent("\(name)/catalog.json"))
            candidates.append(
                root.deletingLastPathComponent().appendingPathComponent("\(name)/catalog.json")
            )
            candidates.append(
                root.deletingLastPathComponent().deletingLastPathComponent()
                    .appendingPathComponent("\(name)/catalog.json")
            )
        }
        for url in candidates {
            guard let data = try? Data(contentsOf: url) else { continue }
            if let catalog = try? CatalogCodec.decode(data) {
                return catalog
            }
        }
        return nil
    }()

    package static func json(localeTag: String) -> String {
        let language = CatalogLanguage.resolving(localeTag: localeTag)
        let providers = ProviderCatalog.all.map { descriptor -> [String: Any] in
            let guide = bundled?.guides[descriptor.id]?.localized(for: language)
            return [
                "id": descriptor.id.rawValue,
                "displayName": descriptor.displayName,
                "kind": descriptor.kind.rawValue,
                // 服务页「按类别」排序和分组小标题用它。译文在 Kotlin 侧的
                // strings（category_* 由 xcstrings 生成 en/ja），这里只出原始键。
                "category": descriptor.category.rawValue,
                "tier": descriptor.tier.rawValue,
                "tierReason": descriptor.tierReason,
                "colorKey": descriptor.colorKey,
                "costsMoneyToRefresh": descriptor.costsMoneyToRefresh,
                "supportsInbox": descriptor.supportsInboxIngest,
                "hasLiveFetch": ProviderAssembly.liveRESTProviderIDs.contains(descriptor.id),
                "summary": summary(for: descriptor, localeTag: localeTag),
                "searchKeywords": descriptor.searchKeywords,
                "accessStatus": descriptor.accessStatus.rawValue,
                "declineReason": descriptor.declineReason ?? "",
                "supportsDailyGranularity": descriptor.supportsDailyGranularity,
                "historyLookbackMonths": descriptor.historyLookbackMonths,
                "minimumRefreshInterval": Int(descriptor.minimumRefreshInterval),
                // URL 编译进 .so，不来自目录——和 iOS 同一条安全红线。
                "billingURL": descriptor.billingURL?.absoluteString ?? "",
                "credentialSetupURL": descriptor.credentialSetupURL?.absoluteString ?? "",
                "fields": (guide?.fields ?? []).map { field in
                    [
                        "key": field.key,
                        "label": field.label,
                        "isSecret": field.isSecret,
                        "hint": field.hint ?? "",
                    ] as [String: Any]
                },
            ]
        }
        return JNIJSON.stringify([
            "jniSchema": JNISchema.version,
            "providers": providers,
            "currencies": ProductRates.bundled.displayCodes,
            // 服务页「按类别」的组序。声明序是唯一权威，别在 Kotlin 侧再抄一份 20 项清单。
            "categoryOrder": ProviderCategory.allCases.map(\.rawValue),
        ])
    }

    /// 向导整篇教程：按 locale 解析后再编码 + 行内深链的解析表。
    /// Kotlin 侧读规范字段即可，不必知道 overlay。
    /// links 的空键是默认落点（创建 token 那页），其余键对应 `SetupStep.linkTarget`。
    package static func setupGuideJson(providerIDRaw: String, localeTag: String) -> String {
        let id = ProviderID(providerIDRaw)
        let language = CatalogLanguage.resolving(localeTag: localeTag)
        guard
            let descriptor = ProviderCatalog.descriptor(id: id),
            let guide = bundled?.guides[id]?.localized(for: language),
            let data = try? JSONEncoder().encode(guide),
            let encoded = try? JSONSerialization.jsonObject(with: data),
            var object = encoded as? [String: Any]
        else {
            return JNIJSON.stringify(["missing": true])
        }
        var links: [String: String] = [:]
        if let setup = descriptor.credentialSetupURL {
            links[""] = setup.absoluteString
        }
        for (key, url) in descriptor.guideURLs {
            links[key] = url.absoluteString
        }
        object["links"] = links
        if let billing = descriptor.billingURL {
            object["billingURL"] = billing.absoluteString
        }
        return JNIJSON.stringify(object)
    }

    /// 取数侧补 stub 用。字段权威在 catalog 的 guide，enum 对不上的键跳过。
    package static func fields(for id: ProviderID) -> [CredentialField] {
        (bundled?.guides[id]?.fields ?? []).compactMap { CredentialField(rawValue: $0.key) }
    }

    private static func summary(for descriptor: ProviderDescriptor, localeTag: String) -> String {
        let kind: String
        switch descriptor.kind {
        case .usage: kind = JNICopy.text("用量后付费", localeTag)
        case .prepaid: kind = JNICopy.text("预充值余额", localeTag)
        case .subscription: kind = JNICopy.text("固定订阅", localeTag)
        case .freeTier: kind = JNICopy.text("免费额度内", localeTag)
        case .planAndUsage: kind = JNICopy.text("月费加超额", localeTag)
        }
        if descriptor.costsMoneyToRefresh {
            return JNICopy.format("%@ · 要花钱取数 约 $0.01", localeTag, kind)
        }
        if descriptor.supportsInboxIngest {
            return JNICopy.format("%@ · 读数信箱", localeTag, kind)
        }
        return kind
    }
}
