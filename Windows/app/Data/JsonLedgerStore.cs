using System.Text.Json;
using System.Text.Json.Serialization;

namespace TollCat;

/// <summary>
/// 对照 Android SQLite schema v4 的本机账本。不引第三方 SQLite 包，
/// 快照序列化口径仍以 ProductSnapshotCodec 为准——这里只落已经编好的字段。
/// </summary>
internal sealed class JsonLedgerStore : ILedgerStore
{
    private const int Version = 4;
    private readonly string _path;
    private readonly object _gate = new();
    private Document _doc;

    public JsonLedgerStore(string path)
    {
        _path = path;
        _doc = Load(path);
    }

    public void InsertSnapshot(SnapshotRow row)
    {
        lock (_gate)
        {
            _doc.Snapshots.Add(row);
            Persist();
        }
    }

    public void ReplaceAccountSnapshots(string accountId, SnapshotRow row)
    {
        lock (_gate)
        {
            _doc.Snapshots.RemoveAll(s => s.AccountId == accountId);
            _doc.Snapshots.Add(row);
            Persist();
        }
    }

    public IReadOnlyList<SnapshotRow> Snapshots()
    {
        lock (_gate)
        {
            return _doc.Snapshots.OrderBy(s => s.FetchedAtMillis).ToList();
        }
    }

    public void UpsertMembership(MembershipRow row)
    {
        lock (_gate)
        {
            _doc.Memberships.RemoveAll(m => m.ProviderId == row.ProviderId);
            _doc.Memberships.Add(row);
            Persist();
        }
    }

    public IReadOnlyList<MembershipRow> Memberships()
    {
        lock (_gate)
        {
            return _doc.Memberships.OrderBy(m => m.SortIndex).ToList();
        }
    }

    public void DeleteMembership(string providerId)
    {
        lock (_gate)
        {
            foreach (var account in _doc.Accounts.Where(a => a.ProviderId == providerId).ToList())
            {
                _doc.Snapshots.RemoveAll(s => s.AccountId == account.AccountId);
                _doc.Accounts.RemoveAll(a => a.AccountId == account.AccountId);
            }
            _doc.Subscriptions.RemoveAll(s => s.ProviderId == providerId);
            _doc.Memberships.RemoveAll(m => m.ProviderId == providerId);
            Persist();
        }
    }

    public void UpsertAccount(AccountRow row)
    {
        lock (_gate)
        {
            _doc.Accounts.RemoveAll(a => a.AccountId == row.AccountId);
            _doc.Accounts.Add(row);
            Persist();
        }
    }

    public IReadOnlyList<AccountRow> Accounts()
    {
        lock (_gate)
        {
            return _doc.Accounts.OrderBy(a => a.SortIndex).ToList();
        }
    }

    public IReadOnlyList<AccountRow> Accounts(string providerId)
    {
        lock (_gate)
        {
            return _doc.Accounts.Where(a => a.ProviderId == providerId).OrderBy(a => a.SortIndex).ToList();
        }
    }

    public void DeleteAccount(string accountId)
    {
        lock (_gate)
        {
            _doc.Snapshots.RemoveAll(s => s.AccountId == accountId);
            _doc.Subscriptions.RemoveAll(s => s.AccountId == accountId);
            _doc.Accounts.RemoveAll(a => a.AccountId == accountId);
            Persist();
        }
    }

    public void UpsertSubscription(SubscriptionRow row)
    {
        lock (_gate)
        {
            _doc.Subscriptions.RemoveAll(s => s.Name == row.Name);
            _doc.Subscriptions.Add(row);
            Persist();
        }
    }

    public IReadOnlyList<SubscriptionRow> Subscriptions()
    {
        lock (_gate)
        {
            return _doc.Subscriptions.OrderBy(s => s.Name).ToList();
        }
    }

    public void DeleteSubscription(string name)
    {
        lock (_gate)
        {
            _doc.Subscriptions.RemoveAll(s => s.Name == name);
            Persist();
        }
    }

    public void ClearAll()
    {
        lock (_gate)
        {
            _doc = new Document { Schema = Version };
            Persist();
        }
    }

    private void Persist()
    {
        var dir = Path.GetDirectoryName(_path);
        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
        var json = JsonSerializer.Serialize(_doc, LedgerJson.Options);
        var tmp = _path + ".tmp";
        File.WriteAllText(tmp, json);
        File.Move(tmp, _path, overwrite: true);
    }

    private static Document Load(string path)
    {
        if (!File.Exists(path)) return new Document { Schema = Version };
        try
        {
            var json = File.ReadAllText(path);
            return JsonSerializer.Deserialize<Document>(json, LedgerJson.Options)
                ?? new Document { Schema = Version };
        }
        catch (JsonException)
        {
            return new Document { Schema = Version };
        }
    }

    private sealed class Document
    {
        public int Schema { get; set; } = Version;
        public List<SnapshotRow> Snapshots { get; set; } = [];
        public List<MembershipRow> Memberships { get; set; } = [];
        public List<AccountRow> Accounts { get; set; } = [];
        public List<SubscriptionRow> Subscriptions { get; set; } = [];
    }
}

internal static class LedgerJson
{
    public static readonly JsonSerializerOptions Options = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };
}
