# Phase 14J-IF - PVEW candidate build preflight, no apply

Date: 2026-06-17

Scope: docs/smoke only. No CT creation, storage mutation, key generation, data copy, service activation, route mutation, PVESO shutdown, or authority migration.

Base checkpoint: Phase 14J-IE, commit 0e664e0.

## Purpose

Define the preflight requirements before any future real-mutation boundary creates PVEW private candidates.

## Proposed future candidates

- CT203 `edge-controller-pvew`: private controller candidate.
- CT204 `edge-data-pvew`: private encrypted data/backups candidate.

## Required before real mutation

Before any build command is provided, verify:

1. repo is clean at latest checkpoint;
2. PVEW is reachable;
3. VM200 website-edge remains running and isolated;
4. CT203 and CT204 IDs are unused;
5. storage pool and encrypted volume plan are selected;
6. key handling and manual unlock procedure are defined;
7. backup and restore rehearsal plan is defined;
8. public routes remain unchanged;
9. laptop controller remains live authority;
10. explicit real-mutation approval is granted.

## Hard blocks

Do not create CTs, create storage, generate keys, copy data, start services, enable services, stop PVESO, or alter routes in no-apply phases.
