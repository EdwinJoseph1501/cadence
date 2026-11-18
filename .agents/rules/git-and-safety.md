---
description: Protect Git history, prohibit automatic publication, prevent destructive operations, and isolate Rivet.
trigger: always_on
---

# Rule: Git Hygiene & Repository Safety

1. **Inspect Before Action**: Always run `git status` and inspect changed files prior to performing any filesystem or package modifications.
2. **No Automatic Commits or Pushes**:
   - Never run `git commit`, `git push`, or `git tag` automatically.
   - The developer retains exclusive authority to review diffs and commit changes to version control.
3. **No Destructive Operations**:
   - Strictly forbidden: `git reset --hard`, `git clean -f`, `git clean -fd`, `git restore .`, `git checkout -- .`, `git branch -D`, `git rebase`.
   - Never discard uncommitted work without explicit confirmation.
4. **Strict Isolation of Rivet**:
   - The sibling directory `~/Dev/projects/rivet` must never be inspected, modified, or targeted by any command.
   - Operations must remain strictly within `/Users/edwin/Dev/projects/cadence`.
5. **Clean Working Tree**: Ensure temporary files, build caches (`.build/`, `build/`), and OS artifacts (`.DS_Store`) are properly ignored by `.gitignore` and never staged.
