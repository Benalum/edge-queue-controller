# Phase 11J Study Answer Judge Router Source Inspection

Phase 11J inspects the current Companion Study answer-checking source before changing runtime behavior.

## Goal

Find the current deterministic Study answer comparison path and document the source location that currently produces the uncertain answer response.

This phase intentionally does not change runtime code.

## Runtime source found

Runtime file:

- `frontend/wrapper-ui/app.js`

Relevant functions:

- `stage5p11jNormalizeAnswer`
- `stage5p11jCompactAnswer`
- `stage5p11jParseNumericAnswer`
- `stage5p11jCompareAnswer`
- `stage5p11jRouteCompanionStudyAnswer`

The Study answer route calls:

- `stage5p11jCompareAnswer(message, expectedAnswer)`

The current uncertain response includes:

- `I am not certain whether that matches the answer`
- `Expected answer`

## Product issue confirmed

The current answer checker is too literal for natural number-word answers.

Example:

- Question: `2 + 3`
- Expected answer: `5`
- User answer: `five`
- Current behavior: uncertain
- Desired future behavior: accept `five` as `5` deterministically without model fallback

## Phase 11J smoke behavior

The smoke is intentionally narrow and authoritative:

- It searches the current runtime file only: `frontend/wrapper-ui/app.js`
- It ignores `.cleanup-archive`
- It passes only when the exact Study answer checker markers are present
- It confirms only docs/smoke files are changed
- It confirms router rollout remains parked
- It does not require or perform any service restart

## Next phase

Phase 11K should implement the deterministic answer normalizer in `frontend/wrapper-ui/app.js`.

Planned behavior:

1. Normalize case, punctuation, and whitespace.
2. Convert simple number words such as `five` to `5`.
3. Support simple multi-word numbers such as `twenty one` to `21`.
4. Compare numeric values deterministically before using any model.
5. Leave tiny-model fallback for a later phase only when deterministic rules are uncertain.
