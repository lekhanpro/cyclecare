#!/usr/bin/env bash
# Status and collision matrix across the parallel port branches.
#
#   tool/dev/port_status.sh            # commits, dirt and changed-file counts
#   tool/dev/port_status.sh --files    # also list every changed file per branch
#   tool/dev/port_status.sh --clashes  # only the files two or more branches touch
#
# Many agents port different areas of the app at once, each in its own git
# worktree under D:/cyclecare-wt. Two branches editing one file is not a
# mistake by itself — the data layer deliberately makes small edits to screens
# another branch rewrites — but every such file needs a decision at merge
# time, so they are worth seeing early rather than discovering in a conflict.
set -u
BASE="${CC_PORT_BASE:-$(git merge-base --octopus $(git rev-parse HEAD) 2>/dev/null || git rev-parse HEAD)}"
ROOT=/d/cyclecare-wt
MODE="${1:-}"

branches=()
for dir in "$ROOT"/*; do
  [ -d "$dir/.git" ] || [ -f "$dir/.git" ] || continue
  branches+=("$(basename "$dir")")
done

printf '%-14s %7s %6s %7s  %s\n' BRANCH COMMITS DIRTY FILES HEAD
for name in "${branches[@]}"; do
  dir="$ROOT/$name"
  base=$(git -C "$dir" merge-base HEAD "$BASE" 2>/dev/null || echo "$BASE")
  commits=$(git -C "$dir" rev-list --count "$base"..HEAD 2>/dev/null || echo '?')
  dirty=$(git -C "$dir" status --porcelain 2>/dev/null | grep -cv ' android/' || true)
  files=$(git -C "$dir" diff --name-only "$base"..HEAD 2>/dev/null | grep -v '^android/' | wc -l)
  head=$(git -C "$dir" log --oneline -1 2>/dev/null | cut -c1-54)
  printf '%-14s %7s %6s %7s  %s\n' "$name" "$commits" "$dirty" "$files" "$head"
done

list_files() {
  for name in "${branches[@]}"; do
    dir="$ROOT/$name"
    base=$(git -C "$dir" merge-base HEAD "$BASE" 2>/dev/null || echo "$BASE")
    git -C "$dir" diff --name-only "$base"..HEAD 2>/dev/null |
      grep -v '^android/' |
      sed "s|^|$name |"
  done
}

if [ "$MODE" = "--files" ]; then
  echo
  list_files | sort -k2 | awk '{printf "%-14s %s\n", $1, $2}'
fi

if [ "$MODE" = "--clashes" ] || [ "$MODE" = "--files" ]; then
  echo
  echo "Files changed on more than one branch:"
  list_files | awk '{print $2" "$1}' | sort |
    awk '{ if ($1 == last) { owners = owners " " $2 } else { if (n > 1) print n"  "last"   <- "owners; last = $1; owners = $2; n = 0 } n++ }
         END { if (n > 1) print n"  "last"   <- "owners }' |
    sort -rn
fi
