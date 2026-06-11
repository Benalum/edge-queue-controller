# Route Owner Snapshot — Stage 5J-1

Generated: 2026-06-10T19:05:20-06:00

## Git
HEAD: 953c082
Tags:
controller-stage-5i-study-direct-wrapper-auth-cleanup-2026-06-10

## Wrapper map_api routes
35:GATEWAY = os.getenv("EDGE_PUBLIC_GATEWAY_URL", "http://127.0.0.1:7071")
36:CT101_FRONTEND = os.getenv("CT101_FRONTEND", "http://100.88.245.33:3010")
37:CT101_API = os.getenv("CT101_API", "http://100.88.245.33:8088")
54:def map_api(path):
60:        "/api/auth/login": "/system/session/login",
61:        "/api/auth/me": "/system/session/me",
62:        "/api/auth/register": "/system/session/register",
63:        "/api/auth/logout": "/system/session/logout-safe",
67:        "/api/auth/forgot-password": "/system/session/forgot-password",
68:        "/api/auth/reset-password": "/system/session/reset-password",
69:        "/api/auth/change-password": "/system/session/change-password",
70:        "/api/auth/verify-email": "/api/auth/verify-email",
71:        "/api/auth/resend-verification": "/api/auth/resend-verification",
77:        return CONTROLLER, controller_auth_exact[path]
84:        return CONTROLLER, path
88:    if path.startswith("/api/backend/"):
89:        return CT101_API, "/api/" + path.split("/api/backend/", 1)[1]
96:        "/api/auth/login": "/system/session/login",
97:        "/api/auth/me": "/system/session/me",
98:        "/api/auth/register": "/system/session/register",
99:        "/api/auth/logout": "/system/session/logout-safe",
126:        return CONTROLLER, controller_exact[path]
129:        return CONTROLLER, path.replace("/api/support/", "/system/support/", 1)
131:    if path.startswith("/api/system/"):
132:        return CONTROLLER, path.replace("/api/system/", "/system/", 1)
134:    if path == "/api/auth/me":
135:        return CONTROLLER, "/system/session/me"
137:    if path.startswith("/api/study/"):
138:        return CONTROLLER, path
140:    if path.startswith("/api/companion/"):
141:        return CONTROLLER, path
143:    if path.startswith("/api/calendar/"):
144:        return CONTROLLER, path
146:    return CONTROLLER, path
302:        if not auth_bridge_path.startswith("/api/backend/"):
347:        # CT101 backend requests arrive at the wrapper as /api/backend/*, then
365:            auth_source_path.startswith("/api/backend/")
366:            or auth_source_path.startswith("/api/study/")
367:            or auth_source_path.startswith("/api/companion/")
368:            or auth_source_path == "/api/auth/me"
376:            auth_source_path.startswith("/api/study/")
377:            or auth_source_path.startswith("/api/companion/")
378:            or auth_source_path.startswith("/api/calendar/")
444:    #   POST /api/backend/chats/{chat_id}/messages/queued
445:    #   GET  /api/backend/chats/{chat_id}/messages/jobs/{job_id}
495:            original_path="/api/backend/chats/_/messages/queued",
637:        create_match = re.fullmatch(r"/api/backend/chats/([^/]+)/messages/queued", path)
682:        status_match = re.fullmatch(r"/api/backend/chats/([^/]+)/messages/jobs/([^/]+)", path)
747:            return self._proxy_to_backend(CT101_FRONTEND, path, parsed.query)
764:            return self._proxy_to_backend(CT101_FRONTEND, path, parsed.query)

## Controller Study/Companion routes
6867:@app.post("/public/study/decks")
6868:@app.post("/api/study/decks")
6931:@app.get("/public/study/decks")
6932:@app.get("/api/study/decks")
6977:@app.delete("/public/study/decks/{deck_id}")
6978:@app.delete("/api/study/decks/{deck_id}")
7003:@app.post("/public/study/decks/{deck_id}/cards")
7004:@app.post("/api/study/decks/{deck_id}/cards")
7104:@app.get("/public/study/decks/{deck_id}/cards")
7105:@app.get("/api/study/decks/{deck_id}/cards")
7156:@app.delete("/public/study/cards/{card_id}")
7157:@app.delete("/api/study/cards/{card_id}")
7178:@app.post("/public/study/cards/{card_id}/reviews")
7179:@app.post("/api/study/cards/{card_id}/reviews")
7311:@app.get("/public/study/progress")
7312:@app.get("/api/study/progress")
7685:@app.get("/public/study/decks/{deck_id}/card-stats")
7686:@app.get("/api/study/decks/{deck_id}/card-stats")
7703:@app.get("/public/study/decks/{deck_id}/review-queue")
7704:@app.get("/api/study/decks/{deck_id}/review-queue")
7796:@app.post("/public/companion/study/grade")
7797:@app.post("/api/companion/study/grade")
8063:@app.get("/public/companion/context")
8064:@app.get("/api/companion/context")
8077:@app.post("/public/companion/chat")
8078:@app.post("/api/companion/chat")

## Active ports
LISTEN 0      2048          0.0.0.0:7070       0.0.0.0:*    users:(("python",pid=1622150,fd=7))
LISTEN 0      5           127.0.0.1:8787       0.0.0.0:*    users:(("python",pid=1622151,fd=3))
