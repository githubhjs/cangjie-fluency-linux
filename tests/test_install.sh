#!/usr/bin/env bash
# Tests for install.sh. Offline: a throwaway Rime dir, a stubbed front end on PATH and a fake "mirror"
# directory that stands in for every download (fetch() reads CJF_MIRROR_DIR/<file name> first).
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

# ---- fake mirror + stubbed front ends
MIRROR="$T/mirror"; STUB="$T/stub"; mkdir -p "$MIRROR" "$STUB"
printf 'schema:\n  schema_id: cangjie3_fluency\n' >"$MIRROR/cangjie3_fluency.schema.yaml"
printf -- '---\nname: cangjie3_fluency\n...\n' >"$MIRROR/cangjie3_fluency.dict.yaml"
printf 'schema:\n  schema_id: cangjie5_fluency\n' >"$MIRROR/cangjie5_fluency.schema.yaml"
printf -- '---\nname: cangjie5_fluency\n...\n' >"$MIRROR/cangjie5_fluency.dict.yaml"
printf -- '---\nname: cangjie5.base\n...\nx\tabc\t1\n' >"$MIRROR/cangjie5.base.dict.yaml"
printf '%s\n' '%chardef begin' 'a 日' '%chardef end' >"$MIRROR/mscj3.cin"
printf '中\t100\n' >"$MIRROR/essay.txt"
printf 'x' >"$MIRROR/zh-hant-t-essay-bgw.gram"
# fake converter: records its arguments, so the test can see that --essay was passed
cat >"$MIRROR/cin2rime.py" <<'PY'
import sys
a = sys.argv[1:]
open(a[1], "w").write("# fake dict from %s args=%s\n" % (open(a[0]).read().strip().replace("\n", "|"), " ".join(x for x in a[2:3])))
print("written: 1")
PY
for c in fcitx5-remote fcitx-remote ibus; do
  printf '#!/bin/sh\necho "%s $*" >>"%s/calls.log"\n' "$c" "$T" >"$STUB/$c"
  chmod +x "$STUB/$c"
done

run() {   # run RIMEDIR args... ; output in $T/out
  local d="$1"; shift
  env -u RIME_DIR CJF_MIRROR_DIR="$MIRROR" CJF_GRAM_SIZE=1 PATH="$STUB:$PATH" \
    bash "$INSTALL" --frontend fcitx5 --rime-dir "$d" "$@" >"$T/out" 2>&1
}
nbak() { find "$1" -maxdepth 1 -name '*.bak-*' | wc -l | tr -d ' '; }
has()  { grep -qF -- "$1" "$T/out"; }

# ================================================================== fresh install
D="$T/r1"
run "$D"; rc=$?
check "fresh: exit 0" test "$rc" -eq 0
for f in cangjie3_fluency.schema.yaml cangjie3_fluency.dict.yaml cangjie3.base.dict.yaml zh-hant-t-essay-bgw.gram essay.txt default.custom.yaml; do
  check "fresh: $f exists" test -f "$D/$f"
done
check "fresh: cangjie5 not installed without --with-cangjie5" test ! -e "$D/cangjie5_fluency.schema.yaml"
check "fresh: converter got --essay" grep -q 'args=--essay' "$D/cangjie3.base.dict.yaml"
check "fresh: default.custom.yaml lists cangjie3_fluency first" \
  test "$(grep -m1 -- '- schema:' "$D/default.custom.yaml")" = "    - schema: cangjie3_fluency"
check "fresh: no backups" test "$(nbak "$D")" = 0
check "fresh: deploy command ran" grep -q 'fcitx5-remote -r' "$T/calls.log"
check "fresh: no .cjf-part left" test -z "$(find "$D" -name '*.cjf-part')"

# ================================================================== identical re-run
before="$(cd "$D" && find . -type f -printf '%p %s %T@\n' | sort | md5sum)"
sleep 1
run "$D"; rc=$?
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
want=$'# my config\npatch:\n  schema_list:\n    - schema: cangjie3_fluency\n    - schema: luna_pinyin\n    - schema: cangjie5\n  menu/page_size: 7\n'
check "merge LF: inserted first, rest untouched" test "$(cat "$d/default.custom.yaml"; echo x)" = "${want}x"
check "merge LF: one backup of default.custom.yaml" test "$(find "$d" -maxdepth 1 -name "default.custom.yaml.bak-*" | wc -l | tr -d " ")" = 1
check "merge LF: backup is the original" cmp -s "$T/dc_in" "$d"/default.custom.yaml.bak-*
run "$d"
check "merge LF: second run adds nothing" test "$(grep -c 'schema: cangjie3_fluency' "$d/default.custom.yaml")" = 1
check "merge LF: second run no extra backup" test "$(find "$d" -maxdepth 1 -name "default.custom.yaml.bak-*" | wc -l | tr -d " ")" = 1

# existing list, CRLF, no trailing newline (what Weasel-style editors produce)
printf 'patch:\r\n  schema_list:\r\n    - schema: luna_pinyin\r\n    - schema: cangjie5' >"$T/dc_in"
d="$(dc_case crlf)"; run "$d"
want=$'patch:\r\n  schema_list:\r\n    - schema: cangjie3_fluency\r\n    - schema: luna_pinyin\r\n    - schema: cangjie5'
check "merge CRLF: CRLF kept, no trailing newline added" cmp -s <(printf '%s' "$want") "$d/default.custom.yaml"
check "merge CRLF: no bare LF introduced" test "$(grep -c $'[^\r]$' "$d/default.custom.yaml")" = 1   # only the last line has no CR

# brace style
printf 'patch:\n  schema_list:\n    - {schema: luna_pinyin}\n    - {schema: cangjie5}\n' >"$T/dc_in"
d="$(dc_case brace)"; run "$d"
check "merge brace: brace style used" grep -qx '    - {schema: cangjie3_fluency}' "$d/default.custom.yaml"
check "merge brace: it is the first entry" test "$(grep -m1 -- '- ' "$d/default.custom.yaml")" = "    - {schema: cangjie3_fluency}"
check "merge brace: other entries unchanged" test "$(grep -c '{schema: ' "$d/default.custom.yaml")" = 3

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
printf 'patch:\n  schema_list:\n    - schema: luna_pinyin\n    - schema: cangjie3_fluency\n' >"$T/dc_in"
d="$(dc_case listed)"; run "$d"
check "already listed: file untouched" cmp -s "$T/dc_in" "$d/default.custom.yaml"
check "already listed: no backup" test "$(find "$d" -maxdepth 1 -name "default.custom.yaml.bak-*" | wc -l | tr -d " ")" = 0

# only cangjie5_fluency listed: exact-id match, so cangjie3_fluency must still be added
printf 'patch:\n  schema_list:\n    - schema: cangjie5_fluency\n' >"$T/dc_in"
d="$(dc_case only5)"; run "$d"
want=$'patch:\n  schema_list:\n    - schema: cangjie3_fluency\n    - schema: cangjie5_fluency\n'
check "only cangjie5_fluency listed: cangjie3_fluency added first" test "$(cat "$d/default.custom.yaml"; echo x)" = "${want}x"

# missing file is created (already covered by fresh install) - also with --with-cangjie5
d="$T/c5"; run "$d" --with-cangjie5 --no-model
check "with-cangjie5: files installed" test -f "$d/cangjie5_fluency.schema.yaml" -a -f "$d/cangjie5.base.dict.yaml"
check "with-cangjie5: both listed, cangjie3 first" \
  test "$(grep -- '- schema:' "$d/default.custom.yaml" | head -2 | tr -d ' \n')" = "-schema:cangjie3_fluency-schema:cangjie5_fluency"
check "no-model: gram not installed" test ! -e "$d/zh-hant-t-essay-bgw.gram"

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
env -u RIME_DIR CJF_MIRROR_DIR="$MIRROR" CJF_GRAM_SIZE=1 PATH="$STUB:$PATH" bash "$INSTALL" --frontend ibus --rime-dir "$d" --no-model >"$T/out" 2>&1
check "ibus: runs 'ibus restart'" grep -q '^ibus restart' "$T/calls.log"
: >"$T/calls.log"; d="$T/nodeploy"; run "$d" --no-deploy --no-model
check "no-deploy: no command run" test ! -s "$T/calls.log"
env -u RIME_DIR bash "$INSTALL" --frontend bogus >"$T/out" 2>&1; rc=$?
check "bad --frontend rejected" test "$rc" -ne 0
d="$T/envdir"; env RIME_DIR="$d" CJF_MIRROR_DIR="$MIRROR" PATH="$STUB:$PATH" bash "$INSTALL" --no-deploy --no-model >"$T/out" 2>&1
check "RIME_DIR env honoured" test -f "$d/cangjie3_fluency.schema.yaml"
check "mscj3.cin and generated table are git-ignored" test "$(git -C "$HERE/.." check-ignore mscj3.cin cangjie3.base.dict.yaml testenv/x/cangjie3.base.dict.yaml | wc -l | tr -d ' ')" = 3

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
