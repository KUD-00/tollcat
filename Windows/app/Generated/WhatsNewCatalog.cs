// GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。
// 不要手改：改 shared/changelog.json 后重跑生成器。


using System.Collections.Generic;

namespace TollCat.Generated;

public sealed record WhatsNewText(string Zh, string En, string Ja)
{
    public string Resolve(string language) =>
        language.StartsWith("en") ? En : language.StartsWith("ja") ? Ja : Zh;
}

public sealed record WhatsNewItem(
    string Id,
    string? Symbol,
    WhatsNewText Title,
    WhatsNewText Body);

public sealed record WhatsNewEntry(
    string Version,
    IReadOnlyList<string> Platforms,
    bool ShowsDrawer,
    string? HeroKind,
    string? HeroValue,
    WhatsNewText Title,
    IReadOnlyList<WhatsNewItem> Items);

/// <summary>新的在上。P0 之前只生成，不接界面。</summary>
public static class WhatsNewCatalog
{
    public static readonly IReadOnlyList<WhatsNewEntry> Entries = new List<WhatsNewEntry>
    {
        new WhatsNewEntry(
            "1.0.0",
            new[] { "ios" },
            false,
            "cat",
            "normal",
            new WhatsNewText("TollCat 1.0：云账单，装进口袋", "TollCat 1.0: your cloud bills, in your pocket", "TollCat 1.0：クラウドの請求を、ポケットに"),
            new List<WhatsNewItem>
            {
                new WhatsNewItem(
                    "firstRelease",
                    null,
                    new WhatsNewText("第一版上架了", "The first release", "はじめてのリリース"),
                    new WhatsNewText("先从 iPhone 和 iPad 开始。把各家云和 AI 服务的花费加在一起，打开就能看到这个月到现在一共花了多少。", "iPhone and iPad first. TollCat adds up what you spend across your cloud and AI services, so one glance tells you how much this month has cost so far.", "まずは iPhone と iPad から。クラウドや AI サービスの利用料をまとめて、今月ここまでいくら使ったかがひと目でわかります。")),
            }),
    };
}
