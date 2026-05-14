---
id: f7fde755-b954-4698-b43c-de79b4296a57
alias: pumux-tmux-mosh-menu-split-planning
short_id: f7fde755
date: 2026-05-12
project: pumux
doc_type: prompts
title: pumux TMUX/MOSH TMUX 메뉴 분리와 mtl 로딩 retry 설계
status: open
---

## 컨텍스트

- 이번 세션은 pumux fork를 upstream cmux v0.64.4까지 끌어올리고, remote tmux account 뱃지/복원 동작을 안정화하는 작업.
- 완료한 일:
  - upstream/v0.64.4 merge → main `f028121bc Merge upstream cmux v0.64.4 into pumux` (vendor/bonsplit submodule 병합 포함, 푸시 완료)
  - `/Applications/pumux.app` 교체 설치, Dock 등록 정리
  - `Sources/Workspace.swift`에 zsh alias 확장 + ssh config Host alias 기반 remote tmux 추론 추가, 그 정보를 가지고 snapshot 저장/복원 시 `mosh host -- tmux new-session -A -s session` 형태의 `tmuxStartCommand`를 자동 복원하도록 변경 → main `98ec7bde3 Restore remote tmux aliases` (푸시 완료)
- 멈춘 지점:
  - 실제 사용자의 `mt/mtl` zsh function은 `mosh mac -- tmux new-session -A -s "$1"` / `ssh mac 'tmux ls ...'` 형태. `mtl`은 attach가 아니라 목록 명령이라 title 기반 복원만으로는 세션 명을 모름.
  - 사용자가 “title 기반 추론 방향은 그만, 앱 시작 시 tmux/mosh tmux 목록을 미리 뽑아 UI로 붙고 그대로 세션 저장”하는 단순한 흐름으로 가자고 결정.
  - 즉 다음 세션에서 menu/저장 흐름을 다시 설계해야 함.

## 사용자 결정

- TMUX 메뉴와 MOSH TMUX 메뉴를 별도로 분리한다. 현재 `Sources/cmuxApp.swift:545` `Menu("tmux")` 하나에 합쳐져 있음.
- `mt` (MOSH TMUX)는 네트워크 지연으로 로딩이 실패할 수 있으니 **최대 5회 retry**한다.
- 로딩이 끝나기 전까지는 해당 항목 선택 불가 (disabled / spinner).
- 세션 저장 시 attach 대상이 명시적으로 남아야 한다. (local: `t <session>` / canonical `tmux new-session -A -s <session>`, remote: `mt <session>` / canonical `mosh <host> -- tmux new-session -A -s <session>`)
- 이번 세션의 “표시 제목에서 mt/mosh를 거꾸로 파싱해 복원”하는 방향은 기각하지는 않았지만, primary는 “목록 fetch + UI attach + 명시 저장” 흐름이다.
- Pi/Mosh 계정 라벨 자체는 별도 reporter API 설계 트랙(앞선 토론 참고)에서 다룸. 이번 handoff는 메뉴/복원 흐름에 한정.

## 변경 파일

- Sources/Workspace.swift — 98ec7bde3에서 변경됨. 다음 작업 시 다음 부분 점검 필요:
  - `restorableRemoteTmuxStartCommand(fromDisplayedCommandTitle:)` (line ~621): title 기반 추론. 새 방향 채택 시 제거 또는 fallback only로 강등 고려.
  - `remoteTmuxContext(fromDisplayedCommandTitle:)` (line ~8359), `remoteTmuxContextFromMosh/SSH/BareSSHHost`: alias 확장기 핵심. 메뉴 분리 후에도 “Remote Tmux 뱃지”용으로는 계속 유효.
  - `zshAliasMap()`/`sshConfigHostAliases()`: 새 메뉴/세션 저장 흐름에서도 alias resolve용으로 재활용 가능.
- Sources/cmuxApp.swift — line 545 `Menu("tmux")` 분리 작업 시작 지점.
- Sources/AppDelegate.swift — 다음 함수가 새 흐름의 hooking point:
  - `tmuxSessionNames()` (line 2914): 현재 로컬 `tmux list-sessions -F '#S'`. mosh 변형 추가 필요.
  - `currentTmuxSessionNamesForMenu()` (line 2738): 메뉴에 노출.
  - `promptNewTmuxTab(...)` (line 2868): 신규 attach 다이얼로그. mosh용 별도 prompt 필요.
- Sources/TabManager.swift — `newManagedTmuxSurface(sessionName:)` (line 5427): 현재 로컬 전용. 원격용 변형/공용 API 필요.
- 저장: SessionTerminalPanelSnapshot의 `tmuxStartCommand`를 attach 대상 canonical 명령으로 저장하면 복원이 그대로 작동(이미 98ec7bde3에서 일부 구현). 새 메뉴 흐름이 명시적으로 이걸 채우도록 만들면 끝.

## 검증

- `./scripts/reload.sh --tag merge-stable-0644 --name pumux` — 성공 (이번 세션, merge 직후)
- `./scripts/reload.sh --tag remote-pi-resolver --name pumux` — 성공 (alias resolver 추가 후)
- 실제 사용 smoke: 사용자가 `mtl`로 만든 워크스페이스 두 개를 재시작 시 자동 attach 되지 않음을 확인 → 방향 전환의 트리거.
- CI/e2e 미실행.

## 실패/기각

- title에서 alias를 거꾸로 풀어 복원 명령을 만드는 접근만으로 mtl 워크스페이스 자동 attach를 보장하기는 어렵다. `mtl`은 list 명령이라 세션명이 title에 없을 수 있고, 사용자가 GUI에서 새 세션 만들었을 때 alias 표현이 매번 다를 수 있음.
- pumux가 Pi/remote에서 직접 endpoint fetch하려던 별도 트랙: 사용자가 “ssh config + zsh alias로 이미 다 알 수 있는데 굳이 별 endpoint 만들 필요 없다”고 결정. (참고만, 이번 handoff 범위 밖)

## 미완료

- [ ] `Sources/cmuxApp.swift`의 `Menu("tmux")`를 두 개 메뉴로 분리: "TMUX" (local) / "MOSH TMUX" (remote)
- [ ] 각 메뉴 본문에 “세션 목록 fetch → 항목 선택 시 attach” 흐름 구현
  - local: `tmux list-sessions -F '#S'`
  - remote: `ssh <host> 'tmux list-sessions -F #S'` (host는 ssh config Host alias / zsh alias에서 resolve)
- [ ] remote list fetch는 비동기 + 최대 5회 retry, 그 동안 메뉴/항목 disabled 상태 유지
- [ ] attach 시 호출되는 새 API: `newManagedTmuxSurface`의 mosh 버전 추가, snapshot에 canonical attach command 저장
- [ ] 기존 `restorableRemoteTmuxStartCommand` title 추론 경로 정리: 새 명시 저장 흐름과 충돌 없는지, fallback으로만 둘지 결정
- [ ] Pi/계정 라벨 reporter 트랙은 별도 handoff로 분리

## Phase 연속성

- plan_id: (none)
- tier: T1
- phase_cursor: planning
- phases_completed: upstream-merge, install, alias-resolver-stage1
- review_status: open
- active.json: (없음)

## 다음 세션 지시

- 먼저 읽을 파일:
  1. `Sources/cmuxApp.swift` (Menu("tmux") 주변 lines 540-580)
  2. `Sources/AppDelegate.swift` lines 2680-2960 (tmux 관련 prompts, listing)
  3. `Sources/TabManager.swift` lines 5410-5440 (newManagedTmuxSurface)
  4. `Sources/Workspace.swift` lines 600-650 (managedTmuxStartCommand / restorableRemoteTmuxStartCommand)
  5. 이번 handoff의 `handoff.md`
- 첫 실행 명령:
  - `git status -sb` (clean인지 확인)
  - `grep -n 'Menu(\"tmux\")\|tmuxSessionNames\|promptNewTmuxTab' Sources/cmuxApp.swift Sources/AppDelegate.swift`
- 사용자가 기대하는 다음 결과:
  - 메뉴바에 "TMUX" / "MOSH TMUX" 두 메뉴 노출
  - MOSH TMUX는 fetch 중 disabled + spinner, 최대 5회 retry 후 항목 활성화
  - 항목 클릭 시 새 tab/workspace로 해당 세션에 attach
  - 그렇게 만들어진 tab이 세션 프로필에 저장되었다가 다음 부팅 때 동일 세션으로 자동 attach

## 검색 키워드

- pumux, cmux fork, tmux menu split, mosh tmux menu, mtl retry, ssh config host alias
- tmuxSessionNames, currentTmuxSessionNamesForMenu, promptNewTmuxTab, newManagedTmuxSurface
- restorableRemoteTmuxStartCommand, remoteTmuxContextFromMosh, RemoteTmuxContext
- Restore remote tmux aliases (commit 98ec7bde3)
- Merge upstream cmux v0.64.4 (commit f028121bc)
- session-com.cmuxterm.app.debug.pumux.json, session-profiles/2.json
