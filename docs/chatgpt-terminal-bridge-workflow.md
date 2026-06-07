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


## Exact operator checklist

Use this exact order when working with ChatGPT Web:

1. Start a phase and create the upload bundle.

   cgpt-workflow phase "specific objective"

2. Upload the newest ZIP from `chatgpt-bundles/` to ChatGPT.

3. Wait for ChatGPT to reply with commands.

4. Copy ChatGPT's whole response.

5. Run `cgpt-apply` only after copying ChatGPT's response.

   cgpt-apply

6. If `cgpt-apply` previews the expected commands, type `RUN`.

7. If `cgpt-apply` says no fenced bash blocks were found, do not type `RUN`. Either copy the correct ChatGPT response or use file mode.

8. After the tmux command finishes, capture output.

   cgpt-output

9. Paste the copied output back into ChatGPT.

### File mode

Use file mode when clipboard contents are confusing:

   cgpt-apply --file /tmp/some-real-command-file.sh

Only use a file path that actually exists. `/tmp/some-commands.sh` is an example placeholder, not a command file unless you created it first.

### Common mistakes

- Do not run `cgpt-apply` immediately after `cgpt-workflow phase`; first upload the ZIP and copy ChatGPT's response.
- Do not type `RUN` directly into your terminal. Type it only inside the `cgpt-apply` prompt.
- Do not type `cgpt-output` inside the `cgpt-apply` prompt. Run `cgpt-output` only after commands have finished in tmux.

## File-based fallback

If clipboard content is confusing, save commands to a file and run:

   cgpt-apply --file /tmp/some-commands.sh

Then type `RUN` when prompted.

## Safety rules

- Do not type `RUN` directly into the terminal.
- Do not run placeholder paths like `/tmp/some-commands.sh` unless the file exists.
- Review the preview shown by `cgpt-apply` before typing `RUN`.
- Keep phases small and validate before merging.
