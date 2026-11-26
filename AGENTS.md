# ArborMed

## Code navigation with Graphify

- For cross-file exploration, start with one focused command from the repository root, e.g. `graphify query "QuizController submitAnswer"`. Use `graphify path` for a specific connection. The default query budget is 800 tokens and depth is 1. Widen the query only when needed.
- Read the relevant source and tests before changing behavior. Treat graph links as navigation hints. Direct file reads and narrow searches are appropriate for known files, missing symbols, and excluded files.
- Build or refresh the local index when it is missing or relevant source has changed. In PowerShell, run `$env:GRAPHIFY_BACKEND = 'none'; graphify update .` from the repository root. The generated files are in `graphify-out/`. Use the local extractor with semantic LLM processing disabled.
