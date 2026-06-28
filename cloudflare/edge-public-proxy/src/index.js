// APC_PHASE_14J_CD_PUBLIC_GATEWAY_ROUTE_OWNERSHIP_CONTRACT: static route ownership marker only; no runtime behavior change.
// APC_PHASE_14J_CB_STATIC_ROUTE_CONTRACT: public gateway contract marker only; no runtime behavior change.
const ALLOWED_ROUTES = [
  { method: "POST", pattern: /^\/api\/auth\/register$/ },
  { method: "GET",  pattern: /^\/api\/auth\/verify-email$/ },
  { method: "POST", pattern: /^\/api\/auth\/resend-verification$/ },
  { method: "POST", pattern: /^\/api\/auth\/login$/ },
  { method: "POST", pattern: /^\/api\/auth\/logout$/ },
  { method: "POST", pattern: /^\/api\/auth\/change-password$/ },
  { method: "POST", pattern: /^\/api\/auth\/forgot-password$/ },
  { method: "POST", pattern: /^\/api\/auth\/reset-password$/ },
  { method: "GET",  pattern: /^\/api\/me$/ },

  { method: "GET",  pattern: /^\/api\/status$/ },

  { method: "POST", pattern: /^\/api\/jobs$/ },
  { method: "GET",  pattern: /^\/api\/jobs$/ },
  { method: "GET",  pattern: /^\/api\/jobs\/[0-9]+$/ },

  { method: "POST", pattern: /^\/api\/study\/decks$/ },
  { method: "GET",  pattern: /^\/api\/study\/decks$/ },
  { method: "POST", pattern: /^\/api\/study\/decks\/[0-9]+\/cards$/ },
  { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/cards$/ },
  { method: "POST", pattern: /^\/api\/study\/cards\/[0-9]+\/reviews$/ },
  { method: "GET",  pattern: /^\/api\/study\/progress$/ },
  { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/card-stats$/ },
  { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/review-queue$/ },

  { method: "POST", pattern: /^\/api\/companion\/study\/grade$/ },
  { method: "GET",  pattern: /^\/api\/companion\/context$/ },
  { method: "POST", pattern: /^\/api\/companion\/chat$/ },

  // System status / power control routes
  { method: "GET",  pattern: /^\/api\/system\/status$/ },
  { method: "GET",  pattern: /^\/api\/ads\/reward\/status$/ },
  { method: "POST", pattern: /^\/api\/ads\/reward\/claim$/ },
  { method: "GET",  pattern: /^\/api\/system\/public-status$/ },
  { method: "GET",  pattern: /^\/api\/system\/admin-status$/ },
  { method: "GET",  pattern: /^\/api\/admin\/users$/ },
  { method: "GET",  pattern: /^\/api\/system\/admin\/users$/ },
  { method: "POST", pattern: /^\/api\/system\/pveso\/boot$/ }
];


function withQuery(path, url) {
  return url.search ? `${path}${url.search}` : path;
}

async function proxyJson(request, env, targetPath) {
  const upstream = new URL(targetPath, env.EDGE_API_BASE_URL);

  const headers = new Headers(request.headers);
  headers.set("Accept", "application/json");

  const init = {
    method: request.method,
    headers,
    redirect: "manual",
  };

  if (!["GET", "HEAD"].includes(request.method)) {
    init.body = await request.text();
  }

  const response = await fetch(upstream.toString(), init);

  const outHeaders = new Headers(response.headers);
  outHeaders.set("Access-Control-Allow-Origin", "*");
  outHeaders.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Edge-Api-Key");
  outHeaders.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");

  return new Response(response.body, {
    status: response.status,
    headers: outHeaders,
  });
}


function corsHeaders(origin) {
  return {
    "Access-Control-Allow-Origin": origin || "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Max-Age": "86400"
  };
}

function isAllowed(method, path) {
  return ALLOWED_ROUTES.some((route) => {
    return route.method === method.toUpperCase() && route.pattern.test(path);
  });
}

/**
 * Stage 1: Route Ownership and Mapping
 *
 * This function maps public API routes (/api/*) to controller backend routes.
 *
 * OWNERSHIP MODEL:
 * - Controller-owned public routes are translated to /public/* and /system/* on the edge controller.
 * - CT101 remains the source of truth for study/companion/calendar private APIs and backend job execution.
 * - Study/companion routes are proxied as /public/study/* and /public/companion/* for public gateway compatibility.
 * - These public gateway routes are legacy bridges and must not become the authoritative data owner.
 * - Do not add direct model routes here; model execution is CT101-owned backend logic.
 *
 * ROUTE MAPPING:
 * - /api/auth/* -> controller /public/auth/* (controller-owned account authentication)
 * - /api/jobs -> controller /public/jobs (public job bridge only; CT101 owns durable backend job execution)
 * - /api/study/* -> /public/study/* (public bridge; CT101 is source-of-truth)
 * - /api/companion/* -> /public/companion/* (public bridge; CT101 is source-of-truth)
 * - /api/ads/* -> /system/ads/* (controller-owned rewarded ads)
 * - /api/system/* -> /system/* (controller-owned system status and power)
 */
function mapApiPathToBackend(path) {
  // Controller account authentication routes
  if (path === "/api/status") return "/public/status";
  if (path === "/api/me") return "/public/me";

  // Controller-owned auth: /api/auth/* -> /public/auth/*
  if (path.startsWith("/api/auth/")) {
    return path.replace("/api/auth/", "/public/auth/");
  }

  // Controller public job bridge: /api/jobs -> /public/jobs
  // (CT101 owns the durable backend job execution and scheduler)
  if (path === "/api/jobs") return "/public/jobs";
  if (/^\/api\/jobs\/[0-9]+$/.test(path)) {
    return path.replace("/api/jobs/", "/public/jobs/");
  }

  // CT101-owned study API, proxied as public bridge: /api/study/* -> /public/study/*
  // (CT101 is the source-of-truth for study data)
  if (path.startsWith("/api/study/")) {
    return path.replace("/api/study/", "/public/study/");
  }

  // CT101-owned companion API, proxied as public bridge: /api/companion/* -> /public/companion/*
  // (CT101 is the source-of-truth for companion data)
  if (path.startsWith("/api/companion/")) {
    return path.replace("/api/companion/", "/public/companion/");
  }

  // Controller-owned rewarded ads: /api/ads/* -> /system/ads/*
  if (path.startsWith("/api/ads/")) {
    return path.replace("/api/ads/", "/system/ads/");
  }

  // Controller-owned admin users: route is protected by backend admin auth.
  if (path === "/api/admin/users") return "/system/admin/users";

  // Controller-owned system status and power: /api/system/* -> /system/*
  if (path.startsWith("/api/system/")) {
    return path.replace("/api/system/", "/system/");
  }

  return null;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin") || "*";

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(origin)
      });
    }

    if (url.pathname === "/api/auth/verify-email" && request.method === "GET") {
      return proxyJson(request, env, withQuery("/api/auth/verify-email", url));
    }

    if (url.pathname === "/api/auth/resend-verification" && request.method === "POST") {
      return proxyJson(request, env, "/api/auth/resend-verification");
    }



    if (!isAllowed(request.method, url.pathname)) {
      return Response.json(
        { ok: false, detail: "Not found." },
        { status: 404, headers: corsHeaders(origin) }
      );
    }

    const backendPath = mapApiPathToBackend(url.pathname);
    if (!backendPath) {
      return Response.json(
        { ok: false, detail: "Not found." },
        { status: 404, headers: corsHeaders(origin) }
      );
    }

    if (!env.EDGE_PUBLIC_API_KEY) {
      return Response.json(
        { ok: false, detail: "Worker secret EDGE_PUBLIC_API_KEY is missing." },
        { status: 500, headers: corsHeaders(origin) }
      );
    }

    const backendUrl = new URL(env.EDGE_API_BASE_URL + backendPath);
    backendUrl.search = url.search;

    const headers = new Headers();
    headers.set("X-Edge-Api-Key", env.EDGE_PUBLIC_API_KEY);

    const contentType = request.headers.get("Content-Type");
    if (contentType) headers.set("Content-Type", contentType);

    const authorization = request.headers.get("Authorization");
    if (authorization) headers.set("Authorization", authorization);

    const init = {
      method: request.method,
      headers
    };

    if (!["GET", "HEAD"].includes(request.method.toUpperCase())) {
      init.body = await request.arrayBuffer();
    }

    const upstream = await fetch(backendUrl.toString(), init);

    const responseHeaders = new Headers(corsHeaders(origin));
    const upstreamType = upstream.headers.get("Content-Type");
    if (upstreamType) responseHeaders.set("Content-Type", upstreamType);

    return new Response(upstream.body, {
      status: upstream.status,
      headers: responseHeaders
    });
  }
};
