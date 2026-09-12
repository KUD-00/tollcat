using TollCat;
using Xunit;

namespace TollCat.Tests;

public class JsonLedgerStoreTests
{
    [Fact]
    public void RoundTripMembershipAccountAndSnapshot()
    {
        var path = Path.Combine(Path.GetTempPath(), "tollcat-test-" + Guid.NewGuid() + ".json");
        try
        {
            var store = new JsonLedgerStore(path);
            store.UpsertMembership(new MembershipRow("openai", 0));
            var account = new AccountRow(Guid.NewGuid().ToString(), "openai", "acct.1", 0);
            store.UpsertAccount(account);
            store.ReplaceAccountSnapshots(account.AccountId, new SnapshotRow(
                "openai", account.AccountId, "usage", "api",
                "7.62", null, null, null, null, null, null, null,
                0, 0, 1_700_000_000_000));
            Assert.Single(store.Memberships());
            Assert.Single(store.Accounts("openai"));
            Assert.Equal("7.62", store.Snapshots().Single().CurrentSpendUsd);

            var reload = new JsonLedgerStore(path);
            Assert.Equal("openai", reload.Memberships().Single().ProviderId);
            Assert.Equal("7.62", reload.Snapshots().Single().CurrentSpendUsd);
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }
    }
}
