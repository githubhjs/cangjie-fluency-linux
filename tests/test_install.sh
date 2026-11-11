#!/usr/bin/env bash
# Tests for install.sh. Offline: a throwaway Rime dir, stubbed front ends on PATH, and the main repo checkout as the
# bundle (CJF_SRC_DIR); the real tables, essay.txt and language model are used, with their SHA-256 checks.
# usage: bash tests/test_install.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL="$HERE/../install.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/cjf-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0

ok()   { PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; }
check() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }

# ---- real bundle = checkout of the main repo (same layout as the full release zip), stubbed front ends
SRC="${CJF_MAIN_REPO:-/home/hjs/projects/cangjie-fluency}"
STUB="$T/stub"; mkdir -p "$STUB"
export RIME_SHARED_DIRS="$T/no-system-rime-data"   # the result must not depend on what the machine has installed
export XDG_DATA_HOME="$T/data"
export CJF_BIN_DIR="$T/bin"

# Prepare mock sweep-pad zip in bundle
SWEEP_STUB="$T/sweep_src"; mkdir -p "$SWEEP_STUB"
cat >"$SWEEP_STUB/cangjie_sweep_pad.py" <<'PY'
#!/usr/bin/env python3
import sys
if "--self-check" in sys.argv:
    print("self-check ok")
    sys.exit(0)
print("cangjie sweep pad")
PY
chmod +x "$SWEEP_STUB/cangjie_sweep_pad.py"
(cd "$SWEEP_STUB" && zip -q -r "$T/cangjie-sweep-pad.zip" cangjie_sweep_pad.py)
sha256sum "$T/cangjie-sweep-pad.zip" | awk '{print $1}' > "$T/cangjie-sweep-pad.zip.sha256"

BUNDLE="$T/bundle"; mkdir -p "$BUNDLE/sweep-pad"
ln -s "$SRC/weasel" "$BUNDLE/weasel"
ln -s "$SRC/tables" "$BUNDLE/tables"
ln -s "$SRC/data" "$BUNDLE/data"
ln -s "$SRC/tools" "$BUNDLE/tools"
cp "$T/cangjie-sweep-pad.zip" "$BUNDLE/sweep-pad/cangjie-sweep-pad.zip"
cp "$T/cangjie-sweep-pad.zip.sha256" "$BUNDLE/sweep-pad/cangjie-sweep-pad.zip.sha256"
SRC="$BUNDLE"
for c in fcitx5-remote fcitx-remote ibus; do
  printf '#!/bin/sh\necho "%s $*" >>"%s/calls.log"\n' "$c" "$T" >"$STUB/$c"
  chmod +x "$STUB/$c"
done

run() {   # run RIMEDIR args... ; output in $T/out
  local d="$1"; shift
  env -u RIME_DIR CJF_SRC_DIR="$SRC" PATH="$STUB:$PATH" \
    bash "$INSTALL" --no-deps --frontend fcitx5 --rime-dir "$d" $([ "${FULL:-0}" = 1 ] || echo --no-model) "$@" >"$T/out" 2>&1
}
nbak() { find "$1" -maxdepth 1 -name '*.bak-*' | wc -l | tr -d ' '; }
has()  { grep -qF -- "$1" "$T/out"; }

# ================================================================== fresh install
D="$T/r1"
FULL=1 run "$D"; rc=$?
check "fresh: exit 0" test "$rc" -eq 0
for f in cangjie3_fluency.schema.yaml cangjie3_fluency.dict.yaml cangjie3.base.dict.yaml zh-hant-t-essay-bgw.gram essay.txt default.custom.yaml; do
  check "fresh: $f exists" test -f "$D/$f"
done
check "fresh: cangjie5 not installed without --with-cangjie5" test ! -e "$D/cangjie5_fluency.schema.yaml"
check "fresh: table identical to the python converter output with the repo essay.txt" sh -c "python3 -I '$SRC/tools/cin2rime.py' '$SRC/tables/mscj3.cin' '$T/py.yaml' --essay '$SRC/data/essay.txt' >/dev/null && cmp -s '$T/py.yaml' '$D/cangjie3.base.dict.yaml'"
check "fresh: default.custom.yaml lists cangjie3_fluency first" \
  test "$(grep -m1 -- '- schema:' "$D/default.custom.yaml")" = "    - schema: cangjie3_fluency"
check "fresh: no backups" test "$(nbak "$D")" = 0
check "fresh: deploy command ran" grep -q 'fcitx5-remote -r' "$T/calls.log"
check "fresh: no .cjf-part left" test -z "$(find "$D" -name '*.cjf-part')"
check "fresh: sweep pad installed" test -f "$T/data/cangjie-sweep/cangjie_sweep_pad.py"
check "fresh: sweep launcher executable" test -x "$T/bin/cangjie-sweep-pad"
check "fresh: sweep desktop entry exists" test -f "$T/data/applications/cangjie-sweep-pad.desktop"
check "fresh: sweep self-check reported" has "Sweep Pad self-check passed"

# ================================================================== identical re-run
before="$(cd "$D" && find . -type f -printf '%p %s %T@\n' | sort | md5sum)"
sleep 1
FULL=1 run "$D"; rc=$?
after="$(cd "$D" && find . -type f -printf '%p %s %T@\n' | sort | md5sum)"
check "rerun: exit 0" test "$rc" -eq 0
check "rerun: no backups" test "$(nbak "$D")" = 0
check "rerun: nothing rewritten (same names, sizes, mtimes)" test "$before" = "$after"
check "rerun: says up to date" has "up to date: cangjie3_fluency.schema.yaml"

# ================================================================== changed file re-run
echo "# user edit" >>"$D/cangjie3_fluency.schema.yaml"
run "$D"; rc=$?
check "changed: exactly one backup" test "$(nbak "$D")" = 1
check "changed: backup holds the edited file" grep -q 'user edit' "$D"/cangjie3_fluency.schema.yaml.bak-*
check "changed: file restored from source" test -z "$(grep 'user edit' "$D/cangjie3_fluency.schema.yaml")"
run "$D"
check "changed: third run adds no further backup" test "$(nbak "$D")" = 1

# ================================================================== default.custom.yaml merge cases
dc_case() {   # dc_case NAME  (content in $T/dc_in)  -> dir $T/m_NAME with that default.custom.yaml
  local d="$T/m_$1"; mkdir -p "$d"; cp "$T/dc_in" "$d/default.custom.yaml"; echo "$d"
}
sum() { md5sum <"$1" | cut -d' ' -f1; }

# existing list, LF
printf '# my config\npatch:\n  schema_list:\n    - schema: luna_pinyin\n    - schema: cangjie5\n  menu/page_size: 7\n' >"$T/dc_in"
d="$(dc_case lf)"; run "$d"
want=$'# my config\npatch:\n  schema_list:\n    - schema: cangjie3_fluency\n    - schema: cangjie3_fuzzy\n    - schema: luna_pinyin\n    - schema: cangjie5\n  menu/page_size: 7\n'
check "merge LF: inserted first, rest untouched" test "$(cat "$d/default.custom.yaml"; echo x)" = "${want}x"
check "merge LF: one backup of default.custom.yaml" test "$(find "$d" -maxdepth 1 -name "default.custom.yaml.bak-*" | wc -l | tr -d " ")" = 1
check "merge LF: backup is the original" cmp -s "$T/dc_in" "$d"/default.custom.yaml.bak-*
run "$d"
check "merge LF: second run adds nothing" test "$(grep -c 'schema: cangjie3_fluency' "$d/default.custom.yaml")" = 1
check "merge LF: second run no extra backup" test "$(find "$d" -maxdepth 1 -name "default.custom.yaml.bak-*" | wc -l | tr -d " ")" = 1

# existing list, CRLF, no trailing newline (what Weasel-style editors produce)
printf 'patch:\r\n  schema_list:\r\n    - schema: luna_pinyin\r\n    - schema: cangjie5' >"$T/dc_in"
d="$(dc_case crlf)"; run "$d"
want=$'patch:\r\n  schema_list:\r\n    - schema: cangjie3_fluency\r\n    - schema: cangjie3_fuzzy\r\n    - schema: luna_pinyin\r\n    - schema: cangjie5'
check "merge CRLF: CRLF kept, no trailing newline added" cmp -s <(printf '%s' "$want") "$d/default.custom.yaml"
check "merge CRLF: no bare LF introduced" test "$(grep -c $'[^\r]$' "$d/default.custom.yaml")" = 1   # only the last line has no CR

# brace style
printf 'patch:\n  schema_list:\n    - {schema: luna_pinyin}\n    - {schema: cangjie5}\n' >"$T/dc_in"
d="$(dc_case brace)"; run "$d"
check "merge brace: brace style used" grep -qx '    - {schema: cangjie3_fluency}' "$d/default.custom.yaml"
check "merge brace: it is the first entry" test "$(grep -m1 -- '- ' "$d/default.custom.yaml")" = "    - {schema: cangjie3_fluency}"
check "merge brace: other entries unchanged" test "$(grep -c '{schema: ' "$d/default.custom.yaml")" = 4

check "merge brace: fuzzy is second, in brace style" test "$(grep -- '- ' "$d/default.custom.yaml" | sed -n 2p)" = "    - {schema: cangjie3_fuzzy}"

# different indentation (4 spaces under patch, 6 for items)
printf 'patch:\n    schema_list:\n          - schema: luna_pinyin\n' >"$T/dc_in"
d="$(dc_case indent)"; run "$d"
check "merge indent: item indentation preserved" grep -qx '          - schema: cangjie3_fluency' "$d/default.custom.yaml"

# no schema_list: file must stay byte-identical, message printed
printf 'patch:\n  menu/page_size: 7\n' >"$T/dc_in"
d="$(dc_case nolist)"; run "$d"
check "no schema_list: file untouched" cmp -s "$T/dc_in" "$d/default.custom.yaml"
check "no schema_list: no backup" test "$(find "$d" -maxdepth 1 -name "default.custom.yaml.bak-*" | wc -l | tr -d " ")" = 0
check "no schema_list: tells what to add" has "- schema: cangjie3_fluency"

# already listed
printf 'patch:\n  schema_list:\n    - schema: luna_pinyin\n    - schema: cangjie3_fluency\n    - schema: cangjie3_fuzzy\n' >"$T/dc_in"
d="$(dc_case listed)"; run "$d"
check "already listed: file untouched" cmp -s "$T/dc_in" "$d/default.custom.yaml"
check "already listed: no backup" test "$(find "$d" -maxdepth 1 -name "default.custom.yaml.bak-*" | wc -l | tr -d " ")" = 0

# only cangjie5_fluency listed: exact-id match, so cangjie3_fluency must still be added
printf 'patch:\n  schema_list:\n    - schema: cangjie5_fluency\n' >"$T/dc_in"
d="$(dc_case only5)"; run "$d"
want=$'patch:\n  schema_list:\n    - schema: cangjie3_fluency\n    - schema: cangjie3_fuzzy\n    - schema: cangjie5_fluency\n'
check "only cangjie5_fluency listed: cangjie3_fluency added first" test "$(cat "$d/default.custom.yaml"; echo x)" = "${want}x"

# missing file is created (already covered by fresh install) - also with --with-cangjie5
d="$T/c5"; run "$d" --with-cangjie5 --no-model
check "with-cangjie5: files installed" test -f "$d/cangjie5_fluency.schema.yaml" -a -f "$d/cangjie5.base.dict.yaml"
check "with-cangjie5: both listed, cangjie3 first" \
  test "$(grep -- '- schema:' "$d/default.custom.yaml" | head -4 | tr -d ' \n')" = "-schema:cangjie3_fluency-schema:cangjie3_fuzzy-schema:cangjie5_fluency-schema:cangjie5_fuzzy"
check "no-model: gram not installed" test ! -e "$d/zh-hant-t-essay-bgw.gram"

# ================================================================== fuzzy: files, order, options
d="$T/fz1"; run "$d" --no-model --with-cangjie5
for f in cangjie3_fuzzy.schema.yaml cangjie3_fuzzy_prism.schema.yaml cangjie5_fuzzy.schema.yaml cangjie5_fuzzy_prism.schema.yaml; do
  check "fuzzy: $f installed byte-identical to the repo copy" cmp -s "$SRC/weasel/$f" "$d/$f"
done
d="$T/fz2"; run "$d" --no-model --with-cangjie5 --fuzzy-default
check "--fuzzy-default fresh: fuzzy first" test "$(grep -- '- schema:' "$d/default.custom.yaml" | head -4 | tr -d ' \n')" = "-schema:cangjie3_fuzzy-schema:cangjie5_fuzzy-schema:cangjie3_fluency-schema:cangjie5_fluency"
printf 'patch:\n  schema_list:\n    - schema: cangjie3_fluency\n    - schema: luna_pinyin\n' >"$T/dc_in"
d="$(dc_case fzdef)"; run "$d" --fuzzy-default
check "--fuzzy-default existing list: fuzzy inserted at the top" test "$(grep -- '- schema:' "$d/default.custom.yaml" | tr -d ' \n')" = "-schema:cangjie3_fuzzy-schema:cangjie3_fluency-schema:luna_pinyin"
check "--fuzzy-default: the closing message names cangjie3_fuzzy as the default" has "The default schema is 'cangjie3_fuzzy'"
printf 'patch:\n  schema_list:\n    - schema: cangjie3_fluency\n    - schema: luna_pinyin\n' >"$T/dc_in"
d="$(dc_case fzdefault_fluency)"; run "$d"
check "default existing list: fuzzy right after fluency, fluency stays default" test "$(grep -- '- schema:' "$d/default.custom.yaml" | tr -d ' \n')" = "-schema:cangjie3_fluency-schema:cangjie3_fuzzy-schema:luna_pinyin"
d="$T/fz3"; run "$d" --no-model --no-fuzzy
check "--no-fuzzy: no fuzzy files" test -z "$(find "$d" -name '*fuzzy*')"
check "--no-fuzzy: list has no fuzzy id" test -z "$(grep fuzzy "$d/default.custom.yaml")"

# ================================================================== fuzzy range
for rg in narrow wide; do
  d="$T/rg_$rg"; run "$d" --no-model --with-cangjie5 --fuzzy-range $rg
  for f in cangjie3_fuzzy.schema.yaml cangjie3_fuzzy_prism.schema.yaml cangjie5_fuzzy.schema.yaml cangjie5_fuzzy_prism.schema.yaml; do
    check "--fuzzy-range $rg: $f is the $rg copy" cmp -s "$SRC/weasel/fuzzy-$rg/$f" "$d/$f"
  done
  check "--fuzzy-range $rg: fluency files untouched by the range" cmp -s "$SRC/weasel/cangjie3_fluency.schema.yaml" "$d/cangjie3_fluency.schema.yaml"
done
check "fuzzy range: narrow and wide differ from the default" test "$(cmp -s "$SRC/weasel/fuzzy-narrow/cangjie3_fuzzy_prism.schema.yaml" "$SRC/weasel/cangjie3_fuzzy_prism.schema.yaml"; echo $?)" = 1
d="$T/rg_bad"; run "$d" --no-model --fuzzy-range huge; rc=$?
check "--fuzzy-range huge is refused" test "$rc" -ne 0

# ================================================================== dry run
d="$T/dry"
run "$d" --dry-run; rc=$?
check "dry-run: exit 0" test "$rc" -eq 0
check "dry-run: directory not even created" test ! -e "$d"
d="$T/dry2"; mkdir -p "$d"; printf 'patch:\n  schema_list:\n    - schema: luna_pinyin\n' >"$d/default.custom.yaml"
before="$(cd "$d" && find . -type f | sort | xargs md5sum | md5sum)"
: >"$T/calls.log"
run "$d" --dry-run
after="$(cd "$d" && find . -type f | sort | xargs md5sum | md5sum)"
check "dry-run: existing dir unchanged" test "$before" = "$after"
check "dry-run: no deploy command" test ! -s "$T/calls.log"
check "dry-run: says what it would do" has "DRY: would"
check "dry-run: mentions Sweep Pad by default" has "DRY: would install Sweep Pad"
d="$T/dry_nosweep"; run "$d" --dry-run --no-sweep
check "dry-run --no-sweep: skips Sweep Pad" has "skipping Sweep Pad (--no-sweep)"
check "dry-run --no-sweep: does not mention would install Sweep Pad" sh -c "! grep -q 'would install Sweep Pad' '$T/out'"

# ================================================================== uninstall
D="$T/r1"           # fresh install + one changed-file backup from above
echo "# user file" >"$D/my-own.yaml"
run "$D" --uninstall; rc=$?
check "uninstall: exit 0" test "$rc" -eq 0
for f in cangjie3_fluency.schema.yaml cangjie3_fluency.dict.yaml cangjie3.base.dict.yaml zh-hant-t-essay-bgw.gram essay.txt default.custom.yaml; do
  check "uninstall: $f removed" test ! -e "$D/$f"
done
check "uninstall: backup kept" test "$(nbak "$D")" = 1
check "uninstall: user's own file kept" test -f "$D/my-own.yaml"
check "uninstall: manifest removed" test ! -e "$D/.cangjie-fluency-linux.manifest"
check "uninstall: sweep dir removed" test ! -e "$T/data/cangjie-sweep"
check "uninstall: sweep launcher removed" test ! -e "$T/bin/cangjie-sweep-pad"
check "uninstall: sweep desktop entry removed" test ! -e "$T/data/applications/cangjie-sweep-pad.desktop"

# uninstall must keep a default.custom.yaml that was merely edited, and files it did not create
d="$T/m_lf"; echo "# pre-existing" >"$d/mine.yaml"
run "$d" --uninstall
check "uninstall merged: default.custom.yaml kept" test -f "$d/default.custom.yaml"
check "uninstall merged: backup kept" test "$(find "$d" -maxdepth 1 -name "default.custom.yaml.bak-*" | wc -l | tr -d " ")" = 1
check "uninstall merged: tells user to remove the line" has "delete the '- schema: cangjie3_fluency'"
check "uninstall merged: installed files gone" test ! -e "$d/cangjie3_fluency.schema.yaml"

d="$T/empty"; mkdir -p "$d"; run "$d" --uninstall
check "uninstall without manifest: harmless" has "nothing to uninstall"

# ================================================================== misc
d="$T/ibus"; : >"$T/calls.log"
env -u RIME_DIR CJF_SRC_DIR="$SRC" PATH="$STUB:$PATH" bash "$INSTALL" --no-deps --frontend ibus --rime-dir "$d" --no-model >"$T/out" 2>&1
check "ibus: runs 'ibus restart'" grep -q '^ibus restart' "$T/calls.log"
: >"$T/calls.log"; d="$T/nodeploy"; run "$d" --no-deploy --no-model
check "no-deploy: no command run" test ! -s "$T/calls.log"
env -u RIME_DIR bash "$INSTALL" --frontend bogus >"$T/out" 2>&1; rc=$?
check "bad --frontend rejected" test "$rc" -ne 0
d="$T/envdir"; env RIME_DIR="$d" CJF_SRC_DIR="$SRC" PATH="$STUB:$PATH" bash "$INSTALL" --no-deps --no-deploy --no-model >"$T/out" 2>&1
check "RIME_DIR env honoured" test -f "$d/cangjie3_fluency.schema.yaml"
check "mscj3.cin and generated table are git-ignored" test "$(git -C "$HERE/.." check-ignore mscj3.cin cangjie3.base.dict.yaml testenv/x/cangjie3.base.dict.yaml | wc -l | tr -d ' ')" = 3

# ================================================================== no third party, no network, hashes
check "install.sh has no third-party URL" sh -c "! grep -Eqi 'EasyIME|PIME|rime/rime-|lotem/|Homebrew|winget' '$INSTALL'"
NETLOG="$T/net.log"; : >"$NETLOG"
for c in curl wget; do printf '#!/bin/sh
echo "%s $*" >>"%s"
exit 22
' "$c" "$NETLOG" >"$STUB/$c"; chmod +x "$STUB/$c"; done
d="$T/offline"; FULL=1 run "$d" --offline; rc=$?
check "offline full bundle: exit 0" test "$rc" -eq 0
check "offline full bundle: model installed" test "$(wc -c <"$d/zh-hant-t-essay-bgw.gram" | tr -d ' ')" = 41415724
check "offline full bundle: ZERO network calls (curl/wget stubs never invoked)" test ! -s "$NETLOG"
check "offline full bundle: table byte-identical to python converter" cmp -s "$T/py.yaml" "$d/cangjie3.base.dict.yaml"
d="$T/offline_nobundle"
env -u RIME_DIR -u CJF_SRC_DIR PATH="$STUB:$PATH" bash "$INSTALL" --offline --no-deps --frontend fcitx5 --rime-dir "$d" >"$T/out" 2>&1; rc=$?
check "offline without bundle: fails clearly" test "$rc" -ne 0
check "offline without bundle: message" has "--offline"
check "offline without bundle: still zero network calls" test ! -s "$NETLOG"
# online path really tries the main repo raw URL (stubs fail, so the install must stop)
d="$T/online_nobundle"
env -u RIME_DIR -u CJF_SRC_DIR PATH="$STUB:$PATH" bash "$INSTALL" --no-deps --frontend fcitx5 --rime-dir "$d" --ref main >"$T/out" 2>&1; rc=$?
check "online without bundle: curl called with the main repo raw URL" grep -q 'raw.githubusercontent.com/githubhjs/cangjie-fluency/main/weasel/cangjie3_fluency.schema.yaml' "$NETLOG"
check "online without bundle: only the main repo is contacted" test -z "$(grep -v 'githubhjs/cangjie-fluency' "$NETLOG")"
# damaged table: SHA-256 mismatch must stop the install before anything is converted
BAD="$T/badbundle"; mkdir -p "$BAD"; cp -r "$SRC/weasel" "$SRC/tools" "$SRC/data" "$BAD/"; mkdir -p "$BAD/tables"; cp "$SRC/tables/mscj3.cin" "$BAD/tables/"; echo 'x 日' >>"$BAD/tables/mscj3.cin"; ln -s "$BUNDLE/sweep-pad" "$BAD/sweep-pad"
d="$T/badhash"
env -u RIME_DIR CJF_SRC_DIR="$BAD" PATH="$STUB:$PATH" bash "$INSTALL" --offline --no-deps --no-model --frontend fcitx5 --rime-dir "$d" >"$T/out" 2>&1; rc=$?
check "bad table hash: install stops" test "$rc" -ne 0
check "bad table hash: says SHA-256 mismatch" has "SHA-256 mismatch"
check "bad table hash: no generated table" test ! -e "$d/cangjie3.base.dict.yaml"
# essay.txt: not installed when a system copy exists, but the table is still built from the repo copy
SYS="$T/sysrime"; mkdir -p "$SYS"; printf '中	1
' >"$SYS/essay.txt"
d="$T/sysessay"; RIME_SHARED_DIRS="$SYS" run "$d"
check "system essay.txt present: not copied to the user dir" test ! -e "$d/essay.txt"
check "system essay.txt present: table still from repo essay (identical)" cmp -s "$T/py.yaml" "$d/cangjie3.base.dict.yaml"
# engine packages: stubbed apt-get/sudo/dpkg; nothing real is installed
: >"$T/pm.log"
for c in apt-get sudo; do printf '#!/bin/sh
echo "%s $*" >>"%s"
' "$c" "$T/pm.log" >"$STUB/$c"; chmod +x "$STUB/$c"; done
d="$T/deps"
env -u RIME_DIR CJF_SRC_DIR="$SRC" CJF_ENGINE_ROOTS="$T/none" RIME_SHARED_DIRS="$T/none" PATH="$STUB:$PATH" bash "$INSTALL" --frontend ibus --rime-dir "$d" --no-model --dry-run >"$T/out" 2>&1
check "deps dry-run (ibus, no model): names the ibus-rime install, runs nothing" sh -c "grep -q 'DRY: would run: sudo apt-get install -y ibus-rime' '$T/out' && [ ! -s '$T/pm.log' ]"
env -u RIME_DIR CJF_SRC_DIR="$SRC" CJF_ENGINE_ROOTS="$T/none" RIME_SHARED_DIRS="$T/none" PATH="$STUB:$PATH" bash "$INSTALL" --frontend ibus --rime-dir "$d" --no-model --no-deploy >"$T/out" 2>&1
check "deps: apt-get install of ibus-rime via sudo" grep -q '^sudo apt-get install -y ibus-rime' "$T/pm.log"
: >"$T/pm.log"
env -u RIME_DIR CJF_SRC_DIR="$SRC" CJF_ENGINE_ROOTS="$T/none" RIME_SHARED_DIRS="$T/none" PATH="$STUB:$PATH" bash "$INSTALL" --no-deps --frontend ibus --rime-dir "$d" --no-model --no-deploy >"$T/out" 2>&1
check "--no-deps: package manager not called" test ! -s "$T/pm.log"
rm -f "$STUB/curl" "$STUB/wget" "$STUB/apt-get" "$STUB/sudo"

# ================================================================== sweep pad: hash mismatch & offline
FAKE_PAD="$T/fake_pad_rel"; mkdir -p "$FAKE_PAD"
echo "corrupt data" > "$FAKE_PAD/cangjie-sweep-pad-v0.3.0.zip"
echo "0000000000000000000000000000000000000000000000000000000000000000  cangjie-sweep-pad-v0.3.0.zip" > "$FAKE_PAD/cangjie-sweep-pad-v0.3.0.zip.sha256"
d="$T/bad_pad_hash"
CJF_PAD_URL_BASE="$FAKE_PAD" env -u CJF_SRC_DIR -u RIME_DIR PATH="$STUB:$PATH" \
  bash "$INSTALL" --frontend fcitx5 --rime-dir "$d" --no-deps --no-model >"$T/out" 2>&1; rc=$?
check "sweep pad bad hash: install stops" test "$rc" -ne 0
check "sweep pad bad hash: says SHA-256 mismatch" has "SHA-256 mismatch"

NO_PAD_BUNDLE="$T/bundle_nopad"; mkdir -p "$NO_PAD_BUNDLE"
ln -s "$BUNDLE/weasel" "$NO_PAD_BUNDLE/weasel"
ln -s "$BUNDLE/tables" "$NO_PAD_BUNDLE/tables"
ln -s "$BUNDLE/data" "$NO_PAD_BUNDLE/data"
ln -s "$BUNDLE/tools" "$NO_PAD_BUNDLE/tools"
d="$T/offline_nopad"
env -u RIME_DIR CJF_SRC_DIR="$NO_PAD_BUNDLE" PATH="$STUB:$PATH" \
  bash "$INSTALL" --offline --no-deps --frontend fcitx5 --rime-dir "$d" --no-model >"$T/out" 2>&1; rc=$?
check "offline without sweep-pad in bundle stops" test "$rc" -ne 0
check "offline without sweep-pad message" has "sweep-pad/cangjie-sweep-pad.zip is missing"

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
