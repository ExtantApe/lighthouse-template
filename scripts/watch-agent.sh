#!/bin/bash
# Keeps `lighthouse watch --forever` running for this user: a LaunchAgent that starts at login and restarts it if it
# stops. Each new bottle (or, on a None vessel, each new chart notice) becomes one line in ~/.lighthouse/watch.log and
# a Mac notification. No admin rights: it lives in ~/Library/LaunchAgents.
#
#   bash scripts/watch-agent.sh install    write the agent and start it (the default for every station)
#   bash scripts/watch-agent.sh off        stop it, and keep it off after restarts, until `on`
#   bash scripts/watch-agent.sh on         start it again
#   bash scripts/watch-agent.sh remove     stop it and move the agent file to the Trash
#   bash scripts/watch-agent.sh status     is it running, and the last lines of the log
#   bash scripts/watch-agent.sh selftest   check the agent file it would write, without loading anything
#
# A Claude session can follow the log and be woken only when a line is added:  tail -n 0 -F ~/.lighthouse/watch.log
set -u
LABEL=com.extantape.lighthouse-watch
AGENTS="${WATCH_AGENT_DIR:-$HOME/Library/LaunchAgents}"
PLIST="$AGENTS/$LABEL.plist"
LH_HOME="${LIGHTHOUSE_HOME:-$HOME/.lighthouse}"
LOG="$LH_HOME/watch.log"
DOMAIN="gui/$(id -u)"

plist() { # lighthouse-binary node-dir
  local path="$2:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$1</string><string>watch</string><string>--forever</string><string>--notify</string>
    <string>--log</string><string>$LOG</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>$path</string><key>LIGHTHOUSE_HOME</key><string>$LH_HOME</string></dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>60</integer>
  <key>ProcessType</key><string>Background</string>
  <key>StandardOutPath</key><string>/dev/null</string>
  <key>StandardErrorPath</key><string>$LH_HOME/watch-agent.err</string>
</dict>
</plist>
EOF
}

need_station() {
  [ -f "$LH_HOME/station.json" ] || { echo "This machine isn't a station yet. Run lighthouse setup first."; exit 1; }
}

case "${1:-status}" in
  install)
    need_station
    lh=$(command -v lighthouse) || { echo "lighthouse isn't on your PATH. Install it first, from source (it isn't on npm yet): see step 1 of \"Set up on this machine\" in README.md"; exit 1; }
    node=$(command -v node) || { echo "node isn't on your PATH."; exit 1; }
    mkdir -p "$AGENTS" "$LH_HOME"; touch "$LOG"; chmod 600 "$LOG"
    plist "$lh" "$(dirname "$node")" > "$PLIST.tmp" && plutil -lint -s "$PLIST.tmp" && mv "$PLIST.tmp" "$PLIST" || { rm -f "$PLIST.tmp"; echo "couldn't write the agent"; exit 1; }
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null
    launchctl enable "$DOMAIN/$LABEL"
    launchctl bootstrap "$DOMAIN" "$PLIST" && echo "Watching. New arrivals go to $LOG (follow it with: tail -n 0 -F $LOG)"
    ;;
  off)
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null
    launchctl disable "$DOMAIN/$LABEL"
    echo "Stopped, and it stays off after restarts. Turn it back on with: bash scripts/watch-agent.sh on"
    ;;
  on)
    [ -f "$PLIST" ] || { echo "No agent yet. Run: bash scripts/watch-agent.sh install"; exit 1; }
    launchctl enable "$DOMAIN/$LABEL"
    launchctl bootstrap "$DOMAIN" "$PLIST" 2>/dev/null || launchctl kickstart "$DOMAIN/$LABEL"
    echo "Watching again."
    ;;
  remove)
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null
    [ -f "$PLIST" ] && mv "$PLIST" "$HOME/.Trash/$LABEL-$(date +%Y%m%d-%H%M%S).plist" && echo "Removed (the agent file is in the Trash). The log stays at $LOG."
    ;;
  status)
    if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
      echo "running: $(launchctl print "$DOMAIN/$LABEL" | awk '/^\tstate =/{print $3}') (pid $(launchctl print "$DOMAIN/$LABEL" | awk '/^\tpid =/{print $3}'))"
    elif launchctl print-disabled "$DOMAIN" 2>/dev/null | grep -q "\"$LABEL\" => disabled"; then
      echo "off (turned off with: bash scripts/watch-agent.sh off)"
    else
      echo "not running"
    fi
    [ -f "$LOG" ] && { echo "log: $LOG"; tail -n 5 "$LOG"; }
    ;;
  selftest)
    T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
    LOG="$T/watch.log" LH_HOME="$T"
    plist /opt/example/bin/lighthouse /opt/example/node/bin > "$T/a.plist"
    pass=0 total=0
    t() { total=$((total+1)); if eval "$2"; then pass=$((pass+1)); echo "ok    $1"; else echo "FAIL  $1"; fi; }
    t "the agent file is a valid plist" 'plutil -lint -s "$T/a.plist"'
    t "it runs watch --forever --notify with the log" 'python3 -c "import plistlib,sys; a=plistlib.load(open(sys.argv[1],\"rb\"))[\"ProgramArguments\"]; sys.exit(a!=[\"/opt/example/bin/lighthouse\",\"watch\",\"--forever\",\"--notify\",\"--log\",sys.argv[2]])" "$T/a.plist" "$T/watch.log"'
    t "KeepAlive and RunAtLoad are on" '[ "$(plutil -extract KeepAlive raw "$T/a.plist")" = true ] && [ "$(plutil -extract RunAtLoad raw "$T/a.plist")" = true ]'
    t "restarts at most once a minute" '[ "$(plutil -extract ThrottleInterval raw "$T/a.plist")" = 60 ]'
    t "node is on its PATH" 'plutil -extract EnvironmentVariables.PATH raw "$T/a.plist" | grep -q "^/opt/example/node/bin:"'
    t "stdout is dropped, so log lines aren't doubled" '[ "$(plutil -extract StandardOutPath raw "$T/a.plist")" = /dev/null ]'
    t "install refuses before setup" '! LIGHTHOUSE_HOME="$T/none" WATCH_AGENT_DIR="$T/agents" bash "$0" install >/dev/null 2>&1 && [ ! -e "$T/agents" ]'
    echo "watch-agent selftest: $pass of $total passed"
    [ "$pass" = "$total" ]
    ;;
  *) echo "usage: bash scripts/watch-agent.sh install|off|on|remove|status|selftest"; exit 2 ;;
esac
