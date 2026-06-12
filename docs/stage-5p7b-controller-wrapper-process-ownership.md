# Stage 5P-7B Controller / Wrapper Process Ownership

## Purpose

Document and smoke-test the local development process ownership model.

Current dev ownership:

- 7070 is the controller API port.
- 8787 is the wrapper dev server port.
- The controller is restarted with ops/dev/restart-controller-7070.sh.
- The wrapper dev server is currently a separate long-running Python process.
- No user systemd service or timer currently owns controller/wrapper startup.

## Why keep port 7070

The project already expects the controller on 7070 through wrapper proxy paths, queue workers, smoke tests, and local development commands.

The issue was not the port number. The issue was duplicate manual controller starts trying to bind the same port.

## Rule going forward

Do not use ad-hoc nohup uvicorn restart blocks in future stages.

Use this helper instead:

bash ops/dev/restart-controller-7070.sh

## Future production owner

Later, once development stabilizes, controller/wrapper should move to a clean systemd user service or system service so the site recovers after reboot.

Until then, the dev helper is the canonical controller owner.
