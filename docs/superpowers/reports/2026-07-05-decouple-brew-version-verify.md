# Verification Report — decouple-brew-version

**Date:** 2026-07-05
**Change:** Switch survival-kit's nix-homebrew input to a local `git+file:` checkout; bump Homebrew to 6.0.6 inside nix-homebrew (unified version source).
**Verify mode:** light (override — 8-file count inflated by 5 openspec process artifacts; actual implementation = 2 files)

## Lightweight checks (6/6 PASS)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | tasks.md all `[x]` | PASS | `grep -c '^- \[ \]'` = 0 |
| 2 | Changed files match tasks | PASS | vs base_ref `fbfbcf0`: `nixos/flake.nix` (1 line: nix-homebrew.url → git+file) + `nixos/flake.lock` (26 lines). `home.nix` reverted to original (no net diff). |
| 3 | Build passes (config eval) | PASS | `nix eval --raw ./nixos#nixosConfigurations.AT-L-PF5S785B.config.system.build.toplevel.drvPath` → exit 0, drv produced |
| 4 | Version correct | PASS | `nix-homebrew.package.version` = `"6.0.6"`, `.name` = `"brew-6.0.6"` (fresh) |
| 5 | No security issues | PASS | `git+file:` is local-only fetch (no network, no secrets); brew-src pinned to official Homebrew/brew tag 6.0.6 with narHash; trust surface unchanged |
| 6 | Lightweight code review | PASS | Reviewer verdict: Ready to merge: Yes. No Critical. 1 Important (investigated, false positive — see below). 2 Minor (cosmetic). |

## Reviewer "Important" — investigated, FALSE POSITIVE

Reviewer claimed the top-level `brew-src` lock node + `nix-homebrew.inputs.brew-src = "brew-src"` reference is a stale follow from the reverted hoist, creating "two independent pins" (source vs version string) with latent silent drift on future `nix flake update nix-homebrew`.

**Disproved by:**
1. `root.inputs` does NOT list `brew-src` — survival-kit declares no brew-src input.
2. The top-level `brew-src` node is nix-homebrew's OWN brew-src input, hoisted to the lock's top level by standard Nix flake.lock flattening (referenced via `nix-homebrew.inputs.brew-src = "brew-src"`). This is NOT a survival-kit declaration.
3. The node's `original` = `{owner: Homebrew, ref: 6.0.6, repo: brew, type: github}` — identical to nix-homebrew's `brew-src.url`. Single source.
4. This structure is byte-identical to the base (`fbfbcf0`) default representation that existed BEFORE any of this change's edits — i.e., it is the normal, correct lock shape, not an artifact of the reverted hoist.
5. The current consistent state (source 6.0.6 + version string 6.0.6) was produced BY `nix flake update nix-homebrew` — the very operation the reviewer feared would cause drift. If it caused drift, the source would still be at the pre-bump value (6.0.1). It is 6.0.6. Therefore the update resolves both together; no silent drift is possible.

**Conclusion:** No fix required. The proposal's "revert the brew-src hoist" refers to the flake.nix INPUT DECLARATION (correctly removed); the lock's hoisted brew-src node is nix-homebrew's own input (standard flattening), not an orphan.

## Minor issues (not blocking)

1. `nix-homebrew` input URL has no explicit `?ref=`. The lock tracks `refs/heads/main` (default branch) with rev pinned in `locked`. Builds are reproducible regardless; `?ref=refs/heads/main` would make the tracked branch explicit. Cosmetic.
2. Untracked tooling dirs (`.agents/`, `.codegraph/`, `node_modules/`, etc.) in the working tree — process hygiene, out of change scope.

## Cross-repo note

This change touches TWO repos:
- `~/workspace/nix-homebrew` (commit `f08778e`): brew-src.url 6.0.1 → 6.0.6 + flake.lock. Committed in that repo.
- `~/survival-kit` (branch `decouple-brew-version`): nix-homebrew.url → `git+file:`, flake.lock updated, home.nix reverted.

## Tradeoff (accepted by user)

`git+file:///home/jian/workspace/nix-homebrew` is an absolute, machine-local path. Only buildable where `~/workspace/nix-homebrew` exists. Other hosts need the path present, or a fork push + switch to `github:luojiansh/nix-homebrew`. Missing path fails loudly at eval (`repository does not exist`), not silently.

## Verdict

**PASS.** All 6 lightweight checks pass; reviewer's Important is a false positive (verified); Minors are cosmetic. Ready for archive pending branch handling.
