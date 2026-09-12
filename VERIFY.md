# How to confirm the App Store app is this source code

English · [中文](VERIFY.zh.md)

On iOS there is no way to compile a byte-for-byte identical copy of the binary on your
phone from this source. Apple re-signs it, wraps the executable in FairPlay encryption,
and thins it per device; Xcode's own builds aren't bit-for-bit deterministic either. So
this document does not promise — or pretend to offer — that kind of reproducibility.
What can be established is a shorter chain of trust.

**The first release must be verified by a human once.** The release workflow below is
written, but the author of this repo has not yet run it end-to-end with real App Store
Connect credentials. Until that manual verification happens, treat it as a "release
pipeline not yet activated", not as something that has already happened.

## 1. How the chain of trust connects

Two segments, each solving one problem.

### Source → build artifact

Official builds happen only in public GitHub Actions, from a tag. The workflow is
[`.github/workflows/release.yml`](.github/workflows/release.yml). It:

1. Generates the project from that tag's commit and runs `xcodebuild archive`
2. Exports the IPA and uploads it to App Store Connect
3. Uses `actions/attest-build-provenance` to sign a provenance attestation for the
   **IPA** and the **dSYM archive** (who built it, in which run, from which commit)
4. Attaches to the GitHub Release: the IPA's sha256, the full output of
   `dwarfdump --uuid`, the dSYMs, and the Xcode / macOS versions and commit at
   build time

The upload uses `xcrun altool --upload-app` with only an App Store Connect API key.
Not `notarytool`: that is for Developer ID notarization of Mac software, not iOS
submission. Not fastlane: one more third-party dependency this project doesn't need.

PRs and ordinary pushes go through
[`.github/workflows/ci.yml`](.github/workflows/ci.yml), which **reads no secrets** —
forks can run it too.

### Build artifact → the app on your phone

Apple's re-signing, FairPlay, and per-device thinning all change file bytes, so the
IPA's sha256 will not match what the App Store delivers to your phone. That is normal.

The Mach-O `LC_UUID` survives re-signing — Apple's own crash symbolication depends on
it. Compare the UUID of the executable on your phone against the `uuids.txt` published
with the release. If they match, it is the product of the same link.

## 2. Verifying the provenance attestation

First download this build's IPA from the GitHub Release (the copy CI just built, not
yet encrypted by the App Store), then:

```bash
gh attestation verify TollCat.ipa --repo <owner>/<repo>
```

Replace `<owner>/<repo>` with the repository you are looking at, e.g. `someone/cost`.

Expected: the command exits 0 and prints a summary of the attestation — the subject
matches the IPA's digest, the predicate is SLSA provenance, and the signer is this
repository's `release.yml` run. If anything doesn't match, or the file was never
attested by this repository, `gh` exits non-zero.

The dSYMs can be verified the same way:

```bash
gh attestation verify TollCat.dSYMs.zip --repo <owner>/<repo>
```

If the repository has never completed a successful tag release, both commands will
fail. That is part of what "the first release must be verified by a human" means.

## 3. Comparing UUIDs

The `uuids.txt` in the release assets is the full output of `dwarfdump --uuid`, one
line per architecture slice. The app and the widget each have their own UUID.

### Extracting `LC_UUID` from an installed app

On a non-jailbroken device, copying the App Store IPA out intact is very hard: the
system won't let you read another app's bundle, and the encrypted executable can't be
opened as an ordinary file. Realistically these are the only paths:

1. **Crash reports (most practical)**
   Settings → Privacy & Security → Analytics & Improvements → Analytics Data,
   open a crash from this app (or one synced into Xcode Organizer).
   Binary Images will contain a line like:

   ```
   TollCat arm64  <XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX> /var/containers/Bundle/Application/…/TollCat.app/TollCat
   ```

   The value in angle brackets is the `LC_UUID`. Compare it against the app
   executable's line in `uuids.txt`.

2. **A Debug / development build you installed with Xcode yourself**
   That is a different binary; its UUID was never going to match the App Store copy.
   It only proves "this source builds and runs" — it cannot vouch for the one in the
   store.

3. **A jailbroken or decrypted IPA**
   `dwarfdump --uuid Payload/TollCat.app/TollCat`.
   Without a jailbreak, don't count on this path.

No match: not the same link. Match: it is the build CI produced on that tag, then
signed, encrypted, and thinned by Apple.

## 4. Don't trust it? Build it yourself

This is the hardest answer for the genuinely suspicious. A free Apple ID can install
onto your own device, valid for about 7 days; rebuild when it expires.

The build you produce **will not, and should not,** have the same UUID as the App
Store copy. The point of this section is to watch with your own eyes what the source
does on your own machine — not to reproduce the store's bytes.

1. Install Xcode 26+ and sign in with your Apple ID.
2. Clone this repository. Don't change dependency directions, and don't add
   third-party libraries.

   ```bash
   git clone <this-repo>
   cd cost
   nix shell nixpkgs#xcodegen -c xcodegen generate                          # iOS
   nix shell nixpkgs#xcodegen -c xcodegen generate --spec project-mac.yml   # Mac
   ```

   No nix? `brew install xcodegen`, then the same two `xcodegen generate` calls.
   The iOS project has no remote packages at all; only the Mac one resolves
   Sparkle.

3. Open `TollCat.xcodeproj` in Xcode. Under Signing & Capabilities:
   - Switch Team to your own personal team
   - If the bundle id `com.zhechengqi.tollcat` is taken, change it to your own
     (change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` and the App Group
     `group.com.zhechengqi.tollcat` together, then re-run `xcodegen generate`)
4. Plug in your iPhone, trust the computer, select the device, Run.
5. On a free account the first run will prompt to register the bundle id and App
   Group; follow Xcode's prompts.
6. Open Settings → About and check the outbound host list. It renders the same data
   as `OutboundHosts.swift`.

At the current stage fetching still runs on mocks. What you're checking: no unknown
outbound traffic, credentials go only into the local Keychain, and the tip worker
can't reach billing data.

## 5. Outbound hosts

More important than binary equivalence: "will my AWS key be sent somewhere?"

- Compile-time list: `Packages/MeterKit/Sources/MeterProviders/OutboundHosts.swift`
- Settings → About renders this list directly
- `scripts/check-outbound-hosts.sh` scans the source for `https://` literals and fails
  CI if a host isn't on the list

Billing credentials and billing data go only to each vendor's own API. Tip messages go
only to the one worker on the list. In-app purchases go through the system and never
touch our server.

## 6. What a human must confirm before the first release

The workflow syntax has been checked with `actionlint`. The following have **never
run** without real credentials; someone must complete them before the first tag:

1. Stock these encrypted secrets in GitHub Environments (not repo-level, never in the
   repo; which secret goes in which environment and which environments require
   reviewers is in `docs/RELEASE.md`):
   - `APP_STORE_CONNECT_KEY_ID`
   - `ISSUER_ID`
   - `PRIVATE_KEY` (base64 of the `.p8`)
   - `BUILD_CERTIFICATE_BASE64` (base64 of the Apple Distribution `.p12`)
   - `P12_PASSWORD`
   - `DEVELOPER_ID_CERTIFICATE_BASE64` (base64 of the Developer ID Application `.p12`,
     for the direct-download Mac build; only the account holder can create this
     certificate on the developer site — Xcode won't generate it for CI)
   - `DEVELOPER_ID_P12_PASSWORD`
   - `SPARKLE_PRIVATE_KEY` (the EdDSA private key exported by Sparkle's
     `generate_keys -x`, paired with `SUPublicEDKey` in `Mac/Supporting-Info.plist`;
     **never rotate it** — every installed Mac copy would refuse all future updates)
2. The API key has enough App Store Connect permission to upload builds (Admin or
   App Manager).
3. The bundle id `com.zhechengqi.tollcat` exists under this team, and `teamID` in
   `scripts/ExportOptions.plist` matches.
4. Push a test tag and watch all five steps succeed: archive, export,
   `altool --upload-app`, attest, GitHub Release (draft). The release is a draft;
   Mac Sparkle clients can't see it until you click Publish.
5. Run `gh attestation verify` against the just-attached IPA / dSYMs.
6. Open the release's `uuids.txt`; confirm every slice of the app and the widget is
   present and matches the live `dwarfdump --uuid` output from the archive.
7. After TestFlight / App Store processing completes, copy the UUID out of a crash
   report from a real device and compare it against `uuids.txt` — the only moment in
   the whole chain that touches "the app on a user's phone".

## 7. Direct-download Mac build: verifying the zip and auto-updates

The Mac build skips the App Store: Developer ID signing + notarization, then Sparkle
updates it in place. This chain is shorter than iOS: the zip you download is exactly
what CI built — there is no Apple re-signing step.

The same tag's release carries, on the Mac side: `TollCat-<version>-mac.zip`, its
`.sha256`, `TollCat-mac.dSYMs.zip`, `uuids-mac.txt`, `build-info-mac.txt`, and
`appcast.xml`. They are produced by
[`scripts/package-mac-release.sh`](scripts/package-mac-release.sh).

### The downloaded zip

```bash
gh attestation verify TollCat-1.0.0-mac.zip --repo <owner>/<repo>
shasum -a 256 -c TollCat-1.0.0-mac.zip.sha256
ditto -x -k TollCat-1.0.0-mac.zip .
spctl -a -vv -t exec TollCat.app          # expect: accepted, source=Notarized Developer ID
xcrun stapler validate TollCat.app        # expect: The validate action worked!
codesign -dv --entitlements :- TollCat.app
```

The entitlements should contain only what `TollCatMac` declares in `project-mac.yml`:
sandbox, network client, user-selected files, App Group, Keychain group, and the two
`temporary-exception.mach-lookup.global-name` entries for Sparkle's installer service
(`…-spks` / `…-spki`). One entry more is one too many.

`dwarfdump --uuid TollCat.app/Contents/MacOS/TollCat` should match `uuids-mac.txt`
verbatim.

### The auto-update feed

The app reads its feed from `SUFeedURL` (`Mac/Supporting-Info.plist`), i.e.
`releases/download/mac-appcast/appcast.xml` — a rolling release whose tag is fixed at
`mac-appcast`, **not** `releases/latest`. iOS and Mac do not ride the same train, so an
iOS-only release becoming "latest" must not break Mac updates. Whenever a `vX.Y.Z`
release that carries Mac assets is **published**, `mac-appcast.yml` copies its
`appcast.xml` and a zip onto `mac-appcast`; the `enclosure` inside the feed still points
at `releases/download/vX.Y.Z/…`, so older zips stay with their own releases. While a
release is still a draft the feed does not move — Mac users never see a half-shipped build.

The `sparkle:edSignature` on the `enclosure` in the feed is an EdDSA signature over
the zip, made with `SPARKLE_PRIVATE_KEY`. The app carries the public key
`SUPublicEDKey` and refuses to install on a bad signature — so even if the asset on
GitHub were swapped, installed apps would not install it. Check it yourself:

```bash
curl -sSL https://github.com/<owner>/<repo>/releases/download/mac-appcast/appcast.xml
# Public key: copy SUPublicEDKey from Mac/Supporting-Info.plist. Signature: copy sparkle:edSignature from the appcast enclosure.
# Uses only the system's CryptoKit — no Sparkle toolchain, no private key needed.
swift scripts/verify-sparkle-signature.swift TollCat-1.0.0-mac.zip '<sparkle:edSignature>' '<SUPublicEDKey>'
```

`sparkle:version` is `CFBundleVersion`, filled by CI with `GITHUB_RUN_NUMBER`; version
comparison uses it. The version users see is `sparkle:shortVersionString`, equal to
the tag minus its `v` (the `preflight` job enforces this).

### Parts of this chain that have not run yet

- While the repo is still private, `releases/download/…` requires a login, so
  Sparkle's anonymous fetch fails and update checks fail silently. Before the first
  Mac release the repo must go public, or `SUFeedURL` and the download prefix in
  `package-mac-release.sh` must move elsewhere.
- `mac-appcast.yml` moving the feed on publish has not run either: after the first
  publish, open `releases/download/mac-appcast/appcast.xml` and check the version.
- On the first tag a human must watch the `mac` job walk all six steps — archive →
  export (Developer ID) → notarytool → staple → sign_update → appcast — then download
  the zip on a Mac that has never had the app and run the checks above.
- After installing 1.0.0, ship a 1.0.1 and confirm "Check for Updates…" really
  installs it into /Applications and relaunches.

## 8. Windows (MSIX + appinstaller)

The counterpart of the direct-download Mac build: official packages are built only in
public GitHub Actions, from a tag. The workflow is the `windows` job of the same
[`release.yml`](.github/workflows/release.yml).

**P0 has not yet run on real Windows 11 hardware.** Until `Windows/README.md` gives
the go, this job attaches only an `.appinstaller` placeholder — no signing, no MSIX.
Below is the manual first-ship checklist.

### First-ship manual checklist

- [ ] The official Swift toolchain builds `MeterCoreCLR.dll` on Windows 11 (x64;
      record the arm64 conclusion)
- [ ] The WinUI shell P/Invokes `tollcat_catalog` / `tollcat_fetch`; ≥3 vendors fetch
      with real credentials and the month-to-date matches iOS
- [ ] Credentials go only into Credential Manager; no plaintext keys in Task Manager
      or on disk
- [ ] Tray shows 16/24px digits, light and dark sets; the flyout only reads numbers
      the main window persisted
- [ ] Launch-at-login follows the system setting; turning it off there flips the
      in-app toggle
- [ ] The code-signed MSIX installs; `.appinstaller` points at GitHub Releases latest
- [ ] Install 1.0.0, ship 1.0.1, and appinstaller auto-update really swaps the package
- [ ] `gh attestation verify TollCat.msix --repo <owner>/<repo>` passes
- [ ] The winget manifest is searchable and installable
- [ ] Full-screen walkthrough in all three languages (zh / en / ja)
- [ ] No `HttpClient` in the C# source (the commit gate already scans)
