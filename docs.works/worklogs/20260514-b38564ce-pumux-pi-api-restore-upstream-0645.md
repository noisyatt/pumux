---
date: 2026-05-14
project: pumux
doc_type: worklog
handoff: b38564ce-c239-4b64-80f8-d9b2261fcdde
alias: pumux-pi-api-restore-upstream-0645
title: pumux Pi session registry restore + MOSH TMUX + upstream v0.64.5
---

## Outcome

- Implemented and pushed pumux support for explicit MOSH TMUX menu attach/restore and Pi session registry resume metadata.
- Merged upstream cmux stable `v0.64.5` into pumux main, preserved pumux-specific code, built, installed `/Applications/pumux.app`, and pushed `origin/main`.
- Created Pi API design proposal at `docs.works/design/20260512-pi-session-context-api-for-pumux.md`; Pi side later exposed registry CLI/files, and pumux now consumes `~/.pi/agent/session-registry.json`.

## Subagent ledger

- `0cdc83f5-2827-43c0-bc13-5b76154ebdc7` / worker: isolated worktree upstream stable check.
  - Artifact: `/Users/daniel/projects/pumux/docs.works/tmp/subagent-upstream-stable-check.md`
  - Session: `/Users/daniel/.pi/agent/sessions/--Users-daniel-projects-pumux--/2026-05-14T01-25-18-980Z_019e2416-9003-720c-8e9b-71de2660dc38.jsonl`
  - Verdict: upstream `v0.64.5` clean-merged in worktree; pumux code preserved; tagged build succeeded with skip flag in worker, then parent build later succeeded without skip.

## Work performed

- Split menu bar `tmux` into localized `TMUX` and `MOSH TMUX` menus.
- Added MOSH TMUX refresh state, startup refresh, disabled loading UX, 5-attempt remote fetch, zsh function discovery via `whence -f`/`functions`, and `mtl`-compatible `ssh <host> 'tmux ls 2>/dev/null'` parsing.
- Added `newMoshTmuxTab`, `newManagedMoshTmuxSurface`, and canonical remote attach command persistence: `mosh '<host>' -- tmux new-session -A -s '<session>'`.
- Verified actual `mtl` output for host `mac`: `Dotozip-arc`, `Dotozip-ocr`, `Pi-Chromium`, `Pi-DEV`.
- Built and installed `/Applications/pumux.app` multiple times during dogfood.
- Confirmed Pi API after Pi restart:
  - `pi session paths --json`
  - `pi session list --cwd /Users/daniel/projects/pumux --limit 10 --json`
  - `pi session inspect --pid 73395 --json`
  - `pi session inspect --tmux-pane %5 --json`
- Added pumux-side Pi registry integration:
  - process-level registry detection in `Sources/VaultAgentProcessScanner.swift`
  - tmux session name matching in `Sources/Workspace.swift` so `tmux: Pi-Pumux` stores both `tmuxStartCommand` and `kind: pi` agent metadata.
- Verified autosave snapshot contained `kind: "pi"`, session id `019e1b9f-3e22-722b-9075-b7715758ed23`, and tmux start command for `Pi-Pumux`.
- Committed/pushed implementation: `6d4c55b73 Restore Pi sessions from registry in pumux`.
- Accepted upstream update, merged `v0.64.5`, ran `git submodule update --init --recursive`, built, installed, and pushed merge commit `f168daa1e Merge upstream cmux v0.64.5 into pumux`.

## Instruction / memory updates

- No `AGENTS.md`, `CLAUDE.md`, or `memory/` files were intentionally changed.
- Added durable design note: `docs.works/design/20260512-pi-session-context-api-for-pumux.md`.
- Existing handoff/worklog formatting changes from the earlier `f7fde755` handoff remain local and are being committed with this handoff set.

## User feedback / decisions

- User explicitly wanted `/Applications/pumux.app` replaced after builds, not only a DerivedData app link.
- User rejected a title-only restore approach for `mtl`; actual `mtl` list output should drive MOSH TMUX menu/session attachment.
- User clarified reboot restore means recreating equivalent processes, e.g. `pi --session <id>`, not preserving live processes.
- User preferred Pi to own session metadata API/registry and pumux to consume/stash stable restore metadata.
- User accepted upstream `v0.64.5` merge after subagent isolated check.

## Validation

- `./scripts/reload.sh --tag mosh-tmux-menu --name pumux` — passed after fixing `Result<String>` and actor isolation issues.
- Actual shell checks:
  - `zsh -ic 'whence -f mtl; mtl'` showed `ssh mac 'tmux ls...'` and the expected remote session list.
  - `ssh mac 'tmux list-sessions -F '\''#S'\'' 2>/dev/null'` returned the four expected sessions.
- `./scripts/reload.sh --tag pi-session-registry --name pumux` — passed.
- Autosave snapshot inspection confirmed `tmux: Pi-Pumux` stores Pi agent metadata and tmux start command.
- `./scripts/reload.sh --tag upstream-0645 --name pumux` — passed after merging upstream `v0.64.5`.
- `/Applications/pumux.app` installed and reports `CFBundleShortVersionString=0.64.5`, bundle id `com.cmuxterm.app.debug.pumux`.
- Static preservation checks after merge found MOSH TMUX menu, `tmux ls` fetch, Pi registry integration, and canonical mosh attach code.
- Missing: full reboot dogfood of `Pi-Pumux` auto-resume; next session should verify this manually.

## Remaining implementation

- [ ] Dogfood reboot/app-restart restore: confirm `tmux: Pi-Pumux` recreates/attaches tmux session and auto-runs `pi --session 019e1b9f-3e22-722b-9075-b7715758ed23`.
- [ ] Exercise MOSH TMUX menu in the installed 0.64.5 app after upstream merge; verify menu list and attach still work interactively.
- [ ] Triage minor UI/socket oddities seen during dogfood: CLI socket returned `Broken pipe` in one launched app instance; app autosave still worked.
- [ ] Consider adding lightweight runtime/unit coverage for Pi registry-to-session-snapshot mapping if a stable seam exists.
- [ ] Decide whether old `f7fde755` handoff artifacts should remain committed as historical context or later be archived after this new handoff supersedes them.

## Resume pointers

- Next start command: `/llc:hands-on pumux-pi-api-restore-upstream-0645`
- Alternate: `/llc:hands-on latest`
- First files to inspect:
  - `docs.works/handoffs/b38564ce-c239-4b64-80f8-d9b2261fcdde/handoff.md`
  - `Sources/Workspace.swift` around `piRegistryAgent`
  - `Sources/VaultAgentProcessScanner.swift` around `PiSessionContextRegistry`
  - `Sources/AppDelegate.swift` around `fetchMoshTmuxSessionsForMenu()`
  - `docs.works/tmp/subagent-upstream-stable-check.md`
- Important commits:
  - `6d4c55b73 Restore Pi sessions from registry in pumux`
  - `f168daa1e Merge upstream cmux v0.64.5 into pumux`
