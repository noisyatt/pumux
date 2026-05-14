---
id: b38564ce-c239-4b64-80f8-d9b2261fcdde
alias: pumux-pi-api-restore-upstream-0645
short_id: b38564ce
date: 2026-05-14
project: pumux
doc_type: prompts
title: pumux Pi API restore and upstream v0.64.5 follow-up
status: open
---

# pumux-pi-api-restore-upstream-0645

## Resume now

- Current state: pumux main is pushed at `f168daa1e` with upstream cmux `v0.64.5`; `/Applications/pumux.app` is installed at version `0.64.5`.
- Current state: MOSH TMUX menu/`mtl` listing, canonical mosh attach, and Pi registry-to-session snapshot restore are implemented and build-verified.
- Next action: dogfood the installed app by restarting/reopening and checking that `tmux: Pi-Pumux` restores tmux then auto-runs `pi --session 019e1b9f-3e22-722b-9075-b7715758ed23`.
- Stop / avoid: do not rely on title-only parsing for remote tmux; do not overwrite current `docs.works` handoff artifacts without reading status first.

## Decisions to preserve

- Pi owns session context metadata/API/registry; pumux consumes durable restore metadata instead of parsing Pi session files.
- Reboot restore target is equivalent process recreation (`tmux new-session -A` + `pi --session`), not live process survival.
- MOSH TMUX session discovery should match user `mtl`: zsh function body discovery + `ssh mac 'tmux ls 2>/dev/null'` parsing.
- Upstream stable `v0.64.5` was accepted and merged after isolated worker verification.

## Open work

- [ ] Verify actual app/reboot restore of `Pi-Pumux` and confirm Pi auto-resume in the restored tmux pane.
- [ ] Verify installed `0.64.5` MOSH TMUX menu fetch/attach in UI after upstream merge.
- [ ] Investigate any lingering CLI socket `Broken pipe` if it reproduces.
- [ ] Consider small coverage/seam for Pi registry snapshot mapping.

## Evidence map

- Worklog: `docs.works/worklogs/20260514-b38564ce-pumux-pi-api-restore-upstream-0645.md`
- Worklog sidecar: `docs.works/worklogs/20260514-b38564ce-pumux-pi-api-restore-upstream-0645.keys.md`
- Handoff sidecar: `docs.works/handoffs/b38564ce-c239-4b64-80f8-d9b2261fcdde/handoff.keys.md`
- Subagent artifacts/reports: `docs.works/tmp/subagent-upstream-stable-check.md`
- Child sessions: `/Users/daniel/.pi/agent/sessions/--Users-daniel-projects-pumux--/2026-05-14T01-25-18-980Z_019e2416-9003-720c-8e9b-71de2660dc38.jsonl`
- Important source/config paths: `Sources/Workspace.swift`, `Sources/VaultAgentProcessScanner.swift`, `Sources/AppDelegate.swift`, `Sources/TabManager.swift`, `Sources/cmuxApp.swift`, `docs.works/design/20260512-pi-session-context-api-for-pumux.md`, `~/.pi/agent/session-registry.json`
- Instruction/memory updates: none

## Validation state

- Passed: `./scripts/reload.sh --tag upstream-0645 --name pumux`; `/Applications/pumux.app` installed and reports `0.64.5`.
- Passed: `pi session inspect --pid 73395 --json`, `pi session inspect --tmux-pane %5 --json` returned the active `PumuxDev_26.0512.01` Pi session.
- Passed: autosave snapshot inspection showed `tmux: Pi-Pumux` has `kind: pi`, session id `019e1b9f-3e22-722b-9075-b7715758ed23`, and `tmuxStartCommand`.
- Missing: real restart/reboot dogfood and interactive MOSH TMUX menu check on the final `v0.64.5` app.
- Lead review: accepted
