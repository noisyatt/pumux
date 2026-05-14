---
date: 2026-05-12
project: pumux
doc_type: worklog
handoff: f7fde755-b954-4698-b43c-de79b4296a57
alias: pumux-tmux-mosh-menu-split-planning
title: pumux upstream merge + remote tmux alias resolver + 다음 메뉴 분리 설계
---

## 사용자 목표

- 좌측 패널의 "업데이트 0.64.4" 알림에 맞춰 upstream cmux 변경을 pumux fork에 반영하기.
- 그 과정에서 tmux/mosh+tmux로 만든 워크스페이스가 앱 재시작/프로필 로드 시 자동 재접속되도록 하기.
- 결정사항: title-based 추론보다 “tmux/mosh tmux 목록 fetch → UI attach → 세션 저장” 흐름이 더 단순. 다음 세션에서 메뉴 분리와 retry UX 구현.

## 실제 작업

1. upstream remote 확인, `v0.64.4` 태그 fetch, ahead/behind 분석 (HEAD 14, upstream 73 / main 89).
2. `merge-stable-v0.64.4-pumux` 브랜치에서 `git merge --no-ff v0.64.4` 실행. 충돌 4건 발생:
   - `Sources/GhosttyTerminalView.swift`
   - `Sources/RightSidebarPanelView.swift`
   - `Sources/Workspace.swift`
   - `vendor/bonsplit` (submodule)
     각각 upstream 변경 + pumux TokenManager/tab color/right sidebar close button 패치 보존 방향으로 수동 해결.
3. submodule `vendor/bonsplit`은 로컬 customColor 커밋 2개를 보존하기 위해 `pumux-merge-stable-v0.64.4` 브랜치로 stable f65eccb 머지 후 `noisyatt/bonsplit#main` 푸시.
4. Swift 6 conformance/warning-as-error 보정:
   - `@MainActor`/`@preconcurrency UNUserNotificationCenterDelegate`
   - BrowserPanel static helper 기본 인자 제거(nonisolated 호출 호환)
5. `./scripts/reload.sh --tag merge-stable-0644 --name pumux` 빌드 성공. `/Applications/pumux.app` 교체 설치, Dock 중복 정리.
6. main fast-forward → `f028121bc Merge upstream cmux v0.64.4 into pumux` 푸시, 임시 브랜치 삭제.
7. tmux/mosh 계정 뱃지 안정성 토론 → 결론: Pi가 publish, pumux는 mosh/ssh 통해 그대로 읽음(ssh config가 모든 라우팅 해결).
8. zsh alias + ssh config를 사용한 remote tmux 추론 추가:
   - `zshAliasMap()` `~/.zshenv/.zprofile/.zshrc/.zlogin` + sourced 파일까지 따라가며 `alias name=value` 파싱
   - `sshConfigHostAliases()` `~/.ssh/config` `Host` 라인
   - `remoteTmuxContext(fromDisplayedCommandTitle:)` token 기반 mosh/ssh/bare ssh-host 인식, `tmux ... -s/-t <session>` 추출
9. snapshot/restore 경로 보강:
   - `sessionPanelSnapshot`에서 explicit `tmuxStartCommand` 없으면 표시 제목에서 추론한 mosh/ssh 명령을 저장
   - `createPanel(from:)`에서 snapshot `tmuxStartCommand` 없으면 저장된 title에서 다시 추론
   - canonical 명령은 `mosh '<host>' -- tmux new-session -A -s '<session>'` 형식
10. 빌드/설치 재실행, main 푸시 → `98ec7bde3 Restore remote tmux aliases`.
11. 실제 mtl 워크스페이스로 만든 세션 프로필 2번이 자동 attach 안 되는 케이스 발견. 사용자 zsh function 확인:
    - `mt() { mosh mac -- tmux new-session -A -s "$1"; }`
    - `mtl() { ssh mac 'tmux ls 2>/dev/null || ...' }` ← attach 아님, 목록
      저장된 `panel.title`이 `"C6 - TMUX - mt Dotozip-arc"` 같이 잘리거나 `tmuxStartCommand`가 비어 있어 title 기반 추론만으론 부족.
12. 사용자 결정: 다음 세션에서 메뉴를 두 개로 쪼개고(`TMUX`/`MOSH TMUX`), `tl`/`mtl`로 목록 뽑아 UI에서 붙고 세션 저장에 attach 명령을 그대로 넣는 방향으로 간다. 컨텍스트 가득 차서 halftime-nextstage로 영구화.

## 변경 파일

- Sources/Workspace.swift — remote tmux alias resolver, snapshot/restore 보강 (커밋 98ec7bde3)
- Sources/AppDelegate.swift — `@preconcurrency UNUserNotificationCenterDelegate` 보정 (커밋 f028121bc)
- Sources/Panels/BrowserPanel.swift — main-actor 정적 함수 기본 인자 정리 (커밋 f028121bc)
- Sources/Workspace+PanelLifecycle.swift — upstream 도입 helper에 pumux 전용 정리 추가 (커밋 f028121bc)
- vendor/bonsplit — local custom tab color 2 커밋 위에 stable v0.64.4 머지 (`4cc7b9a` 푸시)
- 신규 추가: docs.works/handoffs/f7fde755-b954-4698-b43c-de79b4296a57/, docs.works/worklogs/20260512-f7fde755-\*.md (이 handoff 자체)

## 실행 명령과 결과

- `git fetch upstream --tags --prune` — OK
- `git merge --no-commit --no-ff v0.64.4` — 충돌 4건 발생 후 수동 해결
- `git -C vendor/bonsplit fetch upstream && git -C vendor/bonsplit checkout f65eccb ...` — OK
- `./scripts/reload.sh --tag merge-stable-0644 --name pumux` — 두 번째 시도부터 SUCCESS
- `./scripts/reload.sh --tag remote-pi-resolver --name pumux` — SUCCESS
- `git push origin main` (2회) — OK
- `defaults import com.apple.dock ...; killall Dock` — OK (Dock 항목 중복 정리)

## 실패한 시도/기각된 접근

- title-only 복원 (`restorableRemoteTmuxStartCommand`): `mtl`은 list 명령이라 세션명이 title에 없을 때가 있고, alias 정의가 사용자별로 달라 보편성이 약함. → 단독 의존 기각.
- pumux가 별도 HTTP/Unix endpoint를 띄워 Pi에 직접 fetch: ssh config + zsh alias만 알아도 충분하다는 결론.
- `dockutil` 없는 환경에서 `defaults write -array-add`만 사용 → 중복 entry 발생. plistlib로 dedup 처리해 해결.

## 사용자 결정사항

- upstream v0.64.4를 stable로 채택, main으로 fast-forward 후 임시 브랜치 삭제.
- remote tmux 처리는 ssh config + zsh alias 기반으로 한다. Pi 별도 endpoint는 만들지 않는다.
- 다음 세션에서 메뉴 분리 + 5회 retry + 로딩 중 select 비활성 구현.
- Pi 계정 라벨 publisher 작업은 별도 트랙.

## 미해결 작업

- TMUX / MOSH TMUX 메뉴 분리 미구현.
- mosh 세션 목록 fetch 비동기 + retry 미구현.
- 세션 저장 시 attach 명령 명시 저장은 일부 (`tmuxStartCommand` snapshot) 들어갔지만 신규 attach 흐름과 통합 필요.
- 기존 title-based 추론 코드 정리 여부 결정 필요(제거 vs fallback 강등).

## 다음 세션 first-read 파일

1. docs.works/handoffs/f7fde755-b954-4698-b43c-de79b4296a57/handoff.md
2. docs.works/handoffs/f7fde755-b954-4698-b43c-de79b4296a57/handoff.keys.md
3. Sources/cmuxApp.swift (Menu("tmux") 540-580)
4. Sources/AppDelegate.swift 2680-2960
5. Sources/TabManager.swift 5410-5440
6. Sources/Workspace.swift 600-650, 8359-8470

## 검색 키워드/별칭

- pumux, cmux fork, tmux menu split, mosh tmux menu, mtl retry, ssh config host alias
- tmuxSessionNames, currentTmuxSessionNamesForMenu, promptNewTmuxTab, newManagedTmuxSurface
- restorableRemoteTmuxStartCommand, remoteTmuxContextFromMosh, RemoteTmuxContext
- 98ec7bde3 Restore remote tmux aliases, f028121bc Merge upstream cmux v0.64.4 into pumux
- session-com.cmuxterm.app.debug.pumux.json, session-profiles/2.json
