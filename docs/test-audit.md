# Test audit

Newest first.

## 2026-11-22: due (new repo, watch agent added in PR #1)
- Promises (README, CLAUDE.md): the leak check runs on every change and blocks emails, private terms and committed build output; the watch agent keeps `lighthouse watch --forever --notify` running (KeepAlive, RunAtLoad, at most one restart a minute), writes only to the log (stdout dropped so lines aren't doubled), refuses to install before `lighthouse setup`, and `off` keeps it off after restarts.
- Covered: `bash scripts/watch-agent.sh selftest` (7 checks: valid plist; the exact command and log path; KeepAlive and RunAtLoad; ThrottleInterval 60; node on PATH; stdout to /dev/null; install refuses before setup and writes nothing). The leak check: .github/workflows/leak-check.yml on every push and PR (pinned checkout, read-only, persist-credentials false); it passed on every commit so far.
- Gaps added: none needed this pass.
- Cleanup: the selftest writes only into a mktemp folder removed by an EXIT trap; it never calls launchctl.
- Gaps skipped (and why): `off`, `on`, `remove` and `status` call launchctl against the real label in the user's GUI domain, so a test would stop a real station's watcher; they're thin wrappers over launchctl and were run by hand on 2026-11-22. CLAUDE.md's setup rules are instructions for sessions, not code.
