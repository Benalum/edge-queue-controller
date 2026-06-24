# Stage 16 FC-O44-D-R14 public Study signed-out view and banner copy

Date: 2026-06-24

## Purpose

Record the public frontend patch that hides signed-out Study internals and shortens the public banner copy.

Public banner copy is now:

    Under Construction: Some features do not work yet.

## Mutation boundary

This checkpoint performs public smoke plus repo docs/smoke/commit/tag/push only.

No live deploy, service restart, CT/VM restart, nginx/cloudflared mutation, DB write, job mutation, worker/model/runtime mutation, model call, or reset-failed was performed in R14.

## Prior live patch evidence

R12B successfully patched VM200 public static authority:

    app_target=/var/www/apc-wrapper-local/app.js
    index_target=/var/www/apc-wrapper-local/index.html
    old_vm_app_sha=315ed80a5d8eef5c1390294c41b8d671c686fca7c47ef669974e602c6de1d454
    new_vm_app_sha=bbde8974c2baa531bc198687e2608dcd5588fa77a8fbfd885b9da2c690f48525
    old_vm_index_sha=93a140b7779da28b1ada42feb5555189f8b4224cceeb026bd0b24f049343d8b2
    new_vm_index_sha=892ea5a3f5f14aa3f819026d64542c080dd459d728a5da5f8cf1a34e7efb050a
    app_backup=/var/www/apc-wrapper-local/app.js.stage16-fc-o44-d-r12b-pre-public-study-banner.20260624T024708Z.bak
    index_backup=/var/www/apc-wrapper-local/index.html.stage16-fc-o44-d-r12b-pre-public-study-banner.20260624T024708Z.bak

R13 confirmed VM200 local state:

    nginx_active=active
    cloudflared_active=active
    app.js has_guard=true
    index.html has_new_banner=true
    index.html has_old_banner=false
    index.html has_cache_bust=true

## Repo frontend evidence

    wrapper_app_sha=0caf5bb751ef41cec4c2fa85bbc4306c18e5241ae034e55c7c9d863f7b11ea62
    wrapper_index_sha=b9c12b1971bc53088813077f471a6d6440e0ad0b7c966053081d4cc16f2bb54f
    study_index_sha=0be06ac5c7d8307ded1d136afca0b0f6f3a40a995450325b3b885831ebb61839
    guard_marker=APC_PUBLIC_STUDY_SIGNED_OUT_GUARD_FC_O44_D
    cache_bust=20260624fc044d

## Public smoke evidence

    --- public_smoke_attempt=1 ---
    public_http_code=200 url=https://alexhartel.com/?fc_o44_d_r14=1_1782269587
    public_root_pass=true
    public_root_sha=8313cb8bcb2c9df70800dcb51a997532f2ee7272a8ab659c93efb18e7aaf2b01
    public_http_code=200 url=https://alexhartel.com/app.js?fc_o44_d_r14=1_1782269588
    public_app_pass=true
    public_app_sha=bbde8974c2baa531bc198687e2608dcd5588fa77a8fbfd885b9da2c690f48525
    public_http_code=200 url=https://alexhartel.com/app.js?v=20260624fc044d&fc_o44_d_r14=1_1782269588
    public_app_pass=true
    public_app_sha=bbde8974c2baa531bc198687e2608dcd5588fa77a8fbfd885b9da2c690f48525
    public_http_code=200 url=https://alexhartel.com/api/system/status?fc_o44_d_r14=1_1782269589
    public_api_pass=true

## Decision

FC-O44-D-R14 records the public-safe signed-out Study behavior and shortened banner copy.

Next recommended stage: browser-rendered signed-out Study smoke to verify the hidden Study session/deck controls are not visible after JavaScript execution.
