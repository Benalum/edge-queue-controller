# ChatGPT Terminal Bridge Workflow

This project can use the local ChatGPT terminal bridge for safe, phased work.

## Normal phase loop

1. Start the bridge session.

   cgpt-workflow start

2. Create a focused branch.

   cgpt-workflow branch "short phase objective"

3. Generate a prompt and upload bundle.

   cgpt-workflow prompt "specific task for ChatGPT"

4. Upload the newest ZIP from `chatgpt-bundles/` to ChatGPT.

5. Copy ChatGPT's response and apply fenced bash blocks.

   cgpt-apply

6. Type `RUN` only when `cgpt-apply` asks for confirmation.

7. Capture terminal output.

   cgpt-output

8. Paste the copied output back into ChatGPT.

9. Validate and commit.

   cgpt-workflow tests
   cgpt-workflow finish "commit message"

## File-based fallback

If clipboard content is confusing, save commands to a file and run:

   cgpt-apply --file /tmp/some-commands.sh

Then type `RUN` when prompted.

## Safety rules

- Do not type `RUN` directly into the terminal.
- Do not run placeholder paths like `/tmp/some-commands.sh` unless the file exists.
- Review the preview shown by `cgpt-apply` before typing `RUN`.
- Keep phases small and validate before merging.
