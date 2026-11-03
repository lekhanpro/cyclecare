#!/usr/bin/env bash
# Machine-wide queue for flutter commands, shared by every port agent.
#
#   /d/tmp/cc-tools/flutterq.sh analyze lib/features/health test/widget/health_test.dart
#   /d/tmp/cc-tools/flutterq.sh test test/widget/health_test.dart
#   /d/tmp/cc-tools/flutterq.sh test --dart-define=SHOTS=true test/shots/health_shots_test.dart
#
# Many agents work in parallel worktrees on one 16 GB machine. A test compile
# (frontend_server) or an analysis server can take about 1 GB each, so at most
# CC_FLUTTER_SLOTS (default 3) run at once and the rest wait. Three is not
# arbitrary: this machine idles with about 3 GB free, so a fourth concurrent
# compile swaps and makes every agent slower. The way to avoid starving a
# large fan-out is fewer runs per agent, not more slots.
# for a free slot. `flutter test` defaults to --concurrency=2 here unless -j or
# --concurrency is given.
set -u
SLOTS="${CC_FLUTTER_SLOTS:-3}"
ROOT=/d/tmp/cc-flutter-slots
mkdir -p "$ROOT"
slot=""
announced=0
while [ -z "$slot" ]; do
  # A slot older than 15 minutes belongs to a command that was killed before it
  # could release it (for example a tool timeout); reclaim it.
  find "$ROOT" -mindepth 1 -maxdepth 1 -name 'slot*' -mmin +15 -exec rm -rf {} + 2>/dev/null
  for i in $(seq 1 "$SLOTS"); do
    if mkdir "$ROOT/slot$i" 2>/dev/null; then
      slot="$i"
      break
    fi
  done
  if [ -z "$slot" ]; then
    if [ "$announced" -eq 0 ]; then
      echo "[flutterq] all $SLOTS flutter slots are busy; waiting for one..." >&2
      announced=1
    fi
    node -e "setTimeout(() => {}, 4000)"
  fi
done
trap 'rm -rf "$ROOT/slot$slot"' EXIT INT TERM

export PATH="/d/flutter/bin:$PATH" TMP=/d/tmp TEMP=/d/tmp
args=("$@")
if [ "${1:-}" = "test" ]; then
  case " $* " in
    *" -j"*|*"--concurrency"*) ;;
    *) args=(test --concurrency=2 "${@:2}") ;;
  esac
fi
flutter "${args[@]}"
