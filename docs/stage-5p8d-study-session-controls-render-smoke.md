# Stage 5P-8D Study Session Controls Browser Render Smoke

Adds a test-only render smoke for the Stage 5P-8C Study session controls.

The smoke verifies:

- wrapper app syntax
- Stage 5P-8A status card markers
- Stage 5P-8C control button markers
- live app.js and styles.css assets contain Stage 5P-8C markers
- wrapper routes still load
- optional Playwright render check when available

This stage does not change runtime behavior.
