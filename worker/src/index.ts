import { handleTip } from "./tip";
import { handleInbox } from "./inbox";
import { handleFeedback } from "./feedback";
import { handleCatalog } from "./catalog";
import { handleUsage } from "./usage";
import { feedbackPreflight, withFeedbackCors } from "./cors";
import { json } from "./http";

/// `Env`（含 DB binding）由 `wrangler types` 从 wrangler.toml 生成，
/// 见 worker-configuration.d.ts。binding 名写错在编译期就会红。
///
/// 路由表。加 endpoint 加在这里，不要为一个新功能再部署一个 Worker。
///
///   POST   /v1/tip                     打赏留言（不含账单凭据或账单数据）
///   POST   /v1/inbox                   建信箱，返回 read key + 第一把 ingest key
///   DELETE /v1/inbox                   删信箱及其全部读数与 key    [read key]
///   GET    /v1/inbox/ingest-keys       列出投递 key 的元数据       [read key]
///   POST   /v1/inbox/ingest-keys       签一把新的，不吊销旧的       [read key]
///   DELETE /v1/inbox/ingest-keys/:id   吊销指定一把               [read key]
///   POST   /v1/readings                投递一条读数（覆盖写）      [ingest key]
///   GET    /v1/readings                取回全部最新读数           [read key]
///   POST   /v1/feedback                用户反馈（不含账单数据）
///          OPTIONS /v1/feedback        只给 tollcat.app 落地页 CORS 预检
///   POST   /v1/usage                   匿名页面计数（不含标识、不含账单）
///   GET    /v1/catalog                 接入说明、套餐、公告、汇率（公开 JSON）
const INBOX_PREFIX = "/v1/inbox";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/v1/tip") {
      return handleTip(request, env.DB);
    }
    if (url.pathname === "/v1/feedback") {
      if (request.method === "OPTIONS") return feedbackPreflight(request);
      return withFeedbackCors(request, await handleFeedback(request, env.DB));
    }
    if (url.pathname === "/v1/catalog") {
      return handleCatalog(request);
    }
    if (url.pathname === "/v1/usage") {
      return handleUsage(request, env.DB);
    }
    if (url.pathname === INBOX_PREFIX || url.pathname.startsWith(`${INBOX_PREFIX}/`) ||
        url.pathname === "/v1/readings") {
      return handleInbox(request, env.DB);
    }
    return json({ error: "not found" }, 404);
  },
};
