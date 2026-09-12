using System.Text.Json;
using System.Text.Json.Nodes;
using Windows.Storage;

namespace TollCat;

internal sealed class Session
{
    public static Session Current { get; } = Create();

    public ICredentialStore Credentials { get; }
    public ILedgerStore Ledger { get; }
    public PreferencesStore Preferences { get; }

    public Catalog Catalog { get; private set; } = new([], ["USD"]);
    public DashboardSnapshot Dashboard { get; private set; } = DashboardSnapshot.Vacant;
    public DashboardFilterState Filter { get; private set; } = new();
    public bool IsRefreshing { get; private set; }
    public string? RefreshMessage { get; private set; }
    public string DisplayCurrency { get; private set; }
    public event Action? Changed;

    private Session(ICredentialStore credentials, ILedgerStore ledger, PreferencesStore preferences)
    {
        Credentials = credentials;
        Ledger = ledger;
        Preferences = preferences;
        DisplayCurrency = preferences.DisplayCurrency;
    }

    public static Session Create()
    {
        NativeBootstrap.Ensure();
        var folder = ApplicationData.Current.LocalFolder.Path;
        var session = new Session(
            new WindowsCredentialStore(),
            new JsonLedgerStore(Path.Combine(folder, "ledger.json")),
            new PreferencesStore());
        session.Bootstrap();
        return session;
    }

    public void Bootstrap()
    {
        Catalog = RunCatching(
            () => Catalog.Parse(MeterCoreNative.CatalogJson(LocaleTag.Current)),
            new Catalog([], ["USD"]));
        Recompute();
    }

    public IReadOnlyList<MembershipRow> Memberships() => Ledger.Memberships();

    public IReadOnlyList<AccountRow> Accounts(string providerId) => Ledger.Accounts(providerId);

    public bool HasCredentials(AccountRow account) =>
        !string.IsNullOrWhiteSpace(Credentials.Read(account.CredentialReference));

    public SnapshotRow? LatestSnapshot(string providerId) =>
        Ledger.Snapshots().Where(s => s.ProviderId == providerId).MaxBy(s => s.FetchedAtMillis);

    public void AddProvider(string providerId)
    {
        if (Ledger.Memberships().Any(m => m.ProviderId == providerId)) return;
        Ledger.UpsertMembership(new MembershipRow(providerId, Ledger.Memberships().Count));
        var accountId = Guid.NewGuid().ToString();
        Ledger.UpsertAccount(new AccountRow(accountId, providerId, "acct." + accountId, 0));
        Recompute();
        Notify();
    }

    public void RemoveProvider(string providerId)
    {
        foreach (var account in Ledger.Accounts(providerId))
        {
            Credentials.Delete(account.CredentialReference);
        }
        Ledger.DeleteMembership(providerId);
        Recompute();
        Notify();
    }

    public void SaveCredentials(AccountRow account, IReadOnlyDictionary<string, string> fields)
    {
        Credentials.Save(JsonSerializer.Serialize(fields), account.CredentialReference);
    }

    public IReadOnlyDictionary<string, string> LoadCredentialFields(AccountRow account)
    {
        var raw = Credentials.Read(account.CredentialReference);
        if (string.IsNullOrWhiteSpace(raw)) return new Dictionary<string, string>();
        try
        {
            var node = JsonNode.Parse(raw) as JsonObject;
            if (node is null) return new Dictionary<string, string>();
            return node.ToDictionary(p => p.Key, p => p.Value?.ToString() ?? "");
        }
        catch (JsonException)
        {
            return new Dictionary<string, string>();
        }
    }

    public FetchResult TestAndSave(AccountRow account, IReadOnlyDictionary<string, string> fields, bool persist)
    {
        var filled = fields.Where(p => !string.IsNullOrWhiteSpace(p.Value))
            .ToDictionary(p => p.Key, p => p.Value);
        var result = Fetch(account, filled);
        if (result.Ok && persist)
        {
            SaveCredentials(account, filled);
            if (result.Snapshot is not null)
            {
                Ledger.ReplaceAccountSnapshots(account.AccountId, result.Snapshot);
            }
            Recompute();
        }
        Notify();
        return result;
    }

    public async Task RefreshAllAsync()
    {
        if (IsRefreshing) return;
        IsRefreshing = true;
        RefreshMessage = null;
        Notify();
        // IsRefreshing 只在 finally 里复位：body 里任何一处抛
        //（坏 ledger 的 Recompute、Persist 的 IO、桥调用）都不能把刷新永久卡死。
        try
        {
            await Task.Run(() =>
            {
                var accounts = Ledger.Accounts();
                if (accounts.Count == 0)
                {
                    RefreshMessage = "empty";
                    Recompute();
                    return;
                }
                var ok = 0;
                var fail = 0;
                var nowMillis = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
                foreach (var account in accounts)
                {
                    var provider = Catalog.Provider(account.ProviderId);
                    if (provider?.CostsMoneyToRefresh == true) continue;
                    var lastFetched = Ledger.Snapshots()
                        .Where(s => s.AccountId == account.AccountId)
                        .MaxBy(s => s.FetchedAtMillis)
                        ?.FetchedAtMillis ?? 0;
                    if (provider is not null && !provider.ShouldFetch(lastFetched, nowMillis)) continue;
                    var fields = LoadCredentialFields(account);
                    var result = Fetch(account, fields);
                    if (result.Ok && result.Snapshot is not null)
                    {
                        Ledger.ReplaceAccountSnapshots(account.AccountId, result.Snapshot);
                        ok += 1;
                    }
                    else
                    {
                        fail += 1;
                    }
                }
                RefreshMessage = $"ok:{ok} fail:{fail}";
                Recompute();
                ToastService.NotifyBalanceAlerts(Dashboard);
            });
        }
        catch (Exception e)
        {
            RefreshMessage = $"error:{e.GetType().Name}";
        }
        finally
        {
            IsRefreshing = false;
            Notify();
        }
    }

    public void SetCurrency(string code)
    {
        DisplayCurrency = code;
        Preferences.DisplayCurrency = code;
        Recompute();
        Notify();
    }

    public void ApplyFilter(DashboardFilterState next)
    {
        Filter = next;
        Recompute();
        Notify();
    }

    public SetupGuideDoc SetupGuide(string providerId) =>
        SetupGuideDoc.Parse(MeterCoreNative.SetupGuideJson(providerId, LocaleTag.Current));

    public void ClearAll()
    {
        foreach (var account in Ledger.Accounts())
        {
            Credentials.Delete(account.CredentialReference);
        }
        Credentials.DeleteAll();
        Ledger.ClearAll();
        Preferences.Clear();
        DisplayCurrency = "USD";
        Filter = new DashboardFilterState();
        Recompute();
        Notify();
    }

    public string FormatUsd(string raw) =>
        MeterCoreNative.FormatUsd(raw, DisplayCurrency, LocaleTag.Current);

    public HistoryChartState HistoryChart(string providerId, string range)
    {
        var snapshots = new JsonArray();
        foreach (var row in Ledger.Snapshots().Where(s => s.ProviderId == providerId))
        {
            snapshots.Add(SnapshotJson(row));
        }
        return HistoryChartState.Parse(
            MeterCoreNative.HistoryChartJson(providerId, snapshots.ToJsonString(), range, NowMillis()));
    }

    public void Recompute()
    {
        Dashboard = ComputeDashboard();
    }

    public long NowMillis() => DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

    private DashboardSnapshot ComputeDashboard()
    {
        var snapshots = new JsonArray();
        foreach (var row in Ledger.Snapshots()) snapshots.Add(SnapshotJson(row));
        var subscriptions = new JsonArray();
        foreach (var row in Ledger.Subscriptions())
        {
            var obj = new JsonObject
            {
                ["name"] = row.Name,
                ["amountUSD"] = row.AmountUsd,
                ["period"] = row.Period,
                ["anchorYear"] = row.AnchorYear,
                ["anchorMonth"] = row.AnchorMonth,
                ["anchorDay"] = row.AnchorDay,
            };
            if (row.ProviderId is not null) obj["providerID"] = row.ProviderId;
            if (row.AccountId is not null) obj["accountID"] = row.AccountId;
            subscriptions.Add(obj);
        }
        return RunCatching(
            () => DashboardSnapshot.Parse(
                MeterCoreNative.ComputeDashboardJson(
                    snapshots.ToJsonString(),
                    subscriptions.ToJsonString(),
                    NowMillis(),
                    DisplayCurrency,
                    LocaleTag.Current,
                    Filter.ToJson())),
            DashboardSnapshot.Vacant);
    }

    private FetchResult Fetch(AccountRow account, IReadOnlyDictionary<string, string> fields)
    {
        var payload = JsonSerializer.Serialize(fields);
        var json = MeterCoreNative.FetchProviderJson(account.ProviderId, payload, NowMillis());
        return FetchResult.Parse(json, account.AccountId);
    }

    private static JsonObject SnapshotJson(SnapshotRow row)
    {
        var obj = new JsonObject
        {
            ["providerID"] = row.ProviderId,
            ["accountID"] = row.AccountId,
            ["kind"] = row.Kind,
            ["source"] = row.Source,
            ["fetchedAt"] = row.FetchedAtMillis,
            ["periodStart"] = row.PeriodStartMillis,
            ["periodEnd"] = row.PeriodEndMillis,
        };
        if (row.CurrentSpendUsd is not null) obj["currentSpendUSD"] = row.CurrentSpendUsd;
        if (row.BalanceUsd is not null) obj["balanceUSD"] = row.BalanceUsd;
        if (row.CommittedMonthlyUsd is not null) obj["committedMonthlyUSD"] = row.CommittedMonthlyUsd;
        if (row.ChargeDayOfMonth is int day) obj["chargeDayOfMonth"] = day;
        if (row.FreeQuotaUsedRatio is double ratio) obj["freeQuotaUsedRatio"] = ratio;
        if (row.DailyUsdJson is not null) obj["dailyUSD"] = JsonNode.Parse(row.DailyUsdJson);
        if (row.ConvertedJson is not null) obj["converted"] = JsonNode.Parse(row.ConvertedJson);
        if (row.WalletsJson is not null) obj["wallets"] = JsonNode.Parse(row.WalletsJson);
        return obj;
    }

    private void Notify() => Changed?.Invoke();

    private static T RunCatching<T>(Func<T> body, T fallback)
    {
        try { return body(); }
        catch { return fallback; }
    }
}
