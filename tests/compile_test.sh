#!/usr/bin/env bash
# Real librime compile + typing test. Needs the main repo checkout (read-only use) for its librime harness:
#   rimebin/root (extracted Ubuntu debs: librime + librime-plugin-octagram), weasel/docs/rime_driver.py, test case files.
# usage: bash tests/compile_test.sh [MAIN_REPO_DIR]     (default: ../cangjie-fluency next to this repo)
# Installs with install.sh --offline (files from the main repo checkout: no network) into testenv/real (git-ignored), builds with rime_deployer, drives librime key by key.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
M="${1:-$HERE/../cangjie-fluency}"
R="$M/rimebin/root"; D="$M/weasel/docs"
export LD_LIBRARY_PATH="$R/usr/lib/aarch64-linux-gnu"
T="$HERE/testenv"; U="$T/real"; S="$T/shared"; O="$T/out"
mkdir -p "$S" "$O"
# prelude files only (default.yaml, luna_pinyin...): no essay.txt / .gram / cangjie base here, so that everything the
# build uses comes from what install.sh put into the user dir
for f in default.yaml key_bindings.yaml luna_pinyin.dict.yaml luna_pinyin.schema.yaml luna_quanpin.schema.yaml pinyin.yaml punctuation.yaml symbols.yaml; do
  cp "$M/testenv/shared_nogy/$f" "$S/"
done
rm -rf "${U:?}" "${O:?}"; mkdir -p "$O"

echo "## install"
RIME_SHARED_DIRS="$T/none-shared" CJF_SRC_DIR="$M" bash "$HERE/install.sh" --offline --no-deps --frontend fcitx5 --rime-dir "$U" --with-cangjie5 --no-deploy 2>&1 | tee "$O/install.txt"

echo "## build"
( time "$R/usr/bin/rime_deployer" --build "$U" "$S" ) 2>&1 | tee "$O/build.txt"
find "$U/build" -type f -printf "%s %f\n" | sort -k2 | tee -a "$O/build.txt"

drv() { python3 -I "$D/rime_driver.py" --root "$R" --shared "$S" --user "$U" --base "$U/cangjie3.base.dict.yaml" --schema cangjie3_fluency --no-commit "$@"; }
mapfile -t SEN < "$D/sentences.txt"; mapfile -t HARD < "$D/hard.txt"
mapfile -t TR < "$D/trace.txt"; mapfile -t SH < "$D/show.txt"; mapfile -t KEYS < "$D/keys_c3.txt"

echo "## accuracy"
{ echo "### sentences.txt (51)"; drv --quiet "${SEN[@]}"; drv --quiet --no-grammar "${SEN[@]}"
  echo "### hard.txt (40)";      drv --quiet "${HARD[@]}"; drv --quiet --no-grammar "${HARD[@]}"; } 2>&1 | tee "$O/acc.txt"
echo "## trace"; { drv "${TR[@]}"; drv --no-grammar "${TR[@]}"; } 2>&1 | tee "$O/trace.txt"
echo "## show"; drv "${SH[@]}" 2>&1 | tee "$O/show.txt"
echo "## keys"; { drv "${KEYS[@]}"; drv --schema cangjie5_fluency "${KEYS[@]}"; } 2>&1 | tee "$O/keys.txt"
echo "## log"; grep -h 'use grammar' "$U"/log/rime.cangjie-fluency-test.INFO | head -3 | tee "$O/log.txt"

echo "## extra per-key trace: 面 (mwyl) and 板橋, codes taken from the generated table"
drv "trace:面" "trace:板橋" 2>&1 | tee "$O/trace_mian.txt"

echo "## --no-model install (plugin loaded by the driver, but no .gram present): must still build and type"
N="$T/nomodel"; rm -rf "${N:?}"
RIME_SHARED_DIRS="$T/none-shared" CJF_SRC_DIR="$M" bash "$HERE/install.sh" --offline --no-deps --frontend fcitx5 --rime-dir "$N" --no-model --no-deploy 2>&1 | tee "$O/install_nomodel.txt" | tail -3
"$R/usr/bin/rime_deployer" --build "$N" "$S" >/dev/null 2>&1
{ python3 -I "$D/rime_driver.py" --root "$R" --shared "$S" --user "$N" --base "$N/cangjie3.base.dict.yaml" \
    --schema cangjie3_fluency --no-commit --quiet "${SEN[@]}"
  grep -c 'use grammar' "$N"/log/rime.cangjie-fluency-test.INFO || true; } 2>&1 | tee "$O/nomodel.txt"
