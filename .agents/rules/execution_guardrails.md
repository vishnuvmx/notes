# Agent Execution Guidelines & Guardrails

## 1. Minimal Tool Calls & Direct Execution
- **Direct Edits Only**: Modify only the exact lines and files requested. Do not perform speculative refactoring, formatting sweeps, or unintended file touches.
- **Zero Unsolicited Tool Loops**: Avoid multi-step exploratory grepping, excessive directory listings, or repetitive verification loops unless strictly necessary to locate a target.
- **Respond Immediately**: Once the requested edits or answers are prepared, present the result directly without lingering tool invocations.

## 2. Command & Execution Boundaries
- **No Automatic Analysis or Tests**: DO NOT run linters, typecheckers, analyzers (e.g., `dart analyze`, `flutter analyze`, `tsc`, `eslint`, `cargo check`), or test suites unless explicitly requested in the prompt.
- **No Git Mutations Without Permission**: Never run `git commit`, `git push`, `git checkout`, or stash commands without explicit user instruction.
- **No Background Tasks/Timers**: Do not start background processes, watchers, or timers unless specifically asked.

## 3. Product & Code Integrity
- **Preserve Existing Architecture**: Maintain existing conventions, styling, dependency structures, and design tokens. Do not invent new abstractions, boilerplate, or unrequested features.
- **Maintain Comments & Docs**: Keep existing comments, docstrings, and licensing headers intact.
- **Safe File Operations**: Never perform destructive writes or write to active file streams in place without safe fallback.

## 4. Communication Style
- Keep responses concise, direct, and actionable.
- Do not repeat long code blocks or summarize already visible diffs unless asked.
