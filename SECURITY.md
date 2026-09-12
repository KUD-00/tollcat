# Security policy

## Reporting a vulnerability

Please do not open a public issue for security problems.

Use GitHub's private vulnerability reporting instead:
<https://github.com/KUD-00/tollcat/security/advisories/new>. It reaches the
maintainer directly and stays private until a fix is out.

You can expect an acknowledgement within a few days. Once the report is
confirmed, a fix goes out in the next release and the advisory is published
with credit to the reporter, unless you prefer to stay anonymous.

## Scope

- The apps (iOS, macOS, Android, Windows) and the shared `MeterKit` packages
- The `worker/` edge API behind `api.tollcat.app`
- The `site/` code for `tollcat.app`

Third-party billing providers' own APIs are out of scope; problems there
belong to the respective vendor.

## Supported versions

Only the latest release of each app receives security fixes.

## What the app does with your credentials

Provider credentials never leave the device except to call that provider's
own billing endpoint over HTTPS. The list of hosts the app may contact is
enforced at build time (`scripts/check-outbound-hosts.sh`). Reports about any
path that violates this are especially welcome.
