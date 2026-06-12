# Stage 5P-10H Companion Queue Display Polish

Polishes the simplified Companion queue display.

Before:

- complete
- running
- failed/error/cancelled raw status text

After:

- Done
- Running
- Failed
- Cancelled

Queued jobs still display as:

- position / total

No backend behavior changes.
No worker behavior changes.
No queue endpoint changes.
