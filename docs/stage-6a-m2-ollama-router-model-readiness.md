# Stage 6A-M2 Ollama Router Model Readiness

Stage 6A-M2 records the local Ollama model set prepared for the Universal Intent Router.

This stage does not change application runtime behavior.

This stage does not modify Study, Companion, Chat, Calendar, Profile, auth, queue, worker, or power automation behavior.

## Purpose

The Universal Intent Router will eventually route user inputs to different model roles.

The platform should use model roles instead of hard-coding model names throughout page handlers.

Recommended pattern:

User input goes to router.

Router resolves intent.

Router chooses a model role if needed.

Model registry maps the role to an actual Ollama model.

## Current Ollama Location

The Ollama service runs inside CT101, hostname llms.

The Proxmox host is reached over Tailscale.

The current Ollama API is exposed through the CT Tailscale-bound address:

- http://100.88.245.33:11434

Ollama was verified with:

- docker exec ollama ollama list
- curl http://100.88.245.33:11434/api/tags

## Installed Router Model Set

The following models are installed and should be treated as the initial router-ready local model set:

- qwen3:0.6b
- qwen3:1.7b
- llama3.2:3b
- gemma3:4b
- gemma4:e4b

## Recommended Model Roles

Initial role mapping:

- tiny_intent_classifier -> qwen3:0.6b
- tiny_intent_classifier_fallback -> qwen3:1.7b
- default_small_chat -> llama3.2:3b
- multilingual_companion -> gemma3:4b
- larger_local_reasoning -> gemma4:e4b

## Router Usage Rules

Direct Study actions should not use an LLM.

Phrase bank matches should not use an LLM.

Fuzzy matches should not use an LLM unless confidence is low.

Tiny models should only classify intent and return structured JSON.

Medium models should handle normal Companion and Chat conversation.

Larger local models should be reserved for harder reasoning or multilingual fallback.

## Failed Model Pull

qwen2.5-coder:7b was attempted but failed with a digest mismatch.

This is not currently blocking the router foundation.

The router does not require a coder model for Stage 6A or Stage 6B.

The coder model can be retried later or replaced with another code-focused model after the core router foundation is stable.

## Storage State

The Ollama model volume has enough space for the current router model set.

At the time of this checkpoint, model storage was approximately:

- 246G total
- 17G used
- 227G available

## Stage 6A-M2 Acceptance Criteria

Stage 6A-M2 is complete when:

- Ollama is healthy
- qwen3:0.6b is installed
- qwen3:1.7b is installed
- llama3.2:3b is installed
- gemma3:4b is installed
- gemma4:e4b remains installed
- qwen2.5-coder:7b is not required
- the router model role plan is documented
- no app runtime behavior is changed
