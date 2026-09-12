const SITE_ORIGINS = new Set(["https://tollcat.app", "https://www.tollcat.app"]);

function allowedOrigin(request: Request): string | null {
  const origin = request.headers.get("origin");
  if (!origin || !SITE_ORIGINS.has(origin)) return null;
  return origin;
}

/// 只给落地页的反馈表单用。App 没有 Origin，走原样响应。
/// 不要把这组头挂到 tip / inbox / readings 上。
export function feedbackPreflight(request: Request): Response {
  const origin = allowedOrigin(request);
  if (!origin) return new Response(null, { status: 403 });
  return new Response(null, {
    status: 204,
    headers: {
      "access-control-allow-origin": origin,
      "access-control-allow-methods": "POST, OPTIONS",
      "access-control-allow-headers": "content-type",
      "access-control-max-age": "86400",
      vary: "Origin",
    },
  });
}

export function withFeedbackCors(request: Request, response: Response): Response {
  const origin = allowedOrigin(request);
  if (!origin) return response;
  const headers = new Headers(response.headers);
  headers.set("access-control-allow-origin", origin);
  headers.set("vary", "Origin");
  return new Response(response.body, { status: response.status, headers });
}
