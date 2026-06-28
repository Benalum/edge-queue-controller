# Stage 17K-H — Study Source Selector UI Source Patch

Date: 2026-06-28

## Summary

Stage 17K-H adds a frontend-only Study source selector.

The selector exposes:

- Study with Anki
- Study with MyDecks

## Anki behavior

The Anki path reads the browser-local Anki deck summary already created by the Profile Anki picker.

It lets the user select an Anki deck locally.

It does not upload Anki deck names, card text, answers, tags, media, or per-card history.

It does not write to Anki.

It does not call the backend.

## MyDecks behavior

The MyDecks path is recorded as the APC-native editable source.

It remains separate from Anki permissions.

## Storage

The selector stores only the source choice in browser localStorage under:

apc.study.sourceSelection.v1

## Safety

This source patch does not deploy frontend code.

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
