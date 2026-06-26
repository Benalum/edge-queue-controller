# Stage 16 FC-O45-E-CH-E-R2 — Backend Companion Study Action Live Deploy

Date: 2026-06-26

## Summary

CH-E-R2 deployed the backend-only Companion Study action endpoint to CT203 and restarted only the controller service.

No frontend work occurred.

## Live backend deploy

Active CT203 backend file:

    /opt/edge-queue-controller/current/edge_controller.py

Before SHA:

    008b11765b7e677e13b1053afcf48046b0d411c03080128d7920b32542887088

After SHA:

    8b6c0681f16e2d26f49c4a555b60e703aafbda63a1ed05c439f3ecdbdcab3e9f

Backup path:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-ch-e-r2-backend-companion-study-action-deploy-20260626T032955Z

## Service impact

Only this service was restarted:

    edge-queue-controller.service

The controller was active after restart and running on port 7070.

## Live route confirmation

OpenAPI contained:

    /api/companion/study/action
    /public/companion/study/action

## Non-mutating smoke

A localhost smoke against:

    POST http://127.0.0.1:7070/api/companion/study/action

with payload:

    {"action":"make_flashcards","message":"Question one => Answer one"}

returned a successful non-mutating response:

    ok=true
    feature=companion_study_action
    stage=stage16-fc-o45-e-ch-c
    action=make_flashcards
    mutated=false
    message=Flashcard candidates created. Use add_card to save selected cards.
    front=Question one
    back=Answer one
    save_action=add_card

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no DB write, no job mutation, no result insert, no model/helper/Ollama call, no worker/timer activation, and no CT/VM restart occurred.
