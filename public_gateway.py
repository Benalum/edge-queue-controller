import os
import re

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import Response, JSONResponse


BACKEND_BASE_URL = os.getenv("EDGE_PUBLIC_GATEWAY_BACKEND", "http://127.0.0.1:7070").rstrip("/")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("EDGE_PUBLIC_GATEWAY_TIMEOUT_SECONDS", "300"))

app = FastAPI(title="Edge Queue Public Gateway")


def is_allowed_public_route(method: str, path: str) -> bool:
    method = method.upper()

    if method == "GET" and path == "/public/status":
        return True

    if method == "POST" and path == "/public/jobs":
        return True

    if method == "GET" and path == "/public/jobs":
        return True

    if method == "GET" and re.fullmatch(r"/public/jobs/[0-9]+", path):
        return True

    if method == "POST" and path in {"/public/auth/register", "/public/auth/login", "/public/auth/logout"}:
        return True

    if method == "GET" and path == "/public/me":
        return True

    return False


@app.get("/gateway/health")
async def gateway_health():
    return {
        "ok": True,
        "gateway": "edge-queue-public-gateway",
        "backend": BACKEND_BASE_URL,
    }


@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
async def gateway_proxy(path: str, request: Request):
    request_path = "/" + path

    if not is_allowed_public_route(request.method, request_path):
        return JSONResponse(
            status_code=404,
            content={
                "ok": False,
                "detail": "Not found.",
            },
        )

    query = request.url.query
    target_url = f"{BACKEND_BASE_URL}{request_path}"
    if query:
        target_url += f"?{query}"

    body = await request.body()

    forwarded_headers = {}

    for header_name in [
        "content-type",
        "accept",
        "x-edge-api-key",
        "authorization",
    ]:
        value = request.headers.get(header_name)
        if value:
            forwarded_headers[header_name] = value

    async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT_SECONDS) as client:
        upstream = await client.request(
            method=request.method,
            url=target_url,
            headers=forwarded_headers,
            content=body,
        )

    response_headers = {}
    content_type = upstream.headers.get("content-type")
    if content_type:
        response_headers["content-type"] = content_type

    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        headers=response_headers,
    )
