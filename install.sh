#!/usr/bin/env bash
# cangjie-fluency-linux installer: Microsoft-style sentence input for Cangjie on Linux Rime
# (fcitx5-rime, fcitx-rime, ibus-rime).  Third-generation variant cangjie3_fluency by default.
#
#   curl -fsSL https://raw.githubusercontent.com/githubhjs/cangjie-fluency-linux/main/install.sh | bash
#
# Run as a normal user.  Never needs sudo; it only writes into the Rime user directory.
# Run  ./install.sh --help  for the options.
#
# Everything comes from the owner's main repository https://github.com/githubhjs/cangjie-fluency
# (schema files, code tables, word list, language model, converter) and nothing from any other third party:
#   1. files next to this script, in the layout of the full release zip (weasel/ tables/ data/ tools/), else
#   2. the same files from raw.githubusercontent.com/githubhjs/cangjie-fluency/<ref>/ (unless --offline).
# Tables, word list and language model are SHA-256 checked.  Engine packages (ibus-rime / fcitx5-rime +
# librime-octagram) are installed with your distribution's own package manager (sudo), unless --no-deps.
set -euo pipefail

main() {

# ----------------------------------------------------------------------------------------- settings
REF="${CJF_REF:-v0.5.0}"
MAIN_REPO="githubhjs/cangjie-fluency"
GRAM_NAME="zh-hant-t-essay-bgw.gram"
GRAM_SIZE=41415724
GRAM_SHA="0488ebd6688f900a39200f2b794f2f99bcbf1e8fc27280ae4a2324b08b1559c1"
ESSAY_SHA="3e8512ebaa6657e35961b1f5762060717c647e3bf471d5e3b86e783b4e934ffb"
CIN3_SHA="a7b3d03898dc0b2b0bd7803ad0be7b940a1ed945ac5d6314ed832b1dbf6839a2"
CJ5_BASE_SHA="0b7a801720bbf04cea06c55577c159e2e67b9bbb763bf00026a8520497772799"
MANIFEST_NAME=".cangjie-fluency-linux.manifest"
TAG="[cangjie-fluency-linux]"

FRONTEND="auto"
RIME_DIR="${RIME_DIR:-}"
WITH_CJ5=0
NO_FUZZY=0
FUZZY_RANGE=normal
FUZZY_DEFAULT=0
NO_MODEL=0
NO_DEPLOY=0
NO_DEPS=0
OFFLINE=0
DRY=0
UNINSTALL=0
WARNINGS=0
STAMP="$(date +%Y%m%d-%H%M%S)"

# Each takes the English message, plus an optional Traditional Chinese line ($2) printed right after it.
say()  { printf '%s %s\n' "$TAG" "$1"; if [ $# -ge 2 ]; then printf '%s %s\n' "$TAG" "$2"; fi; }
warn() { printf '%s WARNING: %s\n' "$TAG" "$1" >&2; if [ $# -ge 2 ]; then printf '%s 警告：%s\n' "$TAG" "$2" >&2; fi; WARNINGS=$((WARNINGS + 1)); }
die()  { printf '%s ERROR: %s\n' "$TAG" "$1" >&2; if [ $# -ge 2 ]; then printf '%s 錯誤：%s\n' "$TAG" "$2" >&2; fi; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: install.sh [options]

  --frontend fcitx5|fcitx|ibus|auto   which Rime front end to install for (default: auto-detect)
                                      also accepted: fcitx5-flatpak (path unverified)
  --rime-dir DIR                      Rime user directory (also env RIME_DIR); skips the front-end paths
  --ref TAG                           tag/branch of github.com/githubhjs/cangjie-fluency to download
                                      missing files from (default: v0.5.0, env CJF_REF)
  --offline                           never touch the network: every file must be next to this script
                                      (full release zip layout), otherwise the install stops
  --no-deps                           do not install ibus-rime / fcitx5-rime / librime-plugin-octagram
                                      with the system package manager
  --with-cangjie5                     also install cangjie5_fluency (5th generation)
  --no-model                          do not install the 41 MB language model (.gram)
  --no-fuzzy                          do not install the adjacent-key typo tolerance schemas (cangjie3_fuzzy)
  --fuzzy-default                     make the typo-tolerant schema the FIRST (default) one instead of cangjie3_fluency
  --fuzzy-range narrow|normal|wide    how far a wrong key may be from the right one: narrow = left/right only,
                                      normal (default) = also the diagonal neighbours, wide = one more ring
  --no-deploy                         copy files only, do not restart/redeploy the input method
  --dry-run                           say what would be done, change nothing, download nothing
  --uninstall                         remove the files this installer created (backups are kept)
  -h, --help                          this text

Existing files are never overwritten silently: a changed file is first copied to NAME.bak-<time>.
Re-running with identical content changes nothing.
EOF
  cat <<'EOF_ZH'

用法：install.sh [選項]

  --frontend fcitx5|fcitx|ibus|auto   要為哪個 Rime 輸入法框架安裝（預設：自動偵測）
                                      也接受 fcitx5-flatpak（路徑未驗證）
  --rime-dir DIR                      Rime 使用者資料夾（也可用環境變數 RIME_DIR）；會略過框架的預設路徑
  --ref TAG                           從 github.com/githubhjs/cangjie-fluency 下載缺少檔案時使用的
                                      標籤/分支（預設：v0.5.0，環境變數 CJF_REF）
  --offline                           完全不連網：所有檔案都必須放在本腳本旁邊
                                      （完整 release zip 的版面配置），否則安裝會中止
  --no-deps                           不用系統套件管理員安裝 ibus-rime / fcitx5-rime / librime-plugin-octagram
  --with-cangjie5                     同時安裝 cangjie5_fluency（五代）
  --no-model                          不安裝 41 MB 的語言模型（.gram）
  --no-fuzzy                          不安裝相鄰鍵容錯方案（cangjie3_fuzzy）
  --fuzzy-default                     把鄰鍵容錯方案排在第一個（預設），而不是 cangjie3_fluency
  --fuzzy-range narrow|normal|wide    打錯的鍵離正確的鍵多遠算數：narrow = 只有左右相鄰，
                                      normal（預設）= 再加斜向相鄰，wide = 再多一圈
  --no-deploy                         只複製檔案，不重新啟動/重新部署輸入法
  --dry-run                           只說明會做什麼，不更動、不下載
  --uninstall                         移除本安裝程式建立的檔案（備份檔會保留）
  -h, --help                          顯示本說明

既有檔案絕不會被悄悄覆蓋：有變動的檔案會先複製成 NAME.bak-<時間>。
內容相同時重複執行不會有任何變動。
EOF_ZH
}

# ----------------------------------------------------------------------------------------- arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --frontend)       [ $# -ge 2 ] || die "--frontend needs a value" "--frontend 需要一個值"; FRONTEND="$2"; shift 2 ;;
    --frontend=*)     FRONTEND="${1#*=}"; shift ;;
    --rime-dir)       [ $# -ge 2 ] || die "--rime-dir needs a value" "--rime-dir 需要一個值"; RIME_DIR="$2"; shift 2 ;;
    --rime-dir=*)     RIME_DIR="${1#*=}"; shift ;;
    --ref)            [ $# -ge 2 ] || die "--ref needs a value" "--ref 需要一個值"; REF="$2"; shift 2 ;;
    --ref=*)          REF="${1#*=}"; shift ;;
    --offline)        OFFLINE=1; shift ;;
    --no-deps)        NO_DEPS=1; shift ;;
    --with-cangjie5)  WITH_CJ5=1; shift ;;
    --no-model)       NO_MODEL=1; shift ;;
    --no-fuzzy)       NO_FUZZY=1; shift ;;
    --fuzzy-default)  FUZZY_DEFAULT=1; shift ;;
    --fuzzy-range)    FUZZY_RANGE="${2:-}"; case "$FUZZY_RANGE" in narrow|normal|wide) ;; *) die "--fuzzy-range must be narrow, normal or wide" "--fuzzy-range 只能是 narrow、normal 或 wide" ;; esac; shift 2 ;;
    --no-deploy)      NO_DEPLOY=1; shift ;;
    --dry-run)        DRY=1; shift ;;
    --uninstall)      UNINSTALL=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    *)                usage >&2; die "unknown option: $1" "不認得的選項：$1" ;;
  esac
done

case "$FRONTEND" in auto|fcitx5|fcitx|ibus|fcitx5-flatpak) ;; *) die "--frontend must be fcitx5, fcitx, ibus or auto" "--frontend 必須是 fcitx5、fcitx、ibus 或 auto" ;; esac
case "$REF" in *[!A-Za-z0-9._/-]*|"") die "--ref contains unexpected characters" "--ref 含有不允許的字元" ;; esac
[ "$(id -u)" -ne 0 ] || warn "running as root: the files would go into root's home. Run as your normal user." "目前以 root 身分執行：檔案會放進 root 的家目錄。請改用一般使用者執行。"

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
    if [ "$FRONTEND" = none ]; then
      [ "$NO_DEPS" -eq 0 ] || die "could not detect fcitx5 / fcitx / ibus. Use --frontend, or --rime-dir DIR." "偵測不到 fcitx5 / fcitx / ibus。請用 --frontend 指定，或用 --rime-dir DIR。"
      # nothing installed yet: ibus is the default input framework of GNOME/Ubuntu, fcitx5 is the usual one on KDE
      case "${XDG_CURRENT_DESKTOP:-}" in *KDE*|*kde*|*Plasma*) FRONTEND=fcitx5 ;; *) FRONTEND=ibus ;; esac
      say "no front end found; will install $FRONTEND (desktop: ${XDG_CURRENT_DESKTOP:-unknown}). Use --frontend to choose another." "找不到輸入法框架；將安裝 $FRONTEND（桌面環境：${XDG_CURRENT_DESKTOP:-unknown}）。要選別的請用 --frontend。"
    else
      say "detected front end: $FRONTEND" "偵測到輸入法框架：$FRONTEND"
    fi
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
say "Rime user directory: $RIME_DIR (front end: $FRONTEND)" "Rime 使用者資料夾：$RIME_DIR（輸入法框架：$FRONTEND）"
[ "$DRY" -eq 0 ] || say "DRY RUN: nothing will be changed or downloaded." "試跑模式：不會更動或下載任何東西。"

# ----------------------------------------------------------------------------------------- helpers
WORK=""
cleanup() { [ -z "$WORK" ] || rm -rf "$WORK"; }
trap cleanup EXIT

file_size() { wc -c <"$1" | tr -d ' '; }

sha256_of() {   # sha256_of FILE -> hex digest (sha256sum, shasum, openssl, python3)
  if have sha256sum; then sha256sum "$1" | cut -d' ' -f1
  elif have shasum; then shasum -a 256 "$1" | cut -d' ' -f1
  elif have openssl; then openssl dgst -sha256 "$1" | sed 's/^.*= *//'
  else python3 -I -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$1"
  fi
}

verify_sha() {  # verify_sha FILE EXPECTED LABEL
  local got
  got="$(sha256_of "$1")"
  [ "$got" = "$2" ] || die "$3: SHA-256 mismatch (got $got, expected $2). The file is damaged or the wrong version; nothing was installed from it." "$3：SHA-256 不符（實際 $got，預期 $2）。檔案損毀或版本不對；沒有安裝這個檔案的任何內容。"
}

fetch() {   # fetch URL DEST   (never called with --offline)
  local url="$1" dest="$2"
  [ "$OFFLINE" -eq 0 ] || die "internal error: network access attempted with --offline ($url)" "內部錯誤：使用 --offline 時卻嘗試連網（$url）"
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
    say "up to date: $name" "已是最新：$name"
    return 0
  fi
  if [ -f "$dest" ]; then
    cp -p "$dest" "$dest.bak-$STAMP"
    say "backed up $name -> $name.bak-$STAMP" "已備份：$name -> $name.bak-$STAMP"
  fi
  cp "$src" "$dest.cjf-part"
  mv -f "$dest.cjf-part" "$dest"
  manifest_add "$name"
  say "installed: $name" "已安裝：$name"
}

# ----------------------------------------------------------------------------------------- uninstall
if [ "$UNINSTALL" -eq 1 ]; then
  [ -f "$MANIFEST" ] || { say "nothing to uninstall: no $MANIFEST_NAME in $RIME_DIR" "沒有東西可解除安裝：$RIME_DIR 裡沒有 $MANIFEST_NAME"; exit 0; }
  created_dc=0; merged_dc=0
  while IFS= read -r line; do
    case "$line" in
      "") ;;
      @created-default.custom.yaml) created_dc=1 ;;
      @merged-default.custom.yaml)  merged_dc=1 ;;
      */*|..*) warn "ignoring suspicious manifest entry: $line" "略過可疑的清單項目：$line" ;;
      *)
        if [ -f "$RIME_DIR/$line" ]; then
          if [ "$DRY" -eq 1 ]; then say "DRY: would remove $line" "試跑：將會移除 $line"; else rm -f "$RIME_DIR/$line"; say "removed: $line" "已移除：$line"; fi
        fi ;;
    esac
  done <"$MANIFEST"
  dc="$RIME_DIR/default.custom.yaml"
  if [ "$created_dc" -eq 1 ] && [ -f "$dc" ]; then
    if grep -q '^# created by cangjie-fluency-linux' "$dc"; then
      if [ "$DRY" -eq 1 ]; then say "DRY: would remove default.custom.yaml (created by this installer)" "試跑：將會移除 default.custom.yaml（由本安裝程式建立）"
      else rm -f "$dc"; say "removed: default.custom.yaml (it was created by this installer)" "已移除：default.custom.yaml（由本安裝程式建立）"; fi
    else
      say "kept default.custom.yaml (it no longer looks like the file this installer created)" "保留 default.custom.yaml（它已不像是本安裝程式建立的檔案）"
    fi
  fi
  if [ "$merged_dc" -eq 1 ]; then
    say "default.custom.yaml was edited by this installer: delete the '- schema: cangjie3_fluency' (and cangjie5_fluency) lines yourself;" "default.custom.yaml 曾被本安裝程式修改：請自行刪除「- schema: cangjie3_fluency」（以及 cangjie5_fluency）那幾行；"
    say "the pre-edit copy is default.custom.yaml.bak-<time> in $RIME_DIR." "修改前的備份是 $RIME_DIR 裡的 default.custom.yaml.bak-<時間>。"
  fi
  [ "$DRY" -eq 1 ] || rm -f "$MANIFEST"
  say "backups (*.bak-*) were kept. Compiled files in $RIME_DIR/build are regenerated on the next deploy." "備份檔（*.bak-*）已保留。$RIME_DIR/build 裡的編譯檔會在下次部署時重新產生。"
  [ "$DRY" -eq 1 ] || say "Redeploy (see README) or restart the input method so the schema disappears from the menu." "請重新部署（見 README）或重新啟動輸入法，讓方案從選單消失。"
  exit 0
fi

# ----------------------------------------------------------------------------------------- prerequisites
have python3 || die "python3 is required (it converts the Cangjie 3 table). Install it with your package manager." "需要 python3（用來轉換倉頡三代碼表）。請用套件管理員安裝。"
if [ "$OFFLINE" -eq 0 ] && ! have curl && ! have wget; then die "curl or wget is required (or use --offline with the full release zip)." "需要 curl 或 wget（或用完整 release zip 搭配 --offline）。"; fi

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

# ---- engine packages (the distribution's own package manager; skipped with --no-deps or --rime-dir-only use)
engine_installed() {   # engine_installed ibus|fcitx5
  case "$1" in
    ibus)   [ -n "$(find ${CJF_ENGINE_ROOTS:-/usr/lib /usr/lib64 /usr/libexec /usr/local/lib /usr/local/libexec} -maxdepth 3 -name ibus-engine-rime 2>/dev/null | head -n 1)" ] ;;
    fcitx5) [ -n "$(find ${CJF_ENGINE_ROOTS:-/usr/lib /usr/lib64 /usr/local/lib /usr/local/lib64} -maxdepth 3 -path '*fcitx5*' -name rime.so 2>/dev/null | head -n 1)" ] ;;
    *) return 0 ;;
  esac
}

install_deps() {
  local want_engine=0 pm pkgs="" cmd
  case "$FRONTEND" in none|fcitx|fcitx5-flatpak) say "front end '$FRONTEND': not installing engine packages automatically." "輸入法框架「$FRONTEND」：不自動安裝引擎套件。"; return 0 ;; esac
  case "$FRONTEND" in ibus|fcitx5) engine_installed "$FRONTEND" || want_engine=1 ;; esac
  local want_plugin=0
  if [ "$NO_MODEL" -eq 0 ] && ! find_octagram >/dev/null 2>&1; then want_plugin=1; fi
  [ "$want_engine" -eq 1 ] || [ "$want_plugin" -eq 1 ] || { say "engine packages already present." "引擎套件已安裝。"; return 0; }
  if have apt-get; then
    pm=apt                                                    # package names checked with apt-cache on Ubuntu 24.04
    [ "$want_engine" -eq 0 ] || { [ "$FRONTEND" = ibus ] && pkgs="ibus-rime" || pkgs="fcitx5-rime"; }
    [ "$want_plugin" -eq 0 ] || pkgs="$pkgs librime-plugin-octagram"
    cmd="apt-get install -y $pkgs"
  elif have dnf; then
    pm=dnf                                                    # unverified names
    [ "$want_engine" -eq 0 ] || { [ "$FRONTEND" = ibus ] && pkgs="ibus-rime" || pkgs="fcitx5-rime"; }
    [ "$want_plugin" -eq 0 ] || pkgs="$pkgs librime-octagram"
    cmd="dnf install -y $pkgs"
  elif have pacman; then
    pm=pacman                                                 # unverified names; librime ships the octagram plugin
    [ "$want_engine" -eq 0 ] || { [ "$FRONTEND" = ibus ] && pkgs="ibus-rime" || pkgs="fcitx5-rime"; }
    [ -n "$pkgs" ] || { say "pacman: the librime package already provides the octagram plugin." "pacman：librime 套件已內含 octagram 外掛。"; return 0; }
    cmd="pacman -S --needed --noconfirm $pkgs"
  elif have zypper; then
    pm=zypper                                                 # unverified names
    [ "$want_engine" -eq 0 ] || { [ "$FRONTEND" = ibus ] && pkgs="ibus-rime" || pkgs="fcitx5-rime"; }
    [ "$want_plugin" -eq 0 ] || pkgs="$pkgs librime-octagram"
    cmd="zypper --non-interactive install $pkgs"
  else
    warn "no known package manager (apt/dnf/pacman/zypper); install the Rime engine and librime-octagram yourself." "找不到已知的套件管理員（apt/dnf/pacman/zypper）；請自行安裝 Rime 引擎與 librime-octagram。"
    return 0
  fi
  pkgs="${pkgs# }"
  if [ "$DRY" -eq 1 ]; then say "DRY: would run: sudo $cmd   ($pm)" "試跑：將會執行：sudo $cmd   ($pm)"; return 0; fi
  if [ "$(id -u)" -eq 0 ]; then
    say "installing with $pm: $pkgs" "用 $pm 安裝：$pkgs"; $cmd || warn "package installation failed: $cmd" "套件安裝失敗：$cmd"
  elif have sudo; then
    say "installing with $pm (sudo asks for your password): $pkgs" "用 $pm 安裝（sudo 會要求輸入密碼）：$pkgs"
    # shellcheck disable=SC2086
    sudo $cmd || warn "package installation failed or was cancelled. Run it yourself: sudo $cmd" "套件安裝失敗或被取消。請自行執行：sudo $cmd"
  else
    warn "sudo not found. Run as root: $cmd" "找不到 sudo。請以 root 執行：$cmd"
  fi
}
if [ "$NO_DEPS" -eq 1 ]; then say "--no-deps: not installing engine packages." "--no-deps：不安裝引擎套件。"; else install_deps; fi

if OCT="$(find_octagram)"; then
  say "octagram plugin found: $OCT" "找到 octagram 外掛：$OCT"
elif [ "$NO_MODEL" -eq 1 ]; then
  say "octagram plugin not found (not needed with --no-model)." "找不到 octagram 外掛（使用 --no-model 時不需要）。"
else
  warn "librime-octagram plugin not found in the usual places." "在常見位置找不到 librime-octagram 外掛。"
  octagram_help
fi

# rime-data (default.yaml, luna_pinyin, ...) is needed by the schema (import_preset, reverse lookup)
SHARED_DIRS="${RIME_SHARED_DIRS:-/usr/share/rime-data /usr/local/share/rime-data /usr/share/fcitx5/rime-data /run/current-system/sw/share/rime-data}"   # RIME_SHARED_DIRS overrides (tests)
shared_has() {   # shared_has FILE -> prints path of first match
  local d
  for d in "$RIME_DIR" $SHARED_DIRS; do
    [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }
  done
  return 1
}
if ! shared_has luna_pinyin.dict.yaml >/dev/null; then
  warn "rime-data (luna_pinyin, default.yaml) not found. Install it: Debian/Ubuntu 'librime-data' + 'librime-data-luna-pinyin' (checked names: librime-data); Fedora 'rime-data' (unverified); Arch 'librime-data'." "找不到 rime-data（luna_pinyin、default.yaml）。請安裝：Debian/Ubuntu 的 'librime-data' + 'librime-data-luna-pinyin'（已確認的名稱：librime-data）；Fedora 的 'rime-data'（未驗證）；Arch 的 'librime-data'。"
fi

# ----------------------------------------------------------------------------------------- source files
SRC_LOCAL=""
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; fi
for cand in "${CJF_SRC_DIR:-}" "$SCRIPT_DIR"; do   # CJF_SRC_DIR: any directory with the bundle layout (e.g. a checkout of the main repo)
  [ -n "$cand" ] || continue
  if [ -f "$cand/weasel/cangjie3_fluency.schema.yaml" ] && [ -f "$cand/tools/cin2rime.py" ]; then SRC_LOCAL="$cand"; break; fi
done
RAW="https://raw.githubusercontent.com/$MAIN_REPO/$REF"
if [ -n "$SRC_LOCAL" ]; then
  say "using the files next to the installer (bundle layout): $SRC_LOCAL" "使用安裝程式旁邊的檔案（完整包版面配置）：$SRC_LOCAL"
elif [ "$OFFLINE" -eq 1 ]; then
  die "--offline: the files (weasel/ tables/ data/ tools/) must be next to install.sh (use the full release zip)." "--offline：檔案（weasel/ tables/ data/ tools/）必須放在 install.sh 旁邊（請使用完整 release zip）。"
else
  say "files come from $MAIN_REPO at $REF" "檔案來自 $MAIN_REPO（版本 $REF）"
fi

if [ "$DRY" -eq 0 ]; then
  mkdir -p "$RIME_DIR"
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/cjf-linux.XXXXXX")"
fi

get_src() {   # get_src RELPATH_IN_MAIN_REPO DESTFILE [SHA256]: bundle copy first, else download (not with --offline)
  if [ -n "$SRC_LOCAL" ] && [ -f "$SRC_LOCAL/$1" ]; then
    cp "$SRC_LOCAL/$1" "$2"
  elif [ "$OFFLINE" -eq 1 ]; then
    die "--offline: $1 is missing from the bundle" "--offline：完整包裡缺少 $1"
  else
    fetch "$RAW/$1" "$2" || die "download failed: $RAW/$1" "下載失敗：$RAW/$1"
  fi
  [ -s "$2" ] || die "$1 is empty" "$1 是空的"
  if [ -n "${3:-}" ]; then verify_sha "$2" "$3" "$1"; fi
}

if [ "$DRY" -eq 1 ]; then
  say "DRY: would install cangjie3_fluency.schema.yaml, cangjie3_fluency.dict.yaml" "試跑：將會安裝 cangjie3_fluency.schema.yaml、cangjie3_fluency.dict.yaml"
  say "DRY: would convert tables/mscj3.cin (SHA-256 checked) with tools/cin2rime.py and data/essay.txt weights -> cangjie3.base.dict.yaml" "試跑：將會用 tools/cin2rime.py 與 data/essay.txt 的權重轉換 tables/mscj3.cin（已檢查 SHA-256）-> cangjie3.base.dict.yaml"
  [ "$WITH_CJ5" -eq 0 ] || say "DRY: would install cangjie5_fluency.schema.yaml, cangjie5_fluency.dict.yaml, cangjie5.base.dict.yaml" "試跑：將會安裝 cangjie5_fluency.schema.yaml、cangjie5_fluency.dict.yaml、cangjie5.base.dict.yaml"
  [ "$NO_MODEL" -eq 1 ] || say "DRY: would install $GRAM_NAME ($GRAM_SIZE bytes, SHA-256 checked) unless already present" "試跑：將會安裝 $GRAM_NAME（$GRAM_SIZE 位元組，已檢查 SHA-256），若已存在則略過"
else
  # --- schema + dict (single source of truth: the main repo)
  FILES3="cangjie3_fluency.schema.yaml cangjie3_fluency.dict.yaml"
  [ "$NO_FUZZY" -eq 1 ] || FILES3="$FILES3 cangjie3_fuzzy.schema.yaml cangjie3_fuzzy_prism.schema.yaml"
  for f in $FILES3; do
    rel="weasel/$f"; case "$f" in *_fuzzy*) [ "$FUZZY_RANGE" = normal ] || rel="weasel/fuzzy-$FUZZY_RANGE/$f" ;; esac
    get_src "$rel" "$WORK/$f"
    place_file "$WORK/$f" "$f"
  done
  get_src "tools/cin2rime.py" "$WORK/cin2rime.py"

  # --- essay.txt: the repository's pinned copy ALWAYS feeds the converter (identical output on every platform);
  #     it is installed into the user directory only when no system copy exists.
  get_src "data/essay.txt" "$WORK/essay.txt" "$ESSAY_SHA"
  SYS_ESSAY=""
  for d in $SHARED_DIRS; do [ -f "$d/essay.txt" ] && { SYS_ESSAY="$d/essay.txt"; break; }; done
  if [ -n "$SYS_ESSAY" ]; then
    say "system essay.txt found ($SYS_ESSAY): not installing another copy" "找到系統的 essay.txt（$SYS_ESSAY）：不再安裝另一份"
  elif [ -f "$RIME_DIR/essay.txt" ]; then
    say "essay.txt already in $RIME_DIR: left alone" "$RIME_DIR 裡已有 essay.txt：不動它"
  else
    place_file "$WORK/essay.txt" "essay.txt"
  fi

  # --- 3rd generation table (tables/mscj3.cin of the main repo, SHA-256 checked), converted here
  get_src "tables/mscj3.cin" "$WORK/mscj3.cin" "$CIN3_SHA"
  python3 -I "$WORK/cin2rime.py" "$WORK/mscj3.cin" "$WORK/cangjie3.base.dict.yaml" --essay "$WORK/essay.txt" >"$WORK/cin2rime.out" \
    || die "cin2rime.py failed" "cin2rime.py 執行失敗"
  say "converter: $(tr '\n' ' ' <"$WORK/cin2rime.out")" "轉換器輸出：$(tr '\n' ' ' <"$WORK/cin2rime.out")"
  place_file "$WORK/cangjie3.base.dict.yaml" "cangjie3.base.dict.yaml"

  # --- optional 5th generation
  if [ "$WITH_CJ5" -eq 1 ]; then
    FILES5="cangjie5_fluency.schema.yaml cangjie5_fluency.dict.yaml"
    [ "$NO_FUZZY" -eq 1 ] || FILES5="$FILES5 cangjie5_fuzzy.schema.yaml cangjie5_fuzzy_prism.schema.yaml"
    for f in $FILES5; do
      rel="weasel/$f"; case "$f" in *_fuzzy*) [ "$FUZZY_RANGE" = normal ] || rel="weasel/fuzzy-$FUZZY_RANGE/$f" ;; esac
      get_src "$rel" "$WORK/$f"
      place_file "$WORK/$f" "$f"
    done
    get_src "tables/cangjie5.base.dict.yaml" "$WORK/cangjie5.base.dict.yaml" "$CJ5_BASE_SHA"
    place_file "$WORK/cangjie5.base.dict.yaml" "cangjie5.base.dict.yaml"
  fi

  # --- language model (always the repository's full model, size and hash checked)
  if [ "$NO_MODEL" -eq 0 ]; then
    GRAM_DEST="$RIME_DIR/$GRAM_NAME"
    if [ -f "$GRAM_DEST" ] && [ "$(file_size "$GRAM_DEST")" = "$GRAM_SIZE" ] && [ "$(sha256_of "$GRAM_DEST")" = "$GRAM_SHA" ]; then
      say "up to date: $GRAM_NAME (size $GRAM_SIZE, SHA-256 ok)" "已是最新：$GRAM_NAME（大小 $GRAM_SIZE，SHA-256 正確）"
    else
      get_src "data/$GRAM_NAME" "$WORK/$GRAM_NAME" "$GRAM_SHA"
      [ "$(file_size "$WORK/$GRAM_NAME")" = "$GRAM_SIZE" ] || die "$GRAM_NAME has the wrong size (want $GRAM_SIZE)" "$GRAM_NAME 的大小不對（應為 $GRAM_SIZE）"
      place_file "$WORK/$GRAM_NAME" "$GRAM_NAME"
    fi
  else
    say "skipping the language model (--no-model)" "略過語言模型（--no-model）"
  fi
fi

# ----------------------------------------------------------------------------------------- default.custom.yaml
IDS=""
if [ "$FUZZY_DEFAULT" -eq 1 ] && [ "$NO_FUZZY" -eq 0 ]; then
  IDS="cangjie3_fuzzy"; [ "$WITH_CJ5" -eq 0 ] || IDS="$IDS cangjie5_fuzzy"
  IDS="$IDS cangjie3_fluency"; [ "$WITH_CJ5" -eq 0 ] || IDS="$IDS cangjie5_fluency"
else
  IDS="cangjie3_fluency"; [ "$NO_FUZZY" -eq 1 ] || IDS="$IDS cangjie3_fuzzy"
  [ "$WITH_CJ5" -eq 0 ] || { IDS="$IDS cangjie5_fluency"; [ "$NO_FUZZY" -eq 1 ] || IDS="$IDS cangjie5_fuzzy"; }
fi
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
import os, re, sys
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
# typo-tolerant ids go right after their base schema (never becoming the default) unless --fuzzy-default
special = [x for x in missing if x.endswith("_fuzzy") and os.environ.get("CJF_FUZZY_DEFAULT") != "1"]
missing = [x for x in missing if x not in special]
prefix, brace = style if style else (b" " * (base_indent + 2) + b"- ", False)
new = []
for x in missing:
    body = (b"{schema: " + x.encode() + b"}") if brace else (b"schema: " + x.encode())
    new.append(prefix + body)
if not new:
    pass
elif first is not None:
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
cr = b"\r" if crlf else b""
for x in special:
    base = x.replace("_fuzzy", "_fluency")
    at = None
    for j, l in enumerate(lines):
        m = item.match(l.rstrip(b"\r"))
        if m and m.group(3).decode() == base:
            at = j
            break
    body = (b"{schema: " + x.encode() + b"}") if brace else (b"schema: " + x.encode())
    lines.insert((at + 1) if at is not None else idx + 1, prefix + body + cr)
open(out, "wb").write(b"\n".join(lines))
PY
}

dc_step() {
  if [ ! -e "$DC" ]; then
    if [ "$DRY" -eq 1 ]; then say "DRY: would create default.custom.yaml with: $IDS luna_pinyin" "試跑：將會建立 default.custom.yaml，內容：$IDS luna_pinyin"; return 0; fi
    fresh_default_custom >"$DC"
    manifest_add "@created-default.custom.yaml"
    say "created default.custom.yaml ($IDS first)" "已建立 default.custom.yaml（$IDS 排在最前面）"
    return 0
  fi
  local out rc=0
  out="$(mktemp "${TMPDIR:-/tmp}/cjf-dc.XXXXXX")"
  # shellcheck disable=SC2086
  CJF_FUZZY_DEFAULT="$FUZZY_DEFAULT" merge_schema_list "$DC" "$out" $IDS || rc=$?
  case "$rc" in
    10) say "default.custom.yaml already lists $IDS: left untouched" "default.custom.yaml 已列出 $IDS：不動它" ;;
    11)
      warn "default.custom.yaml has no block-style 'schema_list:', so I did not touch it. Add this under 'patch:' yourself:" "default.custom.yaml 沒有區塊寫法的 'schema_list:'，所以沒有修改它。請自行把下面這段加到 'patch:' 底下："
      printf '    schema_list:\n'
      for id in $IDS; do printf '      - schema: %s\n' "$id"; done
      printf '      # ...then the schemas you already use (a patched schema_list replaces the stock one)\n' ;;
    0)
      if [ "$DRY" -eq 1 ]; then say "DRY: would back up default.custom.yaml and insert $IDS at the top of its schema_list" "試跑：將會備份 default.custom.yaml，並把 $IDS 插入 schema_list 的最前面"
      else
        cp -p "$DC" "$DC.bak-$STAMP"
        say "backed up default.custom.yaml -> default.custom.yaml.bak-$STAMP" "已備份：default.custom.yaml -> default.custom.yaml.bak-$STAMP"
        cp "$out" "$DC.cjf-part"; mv -f "$DC.cjf-part" "$DC"
        manifest_add "@merged-default.custom.yaml"
        say "inserted $IDS as first entr(y/ies) of your schema_list in default.custom.yaml" "已把 $IDS 插入 default.custom.yaml 的 schema_list 最前面"
      fi ;;
    *) warn "could not process default.custom.yaml (python exit $rc); left untouched" "無法處理 default.custom.yaml（python 結束碼 $rc）；未做任何修改" ;;
  esac
  rm -f "$out"
}
dc_step

# ----------------------------------------------------------------------------------------- deploy
deploy() {
  [ "$DRY" -eq 0 ] || { say "DRY: would deploy (front end: $FRONTEND)" "試跑：將會部署（輸入法框架：$FRONTEND）"; return 0; }
  [ "$NO_DEPLOY" -eq 0 ] || { say "--no-deploy: not restarting the input method." "--no-deploy：不重新啟動輸入法。"; return 0; }
  case "$FRONTEND" in
    fcitx5)
      if have fcitx5-remote; then
        if fcitx5-remote -r >/dev/null 2>&1; then say "ran: fcitx5-remote -r (reload)" "已執行：fcitx5-remote -r（重新載入）"; else warn "fcitx5-remote -r failed; is fcitx5 running?" "fcitx5-remote -r 失敗；fcitx5 有在執行嗎？"; fi
        say "If the schema does not appear or still looks old, restart Fcitx5 fully (or pick 'Deploy' in the Rime tray menu)." "如果方案沒有出現或仍是舊的，請完整重新啟動 Fcitx5（或在 Rime 系統匣選單選「Deploy」）。"
      else
        warn "fcitx5-remote not found; restart Fcitx5 yourself, then choose Deploy in the Rime tray menu." "找不到 fcitx5-remote；請自行重新啟動 Fcitx5，然後在 Rime 系統匣選單選「Deploy」。"
      fi ;;
    fcitx5-flatpak) say "Flatpak Fcitx5: restart it yourself (path and method unverified), then choose Deploy in the Rime tray menu." "Flatpak 版 Fcitx5：請自行重新啟動（路徑與方法未驗證），然後在 Rime 系統匣選單選「Deploy」。" ;;
    fcitx)
      if have fcitx-remote; then
        if fcitx-remote -r >/dev/null 2>&1; then say "ran: fcitx-remote -r (reload)" "已執行：fcitx-remote -r（重新載入）"; else warn "fcitx-remote -r failed" "fcitx-remote -r 失敗"; fi
        say "If it does not pick up the schema, choose Deploy in the fcitx-rime menu or restart fcitx." "如果沒有載入方案，請在 fcitx-rime 選單選「Deploy」或重新啟動 fcitx。"
      else warn "fcitx-remote not found; restart fcitx yourself." "找不到 fcitx-remote；請自行重新啟動 fcitx。"; fi ;;
    ibus)
      if have ibus; then
        if ibus restart >/dev/null 2>&1; then say "ran: ibus restart (unverified: if the schema is missing, use Deploy in the ibus-rime menu)" "已執行：ibus restart（未驗證：如果方案不見了，請在 ibus-rime 選單用「Deploy」）"; else warn "ibus restart failed" "ibus restart 失敗"; fi
      else warn "ibus not found; restart ibus yourself (ibus-daemon -drx)." "找不到 ibus；請自行重新啟動 ibus（ibus-daemon -drx）。"; fi ;;
    none) say "custom directory, no front end named: not restarting anything. Redeploy from your input method's menu." "自訂資料夾、未指定輸入法框架：不重新啟動任何東西。請從你的輸入法選單重新部署。" ;;
  esac
}
deploy

# ----------------------------------------------------------------------------------------- finish
if [ "$DRY" -eq 1 ]; then
  say "dry run finished; nothing was changed." "試跑結束；沒有更動任何東西。"
else
  say "Done. Switch to the schema with Ctrl+\` (or F4) and pick 'cangjie3_fluency'." "完成。按 Ctrl+\`（或 F4）切換方案，選「cangjie3_fluency」。"
  say "Check the language model: grep -h 'use grammar\\|failed to load grammar' in the Rime log (see README): want a 'use grammar: $GRAM_NAME' line and NO 'failed to load grammar' line (glog buffers: it can appear late)." "檢查語言模型：在 Rime 記錄檔裡 grep -h 'use grammar\\|failed to load grammar'（見 README）：要看到「use grammar: $GRAM_NAME」那一行，且沒有「failed to load grammar」那一行（glog 有緩衝：可能較晚才出現）。"
  [ "$WARNINGS" -eq 0 ] || say "finished with $WARNINGS warning(s), see above." "完成，但有 $WARNINGS 個警告，請看上方訊息。"
fi

}   # end of main

main "$@"
