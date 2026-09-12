import { methodNotAllowed } from "./http";
import catalog from "./catalog.json";

/// 公开目录。只有文字和数字，没有 URL、没有凭据。
///
/// `catalog.json` 是 App 打包那份的符号链接。部署 Worker = 把同一份
/// 说明和汇率推给已装机的 App。
export function handleCatalog(request: Request): Response {
  if (request.method !== "GET") {
    return methodNotAllowed("GET");
  }
  return new Response(JSON.stringify(catalog), {
    status: 200,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "public, max-age=3600",
    },
  });
}
