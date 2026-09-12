# App Review Notes（提交时贴进 App Review Information → Notes）

英文原文如下。方括号里的两处**提交前必须替换**：
一把真实的只读测试密钥，和你的联系邮箱。

---

TollCat has no account system and no sign-in. It shows the user's own
cloud/AI spending: the user pastes a READ-ONLY API key for each service
they use, and the app fetches billing data directly from that vendor's
official API. Credentials are stored only in the device Keychain and are
never sent to us — the app has no server that ever sees them.

HOW TO TEST WITH DATA

Option A (no external account needed): open the "Services" tab → "Add"
→ choose "Manual subscription" and enter any name and monthly price.
The dashboard and widgets will show that spending immediately.

Option B (real API data): use this read-only test credential —
  Service: Cloudflare
  API token: [REPLACE-WITH-THROWAWAY-READ-ONLY-TOKEN]
In the app: Services tab → Add → Cloudflare → paste the token.
The token is read-only and created for this review; it can see billing
amounts only and cannot modify anything.

OTHER NOTES

- Tips: the "tip jar" in Settings uses standard StoreKit consumable
  in-app purchases (3 tiers). There are no external purchase links.
- Network: the only first-party endpoint is api.tollcat.app, used for
  the public setup catalog, optional in-app feedback, optional tip
  notes, and the "reading inbox" (an email-forwarding address for
  services that have no billing API). Provider credentials are never
  sent to it. All other traffic goes directly to the official APIs of
  services the user connects (e.g. api.cloudflare.com).
- Widgets: Lock Screen and Home Screen widgets show the same
  month-to-date total as the dashboard.
- Source: the repository is private for now, so we have not linked it. We can
  provide any part of the source through this thread on request.

CHINA MAINLAND — NO DEEP SYNTHESIS / GENERATIVE AI SERVICE

This app does not provide deep synthesis or generative AI services. It
does not call any model inference, chat, completion, image, audio or
embedding endpoint of any vendor. For every AI vendor in the catalog it
calls only that vendor's billing/usage endpoint (for OpenAI, for example,
only GET https://api.openai.com/v1/organization/costs), which returns
amounts of money for the user's own account. No prompt is ever sent, no
content is ever generated, and the app has no chat interface or prompt
input of any kind. All references to OpenAI, ChatGPT, Anthropic and
Claude have been removed from every metadata field and every
localization (app name, subtitle, keywords, promotional text,
description, screenshots).

Contact: [REPLACE-WITH-YOUR-EMAIL]
