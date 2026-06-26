# Stage 16 FC-O45-E-CJ-E — Backend Companion Prompt Wrapper Contract

Date: 2026-06-26

## Scope

Backend source/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No DB write. No schema migration. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No service change. No CT/VM restart.

## Why this exists

CJ-C-R2 proved the backend mechanics can complete Companion job 573 with qwen2.5:0.5b.

It also proved semantic exactness was not reliable. The prompt asked for:

    FC-O45-E-CF-R2-BROWSER-OK

but qwen2.5 returned a rambly/truncated response instead of exactly the requested marker.

## Added helper contract

CI-E adds source-only prompt wrapper helpers:

- _stage16_cj_e_extract_exact_answer_marker
- _stage16_cj_e_build_exact_answer_prompt
- _stage16_cj_e_classify_companion_model_prompt
- _stage16_cj_e_companion_prompt_wrapper_contract

## Prompt classes

Supported classes:

- exact_answer
- study_companion
- general_companion

## Exact-answer rule

If a prompt contains explicit exact-answer language such as:

    Please answer exactly: MARKER

then the wrapper extracts the marker and builds a strict exact-output prompt.

The wrapped exact-answer prompt instructs the model:

- return exactly and only the requested marker
- do not add explanations
- do not add bullets
- do not add markdown
- do not add quotes
- do not add prefixes or suffixes

## Study Companion rule

Study prompts are wrapped with Study-aware boundaries:

- flashcard requests produce front/back candidates
- review help should be clear and brief
- the model must not claim Study state changed unless a backend Study action already performed that change

## General Companion rule

General prompts are wrapped for brief direct answers and must not claim tool, Study, calendar, voice, or system actions happened unless the backend already performed them.

## Runtime note

This is source-only. It does not enable a worker, scheduler, timer, model call, or persistent process.
