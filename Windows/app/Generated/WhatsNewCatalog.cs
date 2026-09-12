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
    public static readonly IReadOnlyList<WhatsNewEntry> Entries = new List<WhatsNewEntry>();
}
