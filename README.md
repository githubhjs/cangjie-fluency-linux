# cangjie-fluency-linux

Microsoft-style sentence input for full Cangjie on Linux: type a whole phrase of Cangjie codes, the buffer
re-segments and auto-corrects as you type, Enter commits. No picking a character after every code.
It is a [Rime](https://rime.im) schema set up for **ibus-rime, fcitx5-rime and fcitx-rime**.

Everything it needs is provided by the owner's main repository
[githubhjs/cangjie-fluency](https://github.com/githubhjs/cangjie-fluency): the schema files, the Cangjie tables
(`tables/`), the word list and the language model (`data/`) and the converter (`tools/`). Provenance and licences of
those files are documented in the main repo's `tables/README.md` and `data/README.md`. **No other third-party download
is needed**: the installer does not contact PIME, rime-essay, rime-octagram-data, rime-cangjie or anyone else. The only
other thing it uses is your distribution's own package manager (apt, dnf, pacman, zypper) to install the Rime engine
packages, and that can be switched off with `--no-deps`.

繁體中文說明在[文件後半](#繁體中文)。

## Why the 3rd generation (三代)

The "新倉頡" that ships with Windows XP is a modified **3rd-generation** Cangjie. The 5th-generation table that most
Rime schemas use differs in roughly a fifth of the codes (面 is `mwyl` in 3rd gen and `mwsl` in 5th gen; 作 `ohs` vs `oos`;
非 `lmyyy` vs `lmsy`). So the default schema here is **`cangjie3_fluency`**. The 5th-generation variant
`cangjie5_fluency` is available as an option (`--with-cangjie5`).

## Install

### Option A: full release zip (works offline)

Download `cangjie-fluency-linux-<version>-full.zip` from this repository's Releases, unzip, then:

```sh
cd cangjie-fluency-linux-<version>
bash install.sh --offline            # no network access at all; engine packages via your package manager unless --no-deps
```

The zip contains the installer, the schema files, the tables, the word list, the 41,415,724-byte language model and the
converter (about 38 MB zipped). With `--offline` the installer never touches the network and stops with a clear message if a file is
missing. A `slim` zip (installer + schema files + converter, about 29 KB) also exists; it fetches the rest from the main repo.

### Option B: one line

```sh
curl -fsSL https://raw.githubusercontent.com/githubhjs/cangjie-fluency-linux/main/install.sh | bash
```

Safer, in two steps (read it first, try `--dry-run`):

```sh
curl -fsSLO https://raw.githubusercontent.com/githubhjs/cangjie-fluency-linux/main/install.sh
less install.sh
bash install.sh --dry-run
bash install.sh
```

What it does, in order:

1. Finds your front end (a running daemon, then an existing Rime directory, then an installed program). If none is
   installed it picks ibus (GNOME/Ubuntu default) or fcitx5 (KDE) and installs it.
2. Installs the engine packages that are missing with the distribution's package manager, using `sudo`
   (Debian/Ubuntu: `ibus-rime` or `fcitx5-rime`, plus `librime-plugin-octagram` for the language model). Skip with `--no-deps`.
3. Takes every file from the folder next to `install.sh` (full-zip layout `weasel/ tables/ data/ tools/`), otherwise from
   `raw.githubusercontent.com/githubhjs/cangjie-fluency/<ref>/` (default `v0.4.0`). Tables, word list and language model are
   **SHA-256 checked** against hashes pinned in the script.
4. Converts `tables/mscj3.cin` on your machine into `cangjie3.base.dict.yaml` with `tools/cin2rime.py`, always using the
   repository's `data/essay.txt` for the frequency weights, so the result is byte-identical on every platform.
5. Installs `data/zh-hant-t-essay-bgw.gram` (the full model) into the Rime directory, and `essay.txt` only when no system copy exists.
6. Puts `cangjie3_fluency` first in `default.custom.yaml` and redeploys.

Options:

| option | meaning |
|---|---|
| `--frontend ibus\|fcitx5\|fcitx\|auto` | default `auto` (running daemon, then existing directory, then installed program) |
| `--rime-dir DIR` (or env `RIME_DIR`) | install into `DIR`, for testing or unusual setups; nothing is restarted unless you also give `--frontend` |
| `--offline` | never touch the network; every file must be next to `install.sh` (use the full zip) |
| `--no-deps` | do not install engine packages with the package manager |
| `--ref TAG` | which tag/branch of the main repo to download missing files from (default `v0.4.0`) |
| `--with-cangjie5` | also install `cangjie5_fluency` (+ the 5th-generation table from the main repo's `tables/`) |
| `--no-model` | skip the 41 MB language model |
| `--no-deploy` | copy files only |
| `--dry-run` | print what would happen, change and download nothing |
| `--uninstall` | remove only the files this installer created (it keeps a manifest); backups are kept |

Safety properties (covered by `tests/test_install.sh`, 84 checks): re-running with identical content rewrites nothing and
makes no backup; a changed file gets exactly one `NAME.bak-<timestamp>`; your `default.custom.yaml` is never overwritten.
If it already has a `schema_list:`, the installer backs the file up and inserts `- schema: cangjie3_fluency` as the
**first** entry, keeping your indentation, line endings (LF/CRLF), the `- {schema: x}` brace style and a missing final
newline. If `cangjie3_fluency` is already listed nothing is added (exact id match). If the file has no block-style
`schema_list:` it is not touched and the installer prints what to add. Without a `default.custom.yaml` it creates one
listing `cangjie3_fluency` and `luna_pinyin` (a patched `schema_list` replaces the stock list, so add the schemas you
use).

## Engine packages per distribution

`install.sh` runs the matching command through `sudo` (you are asked for your password) unless you pass `--no-deps`:

| | command run | status |
|---|---|---|
| Debian / Ubuntu | `apt-get install -y ibus-rime` (or `fcitx5-rime`) `librime-plugin-octagram` | package names checked with `apt-cache` on Ubuntu 24.04; the install itself was only tested with stub commands |
| Fedora | `dnf install -y ibus-rime` (or `fcitx5-rime`) `librime-octagram` | `librime-octagram` exists in rawhide (checked via mdapi); `ibus-rime`/`fcitx5-rime` names **unverified** |
| Arch Linux | `pacman -S --needed --noconfirm ibus-rime` (or `fcitx5-rime`) | the official `librime` package already contains `librime-octagram.so` (checked in its file list); names **unverified** |
| openSUSE | `zypper --non-interactive install ibus-rime` (or `fcitx5-rime`) `librime-octagram` | **unverified** |
| Gentoo, NixOS, Flatpak, others | not automated | install an engine and `librime-octagram` yourself |

Also needed: the Rime shared data (`default.yaml`, `luna_pinyin`, ...), normally pulled in by the engine package
(Debian/Ubuntu: `librime-data`). User directories used (override with `--rime-dir`): ibus-rime `~/.config/ibus/rime`,
fcitx5-rime `~/.local/share/fcitx5/rime`, fcitx-rime `~/.config/fcitx/rime`.

## Deploy, switch, verify

The installer ends with a deploy step unless you pass `--no-deploy`:

| front end | command run | verified here? |
|---|---|---|
| ibus | `ibus restart` | tested live through the IBus API (see below) |
| fcitx5 | `fcitx5-remote -r` (reload). If the schema does not show up or looks old, restart Fcitx5 completely, or use **Deploy** in the Rime tray menu | **unverified** (no fcitx5 available) |
| fcitx (4) | `fcitx-remote -r` | **unverified** |

The first deploy compiles the dictionary (about 5 seconds on the test machine, producing a 15 MB table).

**Switch schema:** press `Ctrl+`` (grave) or `F4`, pick "倉頡三代整句" (`cangjie3_fluency`).

**Verify the language model loaded.** Look at the Rime log after switching to the schema:

```sh
grep -h 'use grammar\|failed to load grammar' $(ls -t /tmp/rime.*INFO* 2>/dev/null | head -3)
```

Healthy: a line `octagram.cc:29] use grammar: zh-hant-t-essay-bgw` and **no** `failed to load grammar database`.
The `use grammar` line is also printed when the `.gram` file is missing; the real failure shows up as
`E... octagram.cc:180] failed to load grammar database: zh-hant-t-essay-bgw` right after it. No `use grammar` line at all
means the octagram plugin was not loaded. Logs: for **ibus-rime this is verified**
`/tmp/rime.ibus.<host>.<user>.log.INFO.<date>-<time>.<pid>` on Ubuntu 24.04; for fcitx5-rime it is **unverified**. glog buffers the
INFO file, so the line can show up late (wait about 30 s or stop the engine).

## Typing notes

* Just keep typing codes: `dhedhkb` becomes 板橋 and earlier characters get corrected as you continue. No selection needed.
* A character whose Cangjie code is a **single letter** needs a trailing space: 中 is `l`, so 中午 is `l oj`. Other codes
  can be run together; a space between codes is optional.
* **Enter** commits the whole sentence. `,` `.` `!` `?` commit the sentence and then type the (full-width) punctuation.
  Space inside the buffer only separates codes; two spaces in a row commit the sentence plus a space.
* Backspace removes one code (and re-segments), Esc clears the buffer. Page Up/Down and the arrow keys move through
  candidates; same-code characters (e.g. 佑 / 知 on `okr` in 3rd gen) are chosen by frequency and may need a candidate pick.
* `` ` `` followed by pinyin does a reverse lookup (needs `luna_pinyin`, i.e. the rime-data package).
* 3rd generation has no 難 (X) prefix for second characters of the same code (that is a 5th-generation feature).

**Language model.** Our test sentences (51 everyday sentences, 40 same-code hard sentences, 91 whole sentences in total, and
34 same-code pairs such as 手感/手怠 and 頻率/顏率) give the same result with and without the model, because those words
already have frequencies in `essay.txt`. We have not found a case that measures a model effect. The model file
(`zh-hant-t-essay-bgw.gram`) is shipped in the main repository and installed anyway.

**Live test, ibus-rime (2026-11-10).** Ubuntu 24.04 aarch64, IBus 1.5.29-rc2, ibus-rime 1.5.0, librime 1.10.0 with the Ubuntu
`librime-plugin-octagram`, driven through the IBus API (`tests/ibus_live_test.py`: real key events into an input context bound to
the `rime` engine, preedit, candidates and committed text read back). **10 of 10 cases passed**: 面 `mwyl`, 非 `lmyyy`, 作 `ohs`;
`okr` offers 佑 then 知; 板橋 `dhedhkb`; 中午 `l oj`; and four whole sentences typed continuously with no space and no
candidate selection came out exactly as written. The log shows `loaded plugin: octagram`, `use grammar: zh-hant-t-essay-bgw`, no
`failed to load grammar` and no `E` lines. It was **not** a GUI test (no text box, no candidate window).

## Known limits

* **fcitx5-rime and fcitx-rime were not tested; ibus-rime was tested through the IBus API only** (no GUI, one machine: Ubuntu
  24.04 aarch64, GNOME on Xorg). The schema was compiled and driven key by key with librime 1.10, see `docs/test-log.md`.
* The package-manager step was tested with stub commands, not against a distribution's real repositories (apt names were checked
  with `apt-cache`; dnf, pacman and zypper names are unverified).
* Whether the 3rd-generation table `tables/mscj3.cin` is identical to Windows XP's table is **unverified** (only 面, 非, 作, 知/佑 were checked).
* Same-code characters are decided by frequency only (e.g. 雙/隻, 佑/知, 冇/有 are wrong in the main repo's hard test set).
* Digits, symbols and uppercase letters typed into an empty buffer land in the buffer instead of going straight to the
  application (inherited from the main repo's design, see its docs).
* Only a block-style `schema_list:` is edited automatically; an inline `schema_list: [ ... ]` or `schema_list/+:` patch is left
  alone with instructions.
* x86_64 and other distributions are untested (the compile test ran on aarch64 only).

## Uninstall

```sh
bash install.sh --uninstall                 # or: --frontend ibus / --rime-dir DIR to pick the directory
```

Removes only what the installer wrote (listed in `.cangjie-fluency-linux.manifest` in the Rime directory), keeps every
`*.bak-*` backup, and removes `default.custom.yaml` only if the installer created it and it is unchanged. If it merely
edited your existing `default.custom.yaml`, delete the `- schema: cangjie3_fluency` line yourself (the pre-edit copy is
`default.custom.yaml.bak-<time>`). Engine packages installed through the package manager are not removed. Then redeploy.

## Tests and releases

```sh
bash tests/test_install.sh          # offline, stubbed front end/curl/sudo, real tables + model, 84 checks
bash tests/compile_test.sh [DIR]    # real librime build of the schema with the repo's own table/essay/model
./make-release.sh ~/projects/cangjie-fluency v0.4.0   # dist/*-full.zip and *-slim.zip (needs the main repo checkout)
```

## Credits and licensing

* Chu Bong-Foo (朱邦復), inventor of Cangjie, publicly waived the patent in 1982.
* [rime/rime-cangjie](https://github.com/rime/rime-cangjie) and [rime/rime-quick](https://github.com/rime/rime-quick) (LGPL-3.0), and
  eight04's `quick5_fluency` prototype, [rime/rime-quick#2](https://github.com/rime/rime-quick/issues/2): the ideas this builds on.
* [cangjie-system/rime-cangjie-integrated](https://github.com/cangjie-system/rime-cangjie-integrated) (MIT): a collection of Cangjie
  tables for Rime and the guide most Linux users follow; it is a plain table input method, this project adds the sentence-style mode.
* Provenance and licensing of the tables, word list and language model: the main repo's `tables/README.md` and `data/README.md`.
* This repository: LGPL-3.0, see `LICENSE`.

Engine and schema documentation: [githubhjs/cangjie-fluency](https://github.com/githubhjs/cangjie-fluency)
(`weasel/README.zh-TW.md`, `weasel/docs/`).

---

# 繁體中文

## 這是什麼

在 Linux（ibus-rime、fcitx5-rime、fcitx-rime）上提供「微軟新倉頡」手感的整句輸入：連續打完一整串倉頡碼，
緩衝區會自動重新斷詞、修正前面的字，Enter 上屏，不必每個字選字。

所需檔案全部由主倉庫 [githubhjs/cangjie-fluency](https://github.com/githubhjs/cangjie-fluency) 提供：方案檔、倉頡碼表
（`tables/`）、詞彙表與語言模型（`data/`）、轉換工具（`tools/`）。各檔案的來源與授權請看主倉庫的 `tables/README.md`、
`data/README.md`。**不需要任何其他第三方下載**：安裝腳本不會連到 PIME、rime-essay、rime-octagram-data、rime-cangjie 或其他網站；
唯一用到的是作業系統自己的套件管理員（apt、dnf、pacman、zypper）來裝 Rime 引擎，可用 `--no-deps` 關掉。

## 為什麼是三代

Windows XP 內建的「新倉頡」是改良過的**三代**倉頡。多數 Rime 方案用的五代碼表和三代約有兩成字碼不同
（「面」三代 `mwyl`、五代 `mwsl`；「作」`ohs` / `oos`；「非」`lmyyy` / `lmsy`）。所以預設方案是 **`cangjie3_fluency`**，
五代版 `cangjie5_fluency` 用 `--with-cangjie5` 另外裝。

## 安裝

### 方式 A：完整離線包

到本倉庫的 Releases 下載 `cangjie-fluency-linux-<版本>-full.zip`，解壓後：

```sh
cd cangjie-fluency-linux-<版本>
bash install.sh --offline
```

完整包內含安裝腳本、方案檔、碼表、詞彙表、41,415,724 位元組的語言模型與轉換工具（壓縮後約 38 MB）。`--offline` 完全不連網，缺檔會明確報錯。
另有 `slim` 精簡包（只有腳本、方案檔與轉換工具），其餘檔案安裝時從主倉庫下載。

### 方式 B：一行指令

```sh
curl -fsSL https://raw.githubusercontent.com/githubhjs/cangjie-fluency-linux/main/install.sh | bash
```

比較安全的做法：先下載、看過、`--dry-run` 試跑再執行：

```sh
curl -fsSLO https://raw.githubusercontent.com/githubhjs/cangjie-fluency-linux/main/install.sh
less install.sh
bash install.sh --dry-run
bash install.sh
```

腳本會：偵測前端（沒有任何前端時依桌面環境選 ibus 或 fcitx5）→ 用系統套件管理員（`sudo`）補裝缺少的引擎套件與
`librime-plugin-octagram`（`--no-deps` 可跳過）→ 檔案優先取腳本旁邊（完整包的 `weasel/ tables/ data/ tools/` 結構），否則從主倉庫
`raw.githubusercontent.com/githubhjs/cangjie-fluency/<版本>/`（預設 `v0.4.0`）下載；碼表、詞彙表、語言模型都會核對 **SHA-256** →
在你的電腦上把 `tables/mscj3.cin` 轉成 `cangjie3.base.dict.yaml`（一律用主倉庫的 `data/essay.txt` 當權重，各平台輸出逐位元組相同）→
安裝完整語言模型 → 把 `cangjie3_fluency` 放進 `default.custom.yaml` 方案清單的**第一個** → 重新部署。

重複執行是安全的：內容相同的檔案不會重寫、不會備份；內容不同的檔案只備份一次（`檔名.bak-時間`）。
你已有的 `default.custom.yaml` 不會被覆蓋：有 `schema_list:` 就先備份再插入第一項（保留縮排、LF/CRLF、`- {schema: x}`
寫法與結尾沒有換行的狀況）；已經列了就不動；沒有 `schema_list:` 就不碰，只印出要加什麼。

## 各發行版的引擎套件

預設會用 `sudo` 執行對應的套件管理員指令（`--no-deps` 可跳過）：Debian/Ubuntu `apt-get install -y ibus-rime`（或 `fcitx5-rime`）
加 `librime-plugin-octagram`（名稱已用 `apt-cache` 確認，實際安裝只用假指令測過）；Fedora、Arch、openSUSE 的 dnf／pacman／zypper
為盡力支援，名稱**未驗證**（Arch 的 `librime` 已內含 octagram 外掛）。其他發行版、Flatpak 請自行安裝。

資料夾：ibus-rime `~/.config/ibus/rime`、fcitx5-rime `~/.local/share/fcitx5/rime`、fcitx-rime `~/.config/fcitx/rime`。

## 部署、切換、確認語言模型

* ibus：腳本執行 `ibus restart`（已用 IBus API 實測）。fcitx5：`fcitx5-remote -r`；若方案沒出現，請完整重啟 Fcitx5，或在托盤的 Rime 選單按「部署」（**未驗證**）。fcitx 4：`fcitx-remote -r`（**未驗證**）。
* 切換方案：`Ctrl+`` 或 `F4`，選「倉頡三代整句」。
* 確認語言模型：切到方案後看 Rime 日誌，
  `grep -h 'use grammar\|failed to load grammar' $(ls -t /tmp/rime.*INFO* 2>/dev/null | head -3)`。
  正常：有 `use grammar: zh-hant-t-essay-bgw`，而且**沒有** `failed to load grammar database`。
  完全沒有 `use grammar` = 外掛沒載入。日誌位置 ibus-rime 已驗證（`/tmp/rime.ibus.*`），fcitx5 **未驗證**。

## 打法

* 一路打字根：`dhedhkb` → `板橋`，繼續打會自動修正前面的字。
* **只有一個字根的字後面要接空格**：「中」是 `l`，「中午」打 `l oj`；其他字碼之間空格可有可無。
* Enter 上屏整句；`，` `。` `！` `？`（`,` `.` `!` `?`）會先上屏整句再接標點。
* Backspace 退一個字根，Esc 清空；同碼字（三代的 佑/知 同為 `okr`）靠詞頻排序，錯了就選第二候選。
* 三代沒有「難」（X）前綴，那是五代的設計。

**語言模型**：我們的測試句（51 句日常句、40 句同碼困難句，共 91 句整句，以及 34 組同碼詞對，例如 手感/手怠、頻率/顏率）
有沒有語言模型結果都相同，因為這些詞在 `essay.txt` 裡已有詞頻；我們沒有找到能量出語言模型效果的案例。模型檔放在主倉庫裡，仍會一併安裝。

## 已知限制

* **沒有在實際的 fcitx5／fcitx 裡測過；ibus-rime 只用 IBus API 測過**（沒有圖形介面、沒有候選視窗）。方案另用 librime 1.10 在
  Ubuntu 24.04 aarch64 逐鍵編譯、輸入驗證（見 `docs/test-log.md`）。
* 套件管理員那一步只用假指令測過，沒有對真正的套件庫執行。
* 三代碼表是否與 Windows XP 完全一致：**未驗證**（只核對了 面、非、作、知/佑）。
* 同碼字只靠詞頻（雙/隻、佑/知、冇/有 在主倉庫的困難測試集中會錯）。
* 空緩衝區時打的數字、符號、大寫字母會進緩衝區，不會直接送到應用程式。

## 解除安裝

`bash install.sh --uninstall`：只刪除本腳本建立的檔案（記錄在 Rime 資料夾的 `.cangjie-fluency-linux.manifest`），保留所有
`*.bak-*` 備份；用套件管理員裝的引擎不會移除。若只是改了你原本的 `default.custom.yaml`，請自己刪掉
`- schema: cangjie3_fluency` 那行（原檔備份在 `default.custom.yaml.bak-時間`），再重新部署。

## 來源與授權

* 倉頡由朱邦復先生創製，他已於 1982 年公開放棄專利權。
* 基於 [rime/rime-cangjie](https://github.com/rime/rime-cangjie)、[rime/rime-quick](https://github.com/rime/rime-quick)，
  以及 eight04 在 [rime-quick#2](https://github.com/rime/rime-quick/issues/2) 的 `quick5_fluency` 原型；也感謝
  [cangjie-system/rime-cangjie-integrated](https://github.com/cangjie-system/rime-cangjie-integrated)（MIT）。
* 碼表、詞彙表、語言模型的來源與授權：主倉庫的 `tables/README.md`、`data/README.md`。
* 授權：LGPL-3.0，見 `LICENSE`。引擎與方案細節請看主倉庫 `weasel/README.zh-TW.md`。
