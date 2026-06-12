# Stage 5P-11N Retention Policy Dry-Run

Adds an admin-only retention dry-run endpoint.

Policy direction:

- Free/local users keep detailed history for 7 days.
- Paid/pro users are prepared for longer detailed history later.
- Cumulative totals can be kept longer because they do not grow continuously.
- This stage does not delete anything.

Endpoint:

- `/system/retention/dry-run`
- `/api/system/retention/dry-run`

The endpoint reports:

- free retention days
- paid retention days
- candidate tables
- total rows
- eligible rows older than the plan cutoff

Deletion will be added in a later stage only after rollups/totals are proven.
