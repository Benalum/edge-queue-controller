# Stage 5P-11D Study Stopped-State Button Repair

Fixes Study controls after pressing Stop.

Problem:

- After Stop, the Study controls could become unusable.
- Start should remain available after stopped/completed/no-session states.

Behavior after this stage:

- Start enabled for none/stopped/completed/error/offline/unknown.
- Refresh enabled unless a command is actively in progress.
- Pause enabled only for active/reviewing_answer/waiting_for_mark.
- Resume enabled only for paused.
- Stop enabled for active/reviewing_answer/waiting_for_mark/paused.

No backend changes.
No Companion debug tools.
No voice changes.
