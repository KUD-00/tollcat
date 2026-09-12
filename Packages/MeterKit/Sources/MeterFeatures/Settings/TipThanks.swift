import Foundation
import MeterTips

/// 付款成功之后猫说的那两句。
///
/// 一句通用的「谢谢。」太像自动回复：三档价钱差七倍，收到的反应却一模一样。
/// 这里按档位分开写，再打赏的人换一句招呼——这是全 App 唯一该失态一下的位置
/// （BRAND.md 三点五：俏皮只在低风险位置，金额和凭据的句子永远不开玩笑）。
///
/// 三种语言各写各的俏皮，不是互译：中文叠字、英文大写、日文重复「本当に」，
/// 各自是各自语言里会说出口的话。
struct TipThanks: Equatable {
    var headline: LocalizedStringResource
    var note: LocalizedStringResource

    static func make(treat: TipProductID?, isRepeat: Bool) -> TipThanks {
        TipThanks(
            headline: isRepeat ? repeatHeadline : headline(for: treat),
            note: note(for: treat)
        )
    }

    /// 第二次以后不再按档位喊：认出是同一个人，比喊得更大声更值钱。
    private static var repeatHeadline: LocalizedStringResource {
        L("又是你！！太谢谢了！！")
    }

    private static func headline(for treat: TipProductID?) -> LocalizedStringResource {
        switch treat {
        case .small: L("谢谢！！")
        case .medium: L("太谢谢了！！")
        case .large: L("谢谢谢谢谢谢！！！")
        case nil: L("谢谢！！")
        }
    }

    private static func note(for treat: TipProductID?) -> LocalizedStringResource {
        switch treat {
        case .small: L("一颗糖，猫猫叼着就走了。")
        case .medium: L("一杯咖啡。今晚这只猫精神得很。")
        case .large: L("一整块披萨。猫猫已经在打包了。")
        case nil: L("猫猫收下了。")
        }
    }
}
