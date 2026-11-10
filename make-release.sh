#!/usr/bin/env bash
# Build the release zips of cangjie-fluency-linux.
#   usage: ./make-release.sh MAIN_REPO_CHECKOUT VERSION        e.g. ./make-release.sh ~/projects/cangjie-fluency v0.4.0
#   output: dist/cangjie-fluency-linux-VERSION-full.zip   everything needed offline (install.sh --offline works)
#           dist/cangjie-fluency-linux-VERSION-slim.zip   installer + schema files + converter; the rest is downloaded
#                                                         from the main repo (githubhjs/cangjie-fluency) at install time
# The bundle layout (what install.sh looks for next to itself): weasel/ tables/ data/ tools/
set -euo pipefail
[ $# -eq 2 ] || { sed -n '2,8p' "$0"; exit 2; }
MAIN="$(cd "$1" && pwd)"; VER="$2"
HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="cangjie-fluency-linux-$VER"
OUT="$HERE/dist"; mkdir -p "$OUT"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/cjf-rel.XXXXXX")"; trap 'rm -rf "$STAGE"' EXIT

need() { [ -f "$MAIN/$1" ] || { echo "missing in main repo checkout: $1" >&2; exit 1; }; }
for f in weasel/cangjie3_fluency.schema.yaml weasel/cangjie3_fluency.dict.yaml weasel/cangjie5_fluency.schema.yaml \
         weasel/cangjie5_fluency.dict.yaml weasel/cangjie3_fuzzy.schema.yaml weasel/cangjie3_fuzzy_prism.schema.yaml weasel/cangjie5_fuzzy.schema.yaml weasel/cangjie5_fuzzy_prism.schema.yaml weasel/fuzzy-narrow/cangjie3_fuzzy.schema.yaml weasel/fuzzy-narrow/cangjie3_fuzzy_prism.schema.yaml weasel/fuzzy-narrow/cangjie5_fuzzy.schema.yaml weasel/fuzzy-narrow/cangjie5_fuzzy_prism.schema.yaml weasel/fuzzy-wide/cangjie3_fuzzy.schema.yaml weasel/fuzzy-wide/cangjie3_fuzzy_prism.schema.yaml weasel/fuzzy-wide/cangjie5_fuzzy.schema.yaml weasel/fuzzy-wide/cangjie5_fuzzy_prism.schema.yaml tools/cin2rime.py tables/mscj3.cin tables/cangjie5.base.dict.yaml tables/SHA256SUMS \
         tables/README.md data/essay.txt data/zh-hant-t-essay-bgw.gram data/SHA256SUMS data/README.md; do need "$f"; done

# the hashes pinned in install.sh must match the files being shipped
check_pin() { # FILE
  local want got
  got="$(sha256sum "$MAIN/$1" | cut -d' ' -f1)"
  grep -q "$got" "$HERE/install.sh" || { echo "install.sh does not pin the SHA-256 of $1 ($got)" >&2; exit 1; }
}
for f in tables/mscj3.cin tables/cangjie5.base.dict.yaml data/essay.txt data/zh-hant-t-essay-bgw.gram; do check_pin "$f"; done

build() { # build full|slim
  local kind="$1" d
  d="$STAGE/$NAME-$kind/$NAME"
  mkdir -p "$d/weasel" "$d/tools"
  cp "$HERE/install.sh" "$HERE/README.md" "$HERE/LICENSE" "$d/"
  chmod +x "$d/install.sh"
  for f in cangjie3_fluency.schema.yaml cangjie3_fluency.dict.yaml cangjie5_fluency.schema.yaml cangjie5_fluency.dict.yaml \
           cangjie3_fuzzy.schema.yaml cangjie3_fuzzy_prism.schema.yaml cangjie5_fuzzy.schema.yaml cangjie5_fuzzy_prism.schema.yaml; do cp "$MAIN/weasel/$f" "$d/weasel/"; done
  for rg in narrow wide; do mkdir -p "$d/weasel/fuzzy-$rg"; for f in cangjie3_fuzzy.schema.yaml cangjie3_fuzzy_prism.schema.yaml cangjie5_fuzzy.schema.yaml cangjie5_fuzzy_prism.schema.yaml; do cp "$MAIN/weasel/fuzzy-$rg/$f" "$d/weasel/fuzzy-$rg/"; done; done
  cp "$MAIN/tools/cin2rime.py" "$d/tools/"
  if [ "$kind" = full ]; then
    mkdir -p "$d/tables" "$d/data"
    cp "$MAIN/tables/mscj3.cin" "$MAIN/tables/cangjie5.base.dict.yaml" "$MAIN/tables/SHA256SUMS" "$MAIN/tables/README.md" "$d/tables/"
    cp "$MAIN/data/essay.txt" "$MAIN/data/zh-hant-t-essay-bgw.gram" "$MAIN/data/SHA256SUMS" "$MAIN/data/README.md" "$d/data/"
  fi
  rm -f "$OUT/$NAME-$kind.zip"
  (cd "$STAGE/$NAME-$kind" && zip -q -r -X "$OUT/$NAME-$kind.zip" "$NAME")
  ls -l "$OUT/$NAME-$kind.zip" | awk '{print $5, $9}'
}
build full
build slim
(cd "$OUT" && sha256sum "$NAME-full.zip" "$NAME-slim.zip" > "$NAME.SHA256SUMS" && cat "$NAME.SHA256SUMS")
