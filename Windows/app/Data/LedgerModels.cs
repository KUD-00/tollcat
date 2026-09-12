namespace TollCat;

internal sealed record SnapshotRow(
    string ProviderId,
    string AccountId,
    string Kind,
    string Source,
    string? CurrentSpendUsd,
    string? BalanceUsd,
    string? CommittedMonthlyUsd,
    int? ChargeDayOfMonth,
    double? FreeQuotaUsedRatio,
    string? DailyUsdJson,
    string? ConvertedJson,
    string? WalletsJson,
    long PeriodStartMillis,
    long PeriodEndMillis,
    long FetchedAtMillis);

internal sealed record MembershipRow(string ProviderId, int SortIndex);

internal sealed record AccountRow(
    string AccountId,
    string ProviderId,
    string CredentialReference,
    int SortIndex);

internal sealed record SubscriptionRow(
    string Name,
    string AmountUsd,
    string Period,
    int AnchorYear,
    int AnchorMonth,
    int AnchorDay,
    string? ProviderId,
    string? AccountId);

internal interface ILedgerStore
{
    void InsertSnapshot(SnapshotRow row);
    void ReplaceAccountSnapshots(string accountId, SnapshotRow row);
    IReadOnlyList<SnapshotRow> Snapshots();
    void UpsertMembership(MembershipRow row);
    IReadOnlyList<MembershipRow> Memberships();
    void DeleteMembership(string providerId);
    void UpsertAccount(AccountRow row);
    IReadOnlyList<AccountRow> Accounts();
    IReadOnlyList<AccountRow> Accounts(string providerId);
    void DeleteAccount(string accountId);
    void UpsertSubscription(SubscriptionRow row);
    IReadOnlyList<SubscriptionRow> Subscriptions();
    void DeleteSubscription(string name);
    void ClearAll();
}

internal interface ICredentialStore
{
    void Save(string secret, string reference);
    string? Read(string reference);
    void Delete(string reference);
    void DeleteAll();
}
