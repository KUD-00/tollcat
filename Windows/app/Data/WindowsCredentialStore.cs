using System.Runtime.InteropServices;
using System.Text;
using Windows.Security.Cryptography;
using Windows.Security.Cryptography.DataProtection;
using Windows.Storage;
using Windows.Storage.Streams;

namespace TollCat;

/// <summary>
/// Windows 侧的凭据存储。对齐 iOS Keychain / Android Keystore 的隔离粒度。
///
/// 不能用凭据管理器的通用凭据：Win32 GENERIC 凭据**按用户隔离，不按包族隔离**，
/// 同一用户下任意进程 <c>CredEnumerateW("TollCat/*")</c> + <c>CredReadW</c> 就能
/// 取走云厂商密钥，既不用注入本进程也不用等它运行，锁屏后照样可读。
///
/// 改成两层：
/// 1. 信封先过 <c>DataProtectionProvider("LOCAL=app")</c>。这个描述符把密文绑定到
///    **本包族**，别的应用即使拿到密文也 Unprotect 不出来。
/// 2. 密文落 <c>ApplicationData.Current.LocalFolder</c>，本身就是每个包独立的目录。
///
/// 旧版本写进凭据管理器的条目在首次读到时迁移过来并从 CredMan 删除；
/// <see cref="DeleteAll"/> 也会把残留的旧条目一并扫掉。
/// </summary>
internal sealed class WindowsCredentialStore : ICredentialStore
{
    /// 旧实现的目标名前缀。只用于迁移与清理，不再写入。
    private const string LegacyPrefix = "TollCat/";
    private const uint CredTypeGeneric = 1;

    /// LOCAL=app：绑定到本包族，同用户的别的应用解不开。
    private const string ProtectionDescriptor = "LOCAL=app";

    private const string FolderName = "credentials";

    private static string Folder
    {
        get
        {
            var path = Path.Combine(ApplicationData.Current.LocalFolder.Path, FolderName);
            Directory.CreateDirectory(path);
            return path;
        }
    }

    /// reference 里可能出现路径分隔符，一律转成十六进制当文件名。
    private static string FileFor(string reference)
        => Path.Combine(Folder, Convert.ToHexString(Encoding.UTF8.GetBytes(reference)) + ".bin");

    public void Save(string secret, string reference)
    {
        File.WriteAllBytes(FileFor(reference), Protect(Encoding.UTF8.GetBytes(secret)));
    }

    public string? Read(string reference)
    {
        var file = FileFor(reference);
        if (File.Exists(file))
        {
            try
            {
                return Encoding.UTF8.GetString(Unprotect(File.ReadAllBytes(file)));
            }
            catch (Exception)
            {
                // 密文解不开（换机、包身份变了）等同没有这条凭据。
                return null;
            }
        }

        // 旧版本写在凭据管理器里的，读到就迁过来再删掉。
        var legacy = ReadLegacy(reference);
        if (legacy is null) return null;
        Save(legacy, reference);
        DeleteLegacy(reference);
        return legacy;
    }

    public void Delete(string reference)
    {
        var file = FileFor(reference);
        if (File.Exists(file)) File.Delete(file);
        DeleteLegacy(reference);
    }

    /// <summary>
    /// 清空。账本与凭据库分叉时（例如 ledger.json 被旧备份覆盖），逐条 Delete 扫不到
    /// 的孤儿条目必须由这里兜底，否则密钥会留在盘上/凭据库里。
    /// </summary>
    public void DeleteAll()
    {
        if (Directory.Exists(Folder))
        {
            foreach (var file in Directory.EnumerateFiles(Folder, "*.bin"))
            {
                File.Delete(file);
            }
        }
        DeleteAllLegacy();
    }

    // ── DPAPI（包族绑定） ───────────────────────────────────────────

    // WinRT 的 Protect/Unprotect 只有异步版。丢到线程池上等，避免在 UI 线程上
    // 直接 GetResult 造成的死锁。
    private static byte[] Protect(byte[] plain)
        => Task.Run(async () =>
        {
            var provider = new DataProtectionProvider(ProtectionDescriptor);
            var protectedBuffer = await provider.ProtectAsync(CryptographicBuffer.CreateFromByteArray(plain));
            CryptographicBuffer.CopyToByteArray(protectedBuffer, out var bytes);
            return bytes;
        }).GetAwaiter().GetResult();

    private static byte[] Unprotect(byte[] cipher)
        => Task.Run(async () =>
        {
            var provider = new DataProtectionProvider();
            var plainBuffer = await provider.UnprotectAsync(CryptographicBuffer.CreateFromByteArray(cipher));
            CryptographicBuffer.CopyToByteArray(plainBuffer, out var bytes);
            return bytes;
        }).GetAwaiter().GetResult();

    // ── 旧凭据管理器条目：只读、只删，不再写入 ───────────────────────

    private static string? ReadLegacy(string reference)
    {
        if (!CredReadW(LegacyPrefix + reference, CredTypeGeneric, 0, out var ptr)) return null;
        try
        {
            var cred = Marshal.PtrToStructure<CREDENTIAL>(ptr);
            if (cred.CredentialBlob == nint.Zero || cred.CredentialBlobSize == 0) return null;
            var bytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, bytes, 0, bytes.Length);
            return Encoding.UTF8.GetString(bytes);
        }
        finally
        {
            CredFree(ptr);
        }
    }

    private static void DeleteLegacy(string reference)
        => CredDeleteW(LegacyPrefix + reference, CredTypeGeneric, 0);

    /// CredEnumerateW 的 Filter 支持 <c>TollCat/*</c>——旧注释说「没有按前缀批量删的
    /// API」是不对的，孤儿条目就是这么留下来的。
    private static void DeleteAllLegacy()
    {
        if (!CredEnumerateW(LegacyPrefix + "*", 0, out var count, out var ptr)) return;
        try
        {
            for (var i = 0; i < count; i++)
            {
                var entry = Marshal.ReadIntPtr(ptr, i * nint.Size);
                var cred = Marshal.PtrToStructure<CREDENTIAL>(entry);
                if (!string.IsNullOrEmpty(cred.TargetName))
                {
                    CredDeleteW(cred.TargetName, CredTypeGeneric, 0);
                }
            }
        }
        finally
        {
            CredFree(ptr);
        }
    }

    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredReadW(string target, uint type, uint flags, out nint credential);

    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredDeleteW(string target, uint type, uint flags);

    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredEnumerateW(string filter, uint flags, out uint count, out nint credentials);

    [DllImport("advapi32.dll")]
    private static extern void CredFree(nint buffer);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL
    {
        public uint Flags;
        public uint Type;
        public string TargetName;
        public string? Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public nint CredentialBlob;
        public uint Persist;
        public uint AttributeCount;
        public nint Attributes;
        public string? TargetAlias;
        public string? UserName;
    }
}
