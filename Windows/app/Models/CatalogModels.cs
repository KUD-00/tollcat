using System.Text.Json;

namespace TollCat;

internal static class JniSchema
{
    public const int EXPECTED_JNI_SCHEMA = 7;
}

internal sealed record CatalogField(string Key, string Label, bool IsSecret, string Hint);

internal sealed record CatalogProvider(
    string Id,
    string DisplayName,
    string Kind,
    /// <summary>这家干什么活（aiInference / hosting / database……），和 iOS ProviderCategory 同一组值。</summary>
    string Category,
    /// <summary>所属品类里的市占档，1…4，和 iOS ProviderTier 同一组值。</summary>
    int Tier,
    /// <summary>为什么标这个档。给人读的，不进翻译表。</summary>
    string TierReason,
    string ColorKey,
    bool CostsMoneyToRefresh,
    bool SupportsInbox,
    bool HasLiveFetch,
    string Summary,
    IReadOnlyList<string> SearchKeywords,
    string AccessStatus,
    string DeclineReason,
    bool SupportsDailyGranularity,
    int HistoryLookbackMonths,
    /// <summary>两次成功刷新之间的最短间隔（秒）。0 表示不另限。和 iOS ProviderDescriptor.minimumRefreshInterval 同一口径。</summary>
    int MinimumRefreshInterval,
    string BillingUrl,
    string CredentialSetupUrl,
    IReadOnlyList<CatalogField> Fields)
{
    /// <summary>和 iOS RefreshCadence.shouldFetch 同一口径。</summary>
    public bool ShouldFetch(long lastFetchedAtMillis, long nowMillis)
    {
        if (MinimumRefreshInterval <= 0) return true;
        if (lastFetchedAtMillis <= 0) return true;
        if (lastFetchedAtMillis > nowMillis) return true;
        return nowMillis - lastFetchedAtMillis >= (long)MinimumRefreshInterval * 1000;
    }
}

internal sealed record Catalog(IReadOnlyList<CatalogProvider> Providers, IReadOnlyList<string> Currencies)
{
    public CatalogProvider? Provider(string id) => Providers.FirstOrDefault(p => p.Id == id);

    public IEnumerable<CatalogProvider> Offered =>
        Providers.Where(p => p.AccessStatus != "declined");

    public static Catalog Parse(string json)
    {
        using var doc = JsonDocument.Parse(string.IsNullOrWhiteSpace(json) ? "{}" : json);
        var root = doc.RootElement;
        WarnSchema(root, "catalog");
        var providers = new List<CatalogProvider>();
        if (root.TryGetProperty("providers", out var array) && array.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in array.EnumerateArray())
            {
                providers.Add(new CatalogProvider(
                    Id: Str(item, "id"),
                    DisplayName: Str(item, "displayName"),
                    Kind: Str(item, "kind"),
                    Category: Str(item, "category", "other"),
                    Tier: Int(item, "tier", 3),
                    TierReason: Str(item, "tierReason"),
                    ColorKey: Str(item, "colorKey", Str(item, "id")),
                    CostsMoneyToRefresh: Bool(item, "costsMoneyToRefresh"),
                    SupportsInbox: Bool(item, "supportsInbox"),
                    HasLiveFetch: Bool(item, "hasLiveFetch"),
                    Summary: Str(item, "summary"),
                    SearchKeywords: Strs(item, "searchKeywords"),
                    AccessStatus: Str(item, "accessStatus", "available"),
                    DeclineReason: Str(item, "declineReason"),
                    SupportsDailyGranularity: Bool(item, "supportsDailyGranularity"),
                    HistoryLookbackMonths: Int(item, "historyLookbackMonths"),
                    MinimumRefreshInterval: Int(item, "minimumRefreshInterval"),
                    BillingUrl: Str(item, "billingURL"),
                    CredentialSetupUrl: Str(item, "credentialSetupURL"),
                    Fields: Fields(item)));
            }
        }
        var currencies = Strs(root, "currencies");
        if (currencies.Count == 0) currencies = ["USD"];
        return new Catalog(providers, currencies);
    }

    private static List<CatalogField> Fields(JsonElement item)
    {
        var list = new List<CatalogField>();
        if (!item.TryGetProperty("fields", out var array) || array.ValueKind != JsonValueKind.Array)
        {
            return list;
        }
        foreach (var field in array.EnumerateArray())
        {
            var key = Str(field, "key");
            list.Add(new CatalogField(key, Str(field, "label", key), Bool(field, "isSecret"), Str(field, "hint")));
        }
        return list;
    }

    internal static void WarnSchema(JsonElement root, string what)
    {
        var version = root.TryGetProperty("jniSchema", out var v) && v.TryGetInt32(out var n)
            ? n
            : JniSchema.EXPECTED_JNI_SCHEMA;
        if (version != JniSchema.EXPECTED_JNI_SCHEMA)
        {
            System.Diagnostics.Debug.WriteLine($"{what} jniSchema={version} expected={JniSchema.EXPECTED_JNI_SCHEMA}");
        }
    }

    internal static string Str(JsonElement el, string name, string fallback = "") =>
        el.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() ?? fallback : fallback;

    internal static bool Bool(JsonElement el, string name) =>
        el.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.True;

    internal static int Int(JsonElement el, string name, int fallback = 0) =>
        el.TryGetProperty(name, out var v) && v.TryGetInt32(out var n) ? n : fallback;

    internal static IReadOnlyList<string> Strs(JsonElement el, string name)
    {
        if (!el.TryGetProperty(name, out var v) || v.ValueKind != JsonValueKind.Array) return [];
        return v.EnumerateArray().Select(x => x.GetString() ?? "").ToList();
    }
}

internal sealed record CompositionRow(
    string AccountId,
    string ProviderId,
    string DisplayName,
    string ColorKey,
    string Amount,
    int Percent,
    double Fraction);

internal sealed record UpcomingRow(
    string Name,
    string AccountId,
    string ProviderId,
    string ColorKey,
    string Amount,
    string DateCaption);

internal sealed record FreeQuotaRow(
    string AccountId,
    string ProviderId,
    string DisplayName,
    string ColorKey,
    int UsedPercent,
    string Caption);

internal sealed record AnomalyRow(
    string AccountId,
    string ProviderId,
    string DisplayName,
    string SignedPercent,
    string Caption,
    double ChangeRatio);

internal sealed record BalanceAlertRow(
    string AccountId,
    string ProviderId,
    string DisplayName,
    string Balance,
    int DaysRemaining,
    string Caption);

internal sealed record TrendRow(string Month, string Amount, double Fraction);

internal sealed record DashboardSnapshot(
    bool Empty,
    string MonthTitle,
    bool AllowsProjection,
    string FormattedTotal,
    string FormattedVariable,
    string FormattedProjected,
    string Confidence,
    IReadOnlyList<string> EstimatedAccountIds,
    string? SubscriptionFormatted,
    string? CurrencyNote,
    IReadOnlyList<CompositionRow> Composition,
    IReadOnlyList<UpcomingRow> Upcoming,
    IReadOnlyList<FreeQuotaRow> FreeQuota,
    string? FormattedComparison,
    int? ChangePercent,
    string CatSpeech,
    string? ComparisonPercentText,
    string? ComparisonCaption,
    string? ComparisonTone,
    IReadOnlyList<AnomalyRow> Anomalies,
    IReadOnlyList<BalanceAlertRow> BalanceAlerts,
    IReadOnlyList<TrendRow> Trend,
    string CatMood)
{
    public static DashboardSnapshot Vacant { get; } = new(
        true, "", true, "—", "—", "—", "exact", [],
        null, null, [], [], [], null, null, "",
        null, null, null, [], [], [], "sleeping");

    public static DashboardSnapshot Parse(string json)
    {
        using var doc = JsonDocument.Parse(string.IsNullOrWhiteSpace(json) ? "{}" : json);
        var root = doc.RootElement;
        Catalog.WarnSchema(root, "dashboard");
        if (root.TryGetProperty("empty", out var empty) && empty.ValueKind == JsonValueKind.True)
        {
            return Vacant with
            {
                MonthTitle = Catalog.Str(root, "monthTitle"),
                CatSpeech = Catalog.Str(root, "catSpeech"),
                CatMood = Catalog.Str(root, "catMood", "sleeping"),
            };
        }
        return new DashboardSnapshot(
            Empty: false,
            MonthTitle: Catalog.Str(root, "monthTitle"),
            AllowsProjection: !root.TryGetProperty("allowsProjection", out var ap) || ap.ValueKind != JsonValueKind.False,
            FormattedTotal: Catalog.Str(root, "formattedTotal", "—"),
            FormattedVariable: Catalog.Str(root, "formattedVariable", "—"),
            FormattedProjected: Catalog.Str(root, "formattedProjected", "—"),
            Confidence: Catalog.Str(root, "confidence", "exact"),
            EstimatedAccountIds: Catalog.Strs(root, "estimatedAccountIDs"),
            SubscriptionFormatted: NullIfBlank(Catalog.Str(root, "subscriptionFormatted")),
            CurrencyNote: NullIfBlank(Catalog.Str(root, "currencyNote")),
            Composition: Map(root, "composition", item => new CompositionRow(
                Catalog.Str(item, "accountID"), Catalog.Str(item, "providerID"),
                Catalog.Str(item, "displayName"), Catalog.Str(item, "colorKey"),
                Catalog.Str(item, "amount"), Catalog.Int(item, "percent"),
                Num(item, "fraction"))),
            Upcoming: Map(root, "upcoming", item => new UpcomingRow(
                Catalog.Str(item, "name"), Catalog.Str(item, "accountID"),
                Catalog.Str(item, "providerID"), Catalog.Str(item, "colorKey"),
                Catalog.Str(item, "amount"), Catalog.Str(item, "dateCaption"))),
            FreeQuota: Map(root, "freeQuota", item => new FreeQuotaRow(
                Catalog.Str(item, "accountID"), Catalog.Str(item, "providerID"),
                Catalog.Str(item, "displayName"), Catalog.Str(item, "colorKey"),
                Catalog.Int(item, "usedPercent"), Catalog.Str(item, "caption"))),
            FormattedComparison: NullIfBlank(Catalog.Str(root, "formattedComparison")),
            ChangePercent: root.TryGetProperty("changePercent", out var cp) && cp.TryGetInt32(out var n) ? n : null,
            CatSpeech: Catalog.Str(root, "catSpeech"),
            ComparisonPercentText: NullIfBlank(Catalog.Str(root, "comparisonPercentText")),
            ComparisonCaption: NullIfBlank(Catalog.Str(root, "comparisonCaption")),
            ComparisonTone: NullIfBlank(Catalog.Str(root, "comparisonTone")),
            Anomalies: Map(root, "anomalies", item => new AnomalyRow(
                Catalog.Str(item, "accountID"), Catalog.Str(item, "providerID"),
                Catalog.Str(item, "displayName"), Catalog.Str(item, "signedPercent"),
                Catalog.Str(item, "caption"), Num(item, "changeRatio"))),
            BalanceAlerts: Map(root, "balanceAlerts", item => new BalanceAlertRow(
                Catalog.Str(item, "accountID"), Catalog.Str(item, "providerID"),
                Catalog.Str(item, "displayName"), Catalog.Str(item, "balance"),
                Catalog.Int(item, "daysRemaining"), Catalog.Str(item, "caption"))),
            Trend: Map(root, "trend", item => new TrendRow(
                Catalog.Str(item, "month"), Catalog.Str(item, "amount"), Num(item, "fraction"))),
            CatMood: Catalog.Str(root, "catMood", "normal"));
    }

    private static string? NullIfBlank(string value) => string.IsNullOrWhiteSpace(value) ? null : value;

    private static double Num(JsonElement el, string name) =>
        el.TryGetProperty(name, out var v) && v.TryGetDouble(out var d) ? d : 0;

    private static IReadOnlyList<T> Map<T>(JsonElement root, string name, Func<JsonElement, T> map)
    {
        if (!root.TryGetProperty(name, out var array) || array.ValueKind != JsonValueKind.Array) return [];
        return array.EnumerateArray().Select(map).ToList();
    }
}

internal sealed record FetchResult(bool Ok, SnapshotRow? Snapshot, string? Spend, string? Error)
{
    public static FetchResult Parse(string json, string accountId)
    {
        using var doc = JsonDocument.Parse(string.IsNullOrWhiteSpace(json) ? "{}" : json);
        var root = doc.RootElement;
        var ok = Catalog.Bool(root, "ok");
        if (!ok)
        {
            return new FetchResult(false, null, null, Catalog.Str(root, "error", "failed"));
        }
        var snapshot = new SnapshotRow(
            ProviderId: Catalog.Str(root, "providerID"),
            AccountId: NullIfBlank(Catalog.Str(root, "accountID")) ?? accountId,
            Kind: Catalog.Str(root, "kind", "usage"),
            Source: Catalog.Str(root, "source", "api"),
            CurrentSpendUsd: NullIfBlank(Catalog.Str(root, "currentSpendUSD")),
            BalanceUsd: NullIfBlank(Catalog.Str(root, "balanceUSD")),
            CommittedMonthlyUsd: NullIfBlank(Catalog.Str(root, "committedMonthlyUSD")),
            ChargeDayOfMonth: root.TryGetProperty("chargeDayOfMonth", out var day) && day.TryGetInt32(out var d) ? d : null,
            FreeQuotaUsedRatio: root.TryGetProperty("freeQuotaUsedRatio", out var r) && r.TryGetDouble(out var ratio) ? ratio : null,
            DailyUsdJson: root.TryGetProperty("dailyUSD", out var daily) ? daily.GetRawText() : null,
            ConvertedJson: root.TryGetProperty("converted", out var conv) ? conv.GetRawText() : null,
            WalletsJson: root.TryGetProperty("wallets", out var wallets) ? wallets.GetRawText() : null,
            PeriodStartMillis: Long(root, "periodStart"),
            PeriodEndMillis: Long(root, "periodEnd"),
            FetchedAtMillis: Long(root, "fetchedAt"));
        return new FetchResult(true, snapshot, NullIfBlank(Catalog.Str(root, "spend")), null);
    }

    private static string? NullIfBlank(string value) => string.IsNullOrWhiteSpace(value) ? null : value;

    private static long Long(JsonElement el, string name) =>
        el.TryGetProperty(name, out var v) && v.TryGetInt64(out var n) ? n : 0;
}

internal sealed record DashboardFilterState(
    int MonthsBack = 0,
    bool IncludesSubscriptions = true,
    IReadOnlySet<string>? ExcludedAccountIds = null)
{
    public const int MaxMonthsBack = 11;

    public IReadOnlySet<string> Excluded => ExcludedAccountIds ?? new HashSet<string>();

    public bool IsActive => MonthsBack > 0 || !IncludesSubscriptions || Excluded.Count > 0;

    public string ToJson()
    {
        var payload = new Dictionary<string, object?>
        {
            ["monthsBack"] = MonthsBack,
            ["includesSubscriptions"] = IncludesSubscriptions,
            ["excludedAccounts"] = Excluded.ToList(),
        };
        return JsonSerializer.Serialize(payload);
    }
}

internal sealed record SetupGuideDoc(bool Missing, string Json)
{
    public static SetupGuideDoc Parse(string json)
    {
        using var doc = JsonDocument.Parse(string.IsNullOrWhiteSpace(json) ? "{}" : json);
        var missing = Catalog.Bool(doc.RootElement, "missing");
        return new SetupGuideDoc(missing, json);
    }
}

internal sealed record ChartPoint(long BucketMillis, double Amount);

internal abstract record HistoryChartState
{
    public sealed record Spend(
        IReadOnlyList<ChartPoint> Points,
        long StartMillis,
        long EndMillis,
        bool Monthly,
        bool IsIntervalSpend,
        IReadOnlyList<long> Buckets,
        IReadOnlyList<double> AxisMarks) : HistoryChartState;

    public sealed record Balance(
        IReadOnlyList<ChartPoint> Points,
        long StartMillis,
        long EndMillis,
        bool Monthly,
        IReadOnlySet<long> InferredStarts,
        IReadOnlyList<long> Buckets,
        IReadOnlyList<double> AxisMarks) : HistoryChartState;

    public sealed record None : HistoryChartState
    {
        public static None Instance { get; } = new();
    }

    public static HistoryChartState Parse(string json)
    {
        using var doc = JsonDocument.Parse(string.IsNullOrWhiteSpace(json) ? "{}" : json);
        var root = doc.RootElement;
        return Catalog.Str(root, "kind") switch
        {
            "spend" => new Spend(
                Points(root), Long(root, "startMillis"), Long(root, "endMillis"),
                Catalog.Bool(root, "monthly"), Catalog.Bool(root, "isIntervalSpend"),
                Longs(root, "buckets"), Doubles(root, "axisMarks")),
            "balance" => new Balance(
                Points(root), Long(root, "startMillis"), Long(root, "endMillis"),
                Catalog.Bool(root, "monthly"), Longs(root, "inferredStarts").ToHashSet(),
                Longs(root, "buckets"), Doubles(root, "axisMarks")),
            _ => None.Instance,
        };
    }

    private static IReadOnlyList<ChartPoint> Points(JsonElement root)
    {
        if (!root.TryGetProperty("points", out var array) || array.ValueKind != JsonValueKind.Array) return [];
        return array.EnumerateArray()
            .Select(item => new ChartPoint(Long(item, "bucket"), Num(item, "amount")))
            .ToList();
    }

    private static IReadOnlyList<long> Longs(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var array) || array.ValueKind != JsonValueKind.Array) return [];
        return array.EnumerateArray().Select(v => v.TryGetInt64(out var n) ? n : 0).ToList();
    }

    private static IReadOnlyList<double> Doubles(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var array) || array.ValueKind != JsonValueKind.Array) return [];
        return array.EnumerateArray().Select(v => v.TryGetDouble(out var n) ? n : 0).ToList();
    }

    private static long Long(JsonElement el, string name) =>
        el.TryGetProperty(name, out var v) && v.TryGetInt64(out var n) ? n : 0;

    private static double Num(JsonElement el, string name) =>
        el.TryGetProperty(name, out var v) && v.TryGetDouble(out var d) ? d : 0;
}
