#!/usr/bin/env bash
# cangjie-fluency-linux installer: Microsoft-style sentence input for Cangjie on Linux Rime
# (fcitx5-rime, fcitx-rime, ibus-rime).  Third-generation variant cangjie3_fluency by default.
#
#   curl -fsSL https://raw.githubusercontent.com/githubhjs/cangjie-fluency-linux/main/install.sh | bash
#
# Run as a normal user.  Never needs sudo; it only writes into the Rime user directory.
# Run  ./install.sh --help  for the options.
#
# The schema/dict files and tools/cin2rime.py are NOT kept in this repository: they are downloaded from
# https://github.com/githubhjs/cangjie-fluency at the pinned tag ($REF below).
# PIME's mscj3.cin has no licence header, so it is downloaded and converted on YOUR machine only.
set -euo pipefail

main() {

# ----------------------------------------------------------------------------------------- settings
REF="${CJF_REF:-v0.2.0}"
MAIN_REPO="githubhjs/cangjie-fluency"
CIN3_URL="https://raw.githubusercontent.com/EasyIME/PIME/master/python/cinbase/cin/mscj3.cin"
ESSAY_URL="https://raw.githubusercontent.com/rime/rime-essay/master/essay.txt"
GRAM_URL="https://github.com/lotem/rime-octagram-data/raw/hant/zh-hant-t-essay-bgw.gram"
GRAM_NAME="zh-hant-t-essay-bgw.gram"
GRAM_SIZE="${CJF_GRAM_SIZE:-41415724}"
CJ5_BASE_URL="https://raw.githubusercontent.com/rime/rime-cangjie/master/cangjie5.base.dict.yaml"
MANIFEST_NAME=".cangjie-fluency-linux.manifest"
TAG="[cangjie-fluency-linux]"

FRONTEND="auto"
RIME_DIR="${RIME_DIR:-}"
WITH_CJ5=0
NO_MODEL=0
NO_DEPLOY=0
DRY=0
UNINSTALL=0
REF_GIVEN=0
WARNINGS=0
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf '%s %s\n' "$TAG" "$*"; }
warn() { printf '%s WARNING: %s\n' "$TAG" "$*" >&2; WARNINGS=$((WARNINGS + 1)); }
die()  { printf '%s ERROR: %s\n' "$TAG" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: install.sh [options]

  --frontend fcitx5|fcitx|ibus|auto   which Rime front end to install for (default: auto-detect)
                                      also accepted: fcitx5-flatpak (path unverified)
  --rime-dir DIR                      Rime user directory (also env RIME_DIR); skips the front-end paths
  --ref TAG                           tag/branch of github.com/githubhjs/cangjie-fluency to download
                                      the schema files from (default: v0.2.0, env CJF_REF)
  --with-cangjie5                     also install cangjie5_fluency (5th generation)
  --no-model                          do not download the 41 MB language model (.gram)
  --no-deploy                         copy files only, do not restart/redeploy the input method
  --dry-run                           say what would be done, change nothing, download nothing
  --uninstall                         remove the files this installer created (backups are kept)
  -h, --help                          this text

Existing files are never overwritten silently: a changed file is first copied to NAME.bak-<time>.
Re-running with identical content changes nothing.
EOF
}

# ----------------------------------------------------------------------------------------- arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --frontend)       [ $# -ge 2 ] || die "--frontend needs a value"; FRONTEND="$2"; shift 2 ;;
    --frontend=*)     FRONTEND="${1#*=}"; shift ;;
    --rime-dir)       [ $# -ge 2 ] || die "--rime-dir needs a value"; RIME_DIR="$2"; shift 2 ;;
    --rime-dir=*)     RIME_DIR="${1#*=}"; shift ;;
    --ref)            [ $# -ge 2 ] || die "--ref needs a value"; REF="$2"; REF_GIVEN=1; shift 2 ;;
    --ref=*)          REF="${1#*=}"; REF_GIVEN=1; shift ;;
    --with-cangjie5)  WITH_CJ5=1; shift ;;
    --no-model)       NO_MODEL=1; shift ;;
    --no-deploy)      NO_DEPLOY=1; shift ;;
    --dry-run)        DRY=1; shift ;;
    --uninstall)      UNINSTALL=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    *)                usage >&2; die "unknown option: $1" ;;
  esac
done

case "$FRONTEND" in auto|fcitx5|fcitx|ibus|fcitx5-flatpak) ;; *) die "--frontend must be fcitx5, fcitx, ibus or auto" ;; esac
case "$REF" in *[!A-Za-z0-9._/-]*|"") die "--ref contains unexpected characters" ;; esac
[ "$(id -u)" -ne 0 ] || warn "running as root: the files would go into root's home. Run as your normal user."

# ----------------------------------------------------------------------------------------- front end + directory
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DIR_FCITX5="$DATA_HOME/fcitx5/rime"
DIR_FCITX5_FLATPAK="$HOME/.var/app/org.fcitx.Fcitx5/data/fcitx5/rime"   # unverified: not tested with Flatpak
DIR_FCITX="$CONF_HOME/fcitx/rime"
DIR_IBUS="$CONF_HOME/ibus/rime"

detect_frontend() {
  # 1. a running daemon wins, 2. an existing rime directory, 3. an installed program
  if have pgrep; then
    if pgrep -x fcitx5 >/dev/null 2>&1; then echo fcitx5; return; fi
    if pgrep -x ibus-daemon >/dev/null 2>&1 && { [ -d "$DIR_IBUS" ] || have ibus-daemon; }; then echo ibus; return; fi
    if pgrep -x fcitx >/dev/null 2>&1; then echo fcitx; return; fi
  fi
  if [ -d "$DIR_FCITX5" ]; then echo fcitx5; return; fi
  if [ -d "$DIR_IBUS" ]; then echo ibus; return; fi
  if [ -d "$DIR_FCITX" ]; then echo fcitx; return; fi
  if [ -d "$DIR_FCITX5_FLATPAK" ]; then echo fcitx5-flatpak; return; fi
  if have fcitx5; then echo fcitx5; return; fi
  if have ibus-daemon; then echo ibus; return; fi
  if have fcitx; then echo fcitx; return; fi
  echo none
}

if [ -z "$RIME_DIR" ]; then
  if [ "$FRONTEND" = auto ]; then
    FRONTEND="$(detect_frontend)"
    [ "$FRONTEND" != none ] || die "could not detect fcitx5 / fcitx / ibus. Use --frontend, or --rime-dir DIR."
    say "detected front end: $FRONTEND"
  fi
  case "$FRONTEND" in
    fcitx5)         RIME_DIR="$DIR_FCITX5" ;;
    fcitx5-flatpak) RIME_DIR="$DIR_FCITX5_FLATPAK" ;;
    fcitx)          RIME_DIR="$DIR_FCITX" ;;
    ibus)           RIME_DIR="$DIR_IBUS" ;;
  esac
elif [ "$FRONTEND" = auto ]; then
  FRONTEND="none"      # custom directory and no front end named: copy only, nothing to restart
fi
case "$RIME_DIR" in /*) ;; *) RIME_DIR="$PWD/$RIME_DIR" ;; esac
RIME_DIR="${RIME_DIR%/}"
MANIFEST="$RIME_DIR/$MANIFEST_NAME"
say "Rime user directory: $RIME_DIR (front end: $FRONTEND)"
[ "$DRY" -eq 0 ] || say "DRY RUN: nothing will be changed or downloaded."

# ----------------------------------------------------------------------------------------- helpers
WORK=""
cleanup() { [ -z "$WORK" ] || rm -rf "$WORK"; }
trap cleanup EXIT

file_size() { wc -c <"$1" | tr -d ' '; }

fetch() {   # fetch URL DEST   (CJF_MIRROR_DIR: local directory keyed by file name, for tests/offline use)
  local url="$1" dest="$2" base
  base="${url##*/}"
  if [ -n "${CJF_MIRROR_DIR:-}" ] && [ -f "$CJF_MIRROR_DIR/$base" ]; then
    cp "$CJF_MIRROR_DIR/$base" "$dest"
    return 0
  fi
  if have curl; then
    curl -fsSL --retry 3 --connect-timeout 20 -o "$dest" "$url"
  else
    wget -q -t 3 -T 20 -O "$dest" "$url"
  fi
}

manifest_add() {   # manifest_add LINE  (unique lines only)
  [ "$DRY" -eq 0 ] || return 0
  touch "$MANIFEST"
  grep -qxF -- "$1" "$MANIFEST" 2>/dev/null || printf '%s\n' "$1" >>"$MANIFEST"
}

# place_file SRC DESTNAME [--track]: identical -> nothing; changed -> one backup, then replace
place_file() {
  local src="$1" name="$2" dest="$RIME_DIR/$2"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    say "up to date: $name"
    return 0
  fi
  if [ -f "$dest" ]; then
    cp -p "$dest" "$dest.bak-$STAMP"
    say "backed up $name -> $name.bak-$STAMP"
  fi
  cp "$src" "$dest.cjf-part"
  mv -f "$dest.cjf-part" "$dest"
  manifest_add "$name"
  say "installed: $name"
}

# ----------------------------------------------------------------------------------------- uninstall
if [ "$UNINSTALL" -eq 1 ]; then
  [ -f "$MANIFEST" ] || { say "nothing to uninstall: no $MANIFEST_NAME in $RIME_DIR"; exit 0; }
  created_dc=0; merged_dc=0
  while IFS= read -r line; do
    case "$line" in
      "") ;;
      @created-default.custom.yaml) created_dc=1 ;;
      @merged-default.custom.yaml)  merged_dc=1 ;;
      */*|..*) warn "ignoring suspicious manifest entry: $line" ;;
      *)
        if [ -f "$RIME_DIR/$line" ]; then
          if [ "$DRY" -eq 1 ]; then say "DRY: would remove $line"; else rm -f "$RIME_DIR/$line"; say "removed: $line"; fi
        fi ;;
    esac
  done <"$MANIFEST"
  dc="$RIME_DIR/default.custom.yaml"
  if [ "$created_dc" -eq 1 ] && [ -f "$dc" ]; then
    if grep -q '^# created by cangjie-fluency-linux' "$dc"; then
      if [ "$DRY" -eq 1 ]; then say "DRY: would remove default.custom.yaml (created by this installer)"
      else rm -f "$dc"; say "removed: default.custom.yaml (it was created by this installer)"; fi
    else
      say "kept default.custom.yaml (it no longer looks like the file this installer created)"
    fi
  fi
  if [ "$merged_dc" -eq 1 ]; then
    say "default.custom.yaml was edited by this installer: delete the '- schema: cangjie3_fluency' (and cangjie5_fluency) lines yourself;"
    say "the pre-edit copy is default.custom.yaml.bak-<time> in $RIME_DIR."
  fi
  [ "$DRY" -eq 1 ] || rm -f "$MANIFEST"
  say "backups (*.bak-*) were kept. Compiled files in $RIME_DIR/build are regenerated on the next deploy."
  [ "$DRY" -eq 1 ] || say "Redeploy (see README) or restart the input method so the schema disappears from the menu."
  exit 0
fi

# ----------------------------------------------------------------------------------------- prerequisites
have python3 || die "python3 is required (it converts the Cangjie 3 table). Install it with your package manager."
if ! have curl && ! have wget; then die "curl or wget is required."; fi

find_octagram() {
  local d
  for d in /usr/lib/*/rime-plugins /usr/lib/rime-plugins /usr/lib64/rime-plugins /usr/local/lib/rime-plugins /usr/local/lib64/rime-plugins; do
    [ -f "$d/librime-octagram.so" ] && { echo "$d/librime-octagram.so"; return 0; }
  done
  if have ldconfig && ldconfig -p 2>/dev/null | grep -q 'librime-octagram'; then echo "(ldconfig)"; return 0; fi
  return 1
}

octagram_help() {
  cat >&2 <<'EOF'
    Without it the schema still works, but sentence correction is weaker.  Install the plugin:
      Debian / Ubuntu : sudo apt install librime-plugin-octagram        (package exists on Ubuntu 24.04, checked with apt-cache)
      Fedora          : sudo dnf install librime-octagram               (package exists in Fedora rawhide, checked via mdapi)
      Arch Linux      : nothing to install: the official librime package ships librime-octagram.so (checked in librime 1.17.0 file list)
      openSUSE, Gentoo, NixOS, Flatpak, others: unverified, look for a package called librime-octagram / rime-octagram
    Then restart the input method.  librime must load the plugin from its own rime-plugins directory.
EOF
}

if OCT="$(find_octagram)"; then
  say "octagram plugin found: $OCT"
elif [ "$NO_MODEL" -eq 1 ]; then
  say "octagram plugin not found (not needed with --no-model)."
else
  warn "librime-octagram plugin not found in the usual places."
  octagram_help
fi

# rime-data (default.yaml, luna_pinyin, ...) is needed by the schema (import_preset, reverse lookup)
SHARED_DIRS="/usr/share/rime-data /usr/local/share/rime-data /usr/share/fcitx5/rime-data /run/current-system/sw/share/rime-data"
shared_has() {   # shared_has FILE -> prints path of first match
  local d
  for d in "$RIME_DIR" $SHARED_DIRS; do
    [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }
  done
  return 1
}
if ! shared_has luna_pinyin.dict.yaml >/dev/null; then
  warn "rime-data (luna_pinyin, default.yaml) not found. Install it: Debian/Ubuntu 'librime-data' + 'librime-data-luna-pinyin' (checked names: librime-data); Fedora 'rime-data' (unverified); Arch 'librime-data'."
fi

# ----------------------------------------------------------------------------------------- source files
SRC_LOCAL=""
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; fi
for cand in "${CJF_SRC_DIR:-}" "$SCRIPT_DIR"; do
  [ -n "$cand" ] || continue
  if [ -f "$cand/weasel/cangjie3_fluency.schema.yaml" ] && [ -f "$cand/tools/cin2rime.py" ]; then
    if [ "$REF_GIVEN" -eq 0 ] || [ -n "${CJF_SRC_DIR:-}" ]; then SRC_LOCAL="$cand"; fi
    break
  fi
done
RAW="https://raw.githubusercontent.com/$MAIN_REPO/$REF"
if [ -n "$SRC_LOCAL" ]; then say "using local checkout of the main repo: $SRC_LOCAL"; else say "schema files come from $MAIN_REPO at $REF"; fi

if [ "$DRY" -eq 0 ]; then
  mkdir -p "$RIME_DIR"
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/cjf-linux.XXXXXX")"
fi

get_src() {   # get_src RELPATH_IN_MAIN_REPO DESTFILE
  if [ -n "$SRC_LOCAL" ]; then cp "$SRC_LOCAL/$1" "$2"; else fetch "$RAW/$1" "$2" || die "download failed: $RAW/$1"; fi
}

if [ "$DRY" -eq 1 ]; then
  say "DRY: would install cangjie3_fluency.schema.yaml, cangjie3_fluency.dict.yaml"
  say "DRY: would download tools/cin2rime.py and PIME mscj3.cin, then write cangjie3.base.dict.yaml (with essay.txt weights)"
  [ "$WITH_CJ5" -eq 0 ] || say "DRY: would install cangjie5_fluency.schema.yaml, cangjie5_fluency.dict.yaml, cangjie5.base.dict.yaml"
  [ "$NO_MODEL" -eq 1 ] || say "DRY: would download $GRAM_NAME ($GRAM_SIZE bytes) unless already present"
else
  # --- schema + dict (single source of truth: the main repo)
  for f in cangjie3_fluency.schema.yaml cangjie3_fluency.dict.yaml; do
    get_src "weasel/$f" "$WORK/$f"
    place_file "$WORK/$f" "$f"
  done
  get_src "tools/cin2rime.py" "$WORK/cin2rime.py"

  # --- essay.txt: needed by the converter (frequency weights) and by use_preset_vocabulary
  ESSAY=""
  if ESSAY="$(shared_has essay.txt)"; then
    say "essay.txt found: $ESSAY"
  else
    say "essay.txt not found in $RIME_DIR or /usr/share/rime-data: downloading rime-essay"
    fetch "$ESSAY_URL" "$WORK/essay.txt" || die "download failed: $ESSAY_URL"
    [ -s "$WORK/essay.txt" ] || die "essay.txt download is empty"
    place_file "$WORK/essay.txt" "essay.txt"
    ESSAY="$RIME_DIR/essay.txt"
  fi

  # --- 3rd generation table: PIME mscj3.cin, converted here, never stored in this repository
  say "downloading mscj3.cin from PIME and converting it (not redistributed, see README)"
  fetch "$CIN3_URL" "$WORK/mscj3.cin" || die "download failed: $CIN3_URL"
  [ -s "$WORK/mscj3.cin" ] || die "mscj3.cin download is empty"
  python3 -I "$WORK/cin2rime.py" "$WORK/mscj3.cin" "$WORK/cangjie3.base.dict.yaml" --essay "$ESSAY" >"$WORK/cin2rime.out" \
    || die "cin2rime.py failed"
  say "converter: $(tr '\n' ' ' <"$WORK/cin2rime.out")"
  place_file "$WORK/cangjie3.base.dict.yaml" "cangjie3.base.dict.yaml"

  # --- optional 5th generation
  if [ "$WITH_CJ5" -eq 1 ]; then
    for f in cangjie5_fluency.schema.yaml cangjie5_fluency.dict.yaml; do
      get_src "weasel/$f" "$WORK/$f"
      place_file "$WORK/$f" "$f"
    done
    fetch "$CJ5_BASE_URL" "$WORK/cangjie5.base.dict.yaml" || die "download failed: $CJ5_BASE_URL"
    [ -s "$WORK/cangjie5.base.dict.yaml" ] || die "cangjie5.base.dict.yaml download is empty"
    place_file "$WORK/cangjie5.base.dict.yaml" "cangjie5.base.dict.yaml"
  fi

  # --- language model
  if [ "$NO_MODEL" -eq 0 ]; then
    GRAM_DEST="$RIME_DIR/$GRAM_NAME"
    if [ -f "$GRAM_DEST" ] && [ "$(file_size "$GRAM_DEST")" = "$GRAM_SIZE" ]; then
      say "up to date: $GRAM_NAME (size $GRAM_SIZE)"
    else
      say "downloading $GRAM_NAME (~41 MB)"
      if fetch "$GRAM_URL" "$WORK/$GRAM_NAME" && [ "$(file_size "$WORK/$GRAM_NAME")" = "$GRAM_SIZE" ]; then
        place_file "$WORK/$GRAM_NAME" "$GRAM_NAME"
      else
        warn "$GRAM_NAME download failed or has the wrong size (want $GRAM_SIZE). Continuing without the language model; re-run later."
      fi
    fi
  else
    say "skipping the language model (--no-model)"
  fi
fi

# ----------------------------------------------------------------------------------------- default.custom.yaml
IDS="cangjie3_fluency"
[ "$WITH_CJ5" -eq 0 ] || IDS="$IDS cangjie5_fluency"
DC="$RIME_DIR/default.custom.yaml"

fresh_default_custom() {
  printf '%s\n' '# encoding: utf-8' '# created by cangjie-fluency-linux install.sh'
  printf '%s\n' '# patch/schema_list REPLACES the stock list, so keep the schemas you still want below.'
  printf '%s\n' 'patch:' '  schema_list:'
  local id
  for id in $IDS; do printf '    - schema: %s\n' "$id"; done
  printf '    - schema: luna_pinyin\n'
}

# merge_schema_list FILE OUT IDS...  exit 0 = OUT written with changes, 10 = nothing to add, 11 = no usable schema_list
merge_schema_list() {
  python3 -I - "$@" <<'PY'
import re, sys
path, out, ids = sys.argv[1], sys.argv[2], sys.argv[3:]
data = open(path, "rb").read()
crlf = b"\r\n" in data
lines = data.split(b"\n")            # a CRLF file keeps the \r at the end of each element
head = re.compile(rb'^(\s*)schema_list:[ \t]*(#.*)?\r?$')
idx = next((i for i, l in enumerate(lines) if head.match(l)), None)
if idx is None:
    sys.exit(11)
base_indent = len(head.match(lines[idx]).group(1))
item = re.compile(rb'^(\s*-\s+)(\{\s*)?schema:\s*[\'"]?([^\'"\s,}#]+)')
first = None          # index of first list item
listed = set()
style = None          # (prefix, brace)
i = idx + 1
while i < len(lines):
    l = lines[i].rstrip(b"\r")
    if l.strip() == b"" or l.lstrip().startswith(b"#"):
        i += 1
        continue
    ind = len(l) - len(l.lstrip())
    if ind <= base_indent and not l.lstrip().startswith(b"-"):
        break
    m = item.match(l)
    if m:
        if first is None:
            first = i
            style = (m.group(1), bool(m.group(2)))
        listed.add(m.group(3).decode())
    elif l.lstrip().startswith(b"-"):
        if first is None:
            first = i
            style = (re.match(rb'^(\s*-\s+)', l).group(1), False)
    i += 1
missing = [x for x in ids if x not in listed]
if not missing:
    sys.exit(10)
prefix, brace = style if style else (b" " * (base_indent + 2) + b"- ", False)
new = []
for x in missing:
    body = (b"{schema: " + x.encode() + b"}") if brace else (b"schema: " + x.encode())
    new.append(prefix + body)
if first is not None:
    pos = first
    ins = [n + (b"\r" if crlf else b"") for n in new]
    lines[pos:pos] = ins
else:
    pos = idx + 1
    cr = b"\r" if crlf else b""
    if pos >= len(lines):            # schema_list: was the last line and the file has no trailing newline
        lines[-1] += cr
        lines.extend([n + cr for n in new[:-1]] + [new[-1]])
    else:
        lines[pos:pos] = [n + cr for n in new]
open(out, "wb").write(b"\n".join(lines))
PY
}

dc_step() {
  if [ ! -e "$DC" ]; then
    if [ "$DRY" -eq 1 ]; then say "DRY: would create default.custom.yaml with: $IDS luna_pinyin"; return 0; fi
    fresh_default_custom >"$DC"
    manifest_add "@created-default.custom.yaml"
    say "created default.custom.yaml ($IDS first)"
    return 0
  fi
  local out rc=0
  out="$(mktemp "${TMPDIR:-/tmp}/cjf-dc.XXXXXX")"
  # shellcheck disable=SC2086
  merge_schema_list "$DC" "$out" $IDS || rc=$?
  case "$rc" in
    10) say "default.custom.yaml already lists $IDS: left untouched" ;;
    11)
      warn "default.custom.yaml has no block-style 'schema_list:', so I did not touch it. Add this under 'patch:' yourself:"
      printf '    schema_list:\n'
      for id in $IDS; do printf '      - schema: %s\n' "$id"; done
      printf '      # ...then the schemas you already use (a patched schema_list replaces the stock one)\n' ;;
    0)
      if [ "$DRY" -eq 1 ]; then say "DRY: would back up default.custom.yaml and insert $IDS at the top of its schema_list"
      else
        cp -p "$DC" "$DC.bak-$STAMP"
        say "backed up default.custom.yaml -> default.custom.yaml.bak-$STAMP"
        cp "$out" "$DC.cjf-part"; mv -f "$DC.cjf-part" "$DC"
        manifest_add "@merged-default.custom.yaml"
        say "inserted $IDS as first entr(y/ies) of your schema_list in default.custom.yaml"
      fi ;;
    *) warn "could not process default.custom.yaml (python exit $rc); left untouched" ;;
  esac
  rm -f "$out"
}
dc_step

# ----------------------------------------------------------------------------------------- deploy
deploy() {
  [ "$DRY" -eq 0 ] || { say "DRY: would deploy (front end: $FRONTEND)"; return 0; }
  [ "$NO_DEPLOY" -eq 0 ] || { say "--no-deploy: not restarting the input method."; return 0; }
  case "$FRONTEND" in
    fcitx5)
      if have fcitx5-remote; then
        if fcitx5-remote -r >/dev/null 2>&1; then say "ran: fcitx5-remote -r (reload)"; else warn "fcitx5-remote -r failed; is fcitx5 running?"; fi
        say "If the schema does not appear or still looks old, restart Fcitx5 fully (or pick 'Deploy' in the Rime tray menu)."
      else
        warn "fcitx5-remote not found; restart Fcitx5 yourself, then choose Deploy in the Rime tray menu."
      fi ;;
    fcitx5-flatpak) say "Flatpak Fcitx5: restart it yourself (path and method unverified), then choose Deploy in the Rime tray menu." ;;
    fcitx)
      if have fcitx-remote; then
        if fcitx-remote -r >/dev/null 2>&1; then say "ran: fcitx-remote -r (reload)"; else warn "fcitx-remote -r failed"; fi
        say "If it does not pick up the schema, choose Deploy in the fcitx-rime menu or restart fcitx."
      else warn "fcitx-remote not found; restart fcitx yourself."; fi ;;
    ibus)
      if have ibus; then
        if ibus restart >/dev/null 2>&1; then say "ran: ibus restart (unverified: if the schema is missing, use Deploy in the ibus-rime menu)"; else warn "ibus restart failed"; fi
      else warn "ibus not found; restart ibus yourself (ibus-daemon -drx)."; fi ;;
    none) say "custom directory, no front end named: not restarting anything. Redeploy from your input method's menu." ;;
  esac
}
deploy

# ----------------------------------------------------------------------------------------- finish
if [ "$DRY" -eq 1 ]; then
  say "dry run finished; nothing was changed."
else
  say "Done. Switch to the schema with Ctrl+\` (or F4) and pick 'cangjie3_fluency'."
  say "Check the language model: grep -h 'use grammar' in the Rime log (see README) should show $GRAM_NAME."
  [ "$WARNINGS" -eq 0 ] || say "finished with $WARNINGS warning(s), see above."
fi

}   # end of main

main "$@"
