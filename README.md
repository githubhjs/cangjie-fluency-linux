# cangjie-fluency-linux / 倉頡整句輸入（Linux 版）

在 Linux 上提供微軟風格的完整倉頡整句輸入：一次打完整個詞組的倉頡碼，緩衝區會一邊輸入一邊重新斷詞並自動修正，按 Enter 上屏，
不必每打完一個碼就選字。這是一套 [Rime](https://rime.im) 方案，適用於 **ibus-rime、fcitx5-rime 與 fcitx-rime**。

所需的一切都由作者的主倉庫 [githubhjs/cangjie-fluency](https://github.com/githubhjs/cangjie-fluency) 提供：方案檔、倉頡碼表（`tables/`）、
詞表與語言模型（`data/`）以及轉換工具（`tools/`）。這些檔案的來源與授權記載於主倉庫的 `tables/README.md` 與 `data/README.md`。
**不需要任何其他第三方下載**：安裝腳本不會連到 PIME、rime-essay、rime-octagram-data、rime-cangjie 或其他任何來源。
它唯一會用到的，是你的發行版自己的套件管理員（apt、dnf、pacman、zypper）來安裝 Rime 引擎套件，這一步可用 `--no-deps` 關閉。

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

## Why the 3rd generation (三代) / 為什麼是三代

Windows XP 內建的「新倉頡」是經過修改的**倉頡三代**。多數 Rime 方案使用的五代碼表，約有五分之一的字碼與三代不同
（「面」三代是 `mwyl`、五代是 `mwsl`；「作」`ohs` 對 `oos`；「非」`lmyyy` 對 `lmsy`）。因此這裡預設的方案是 **`cangjie3_fluency`**。
五代版本 `cangjie5_fluency` 可作為選項安裝（`--with-cangjie5`）。

The "新倉頡" that ships with Windows XP is a modified **3rd-generation** Cangjie. The 5th-generation table that most
Rime schemas use differs in roughly a fifth of the codes (面 is `mwyl` in 3rd gen and `mwsl` in 5th gen; 作 `ohs` vs `oos`;
非 `lmyyy` vs `lmsy`). So the default schema here is **`cangjie3_fluency`**. The 5th-generation variant
`cangjie5_fluency` is available as an option (`--with-cangjie5`).

## Install / 安裝

### Option A: full release zip (works offline) / 方式 A：完整發行 zip（可離線使用）

從本倉庫的 Releases 下載 `cangjie-fluency-linux-<version>-full.zip`，解壓縮後執行下方英文區塊中的指令。

完整 zip 內含安裝腳本、方案檔、碼表、詞表、41,415,724 位元組的語言模型與轉換工具（壓縮後約 38 MB）。使用 `--offline` 時，
安裝腳本完全不碰網路，若缺少檔案會以清楚的訊息停止。另有 `slim` zip（安裝腳本 + 方案檔 + 轉換工具，約 29 KB），其餘檔案會從主倉庫下載。

Download `cangjie-fluency-linux-<version>-full.zip` from this repository's Releases, unzip, then:

```sh
cd cangjie-fluency-linux-<version>
bash install.sh --offline            # no network access at all; engine packages via your package manager unless --no-deps
```

The zip contains the installer, the schema files, the tables, the word list, the 41,415,724-byte language model and the
converter (about 38 MB zipped). With `--offline` the installer never touches the network and stops with a clear message if a file is
missing. A `slim` zip (installer + schema files + converter, about 29 KB) also exists; it fetches the rest from the main repo.

### Option B: one line / 方式 B：一行指令

一行指令見下方英文區塊。較安全的做法是分兩步（先閱讀腳本，再試跑 `--dry-run`），指令同樣見下方。

安裝腳本依序執行：

1. 尋找你的輸入法框架（先找執行中的常駐程式，再找既有的 Rime 目錄，最後找已安裝的程式）。若都沒有安裝，
   就選 ibus（GNOME/Ubuntu 預設）或 fcitx5（KDE）並安裝。
2. 以發行版的套件管理員、透過 `sudo` 安裝缺少的引擎套件（Debian/Ubuntu：`ibus-rime` 或 `fcitx5-rime`，
   另加供語言模型使用的 `librime-plugin-octagram`）。可用 `--no-deps` 跳過。
3. 所有檔案優先取自 `install.sh` 旁邊的資料夾（完整 zip 的結構為 `weasel/ tables/ data/ tools/`），否則取自
   `raw.githubusercontent.com/githubhjs/cangjie-fluency/<ref>/`（預設 `v0.5.1`）。碼表、詞表與語言模型都會以
   腳本中固定的雜湊值做 **SHA-256 核對**。
4. 在你的電腦上用 `tools/cin2rime.py` 把 `tables/mscj3.cin` 轉成 `cangjie3.base.dict.yaml`，詞頻權重一律使用
   倉庫的 `data/essay.txt`，因此各平台的結果逐位元組相同。
5. 把 `data/zh-hant-t-essay-bgw.gram`（完整模型）安裝到 Rime 目錄；`essay.txt` 只有在系統沒有現成副本時才安裝。
6. 在 `default.custom.yaml` 中把 `cangjie3_fluency` 放在第一位，並重新部署。

選項：

| 選項 | 意義 |
|---|---|
| `--frontend ibus\|fcitx5\|fcitx\|auto` | 預設 `auto`（先找執行中的常駐程式，再找既有目錄，最後找已安裝的程式） |
| `--rime-dir DIR`（或環境變數 `RIME_DIR`） | 安裝到 `DIR`，供測試或特殊環境使用；除非同時指定 `--frontend`，否則不會重新啟動任何程式 |
| `--offline` | 完全不碰網路；每個檔案都必須在 `install.sh` 旁邊（請使用完整 zip） |
| `--no-deps` | 不用套件管理員安裝引擎套件 |
| `--ref TAG` | 從主倉庫的哪個標籤／分支下載缺少的檔案（預設 `v0.5.1`） |
| `--with-cangjie5` | 一併安裝 `cangjie5_fluency`（以及主倉庫 `tables/` 中的五代碼表） |
| `--no-model` | 跳過 41 MB 的語言模型 |
| `--no-sweep` | 不安裝倉頡滑行輸入板（預設會安裝） |
| `--pad-ref REF` | 從 githubhjs/cangjie-fuzzy-core 下載滑行板的版本標籤（預設 `v0.1.0`） |
| `--no-deploy` | 只複製檔案 |
| `--dry-run` | 只印出會做什麼，不變更也不下載任何東西 |
| `--uninstall` | 只移除本安裝腳本建立的檔案（它會保存一份清單）；備份會保留 |

安全特性（由 `tests/test_install.sh` 涵蓋，共 84 項檢查）：以相同內容重複執行時不會重寫任何檔案，也不會建立備份；
內容有變動的檔案只會得到一份 `NAME.bak-<timestamp>`；你的 `default.custom.yaml` 絕不會被覆蓋。
若它已有 `schema_list:`，安裝腳本會先備份該檔，並把 `- schema: cangjie3_fluency` 插入為**第一項**，同時保留你的縮排、
換行字元（LF/CRLF）、`- {schema: x}` 大括號寫法，以及缺少結尾換行的狀況。若 `cangjie3_fluency` 已列在其中則不新增（以完整 id 比對）。
若檔案沒有區塊式（block-style）的 `schema_list:`，則不會動它，安裝腳本會印出該加入的內容。
若沒有 `default.custom.yaml`，則會建立一個，列出 `cangjie3_fluency` 與 `luna_pinyin`（打了補丁的 `schema_list` 會取代原本的預設清單，
所以請自行加入你使用的方案）。

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
   `raw.githubusercontent.com/githubhjs/cangjie-fluency/<ref>/` (default `v0.5.1`). Tables, word list and language model are
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
| `--ref TAG` | which tag/branch of the main repo to download missing files from (default `v0.5.1`) |
| `--with-cangjie5` | also install `cangjie5_fluency` (+ the 5th-generation table from the main repo's `tables/`) |
| `--no-model` | skip the 41 MB language model |
| `--no-sweep` | do not install the Cangjie Sweep Pad (installed by default) |
| `--pad-ref REF` | release tag of githubhjs/cangjie-fuzzy-core to download the pad from (default `v0.5.0`) |
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

## Engine packages per distribution / 各發行版的引擎套件

除非你加上 `--no-deps`，`install.sh` 會透過 `sudo` 執行對應的指令（會要求輸入密碼）：

| | 執行的指令 | 狀態 |
|---|---|---|
| Debian / Ubuntu | `apt-get install -y ibus-rime`（或 `fcitx5-rime`）`librime-plugin-octagram` | 套件名稱已在 Ubuntu 24.04 以 `apt-cache` 核對；安裝本身只用假（stub）指令測試過 |
| Fedora | `dnf install -y ibus-rime`（或 `fcitx5-rime`）`librime-octagram` | `librime-octagram` 存在於 rawhide（以 mdapi 核對）；`ibus-rime`／`fcitx5-rime` 的名稱**未驗證** |
| Arch Linux | `pacman -S --needed --noconfirm ibus-rime`（或 `fcitx5-rime`） | 官方 `librime` 套件已內含 `librime-octagram.so`（已核對其檔案清單）；名稱**未驗證** |
| openSUSE | `zypper --non-interactive install ibus-rime`（或 `fcitx5-rime`）`librime-octagram` | **未驗證** |
| Gentoo、NixOS、Flatpak 及其他 | 未自動化 | 請自行安裝引擎與 `librime-octagram` |

另外還需要 Rime 共用資料（`default.yaml`、`luna_pinyin` 等），通常由引擎套件一併裝入（Debian/Ubuntu：`librime-data`）。
使用的使用者目錄（可用 `--rime-dir` 覆寫）：ibus-rime `~/.config/ibus/rime`、
fcitx5-rime `~/.local/share/fcitx5/rime`、fcitx-rime `~/.config/fcitx/rime`。

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

## Deploy, switch, verify / 部署、切換、確認

除非加上 `--no-deploy`，安裝腳本最後會執行部署步驟：

| 輸入法框架 | 執行的指令 | 在此驗證過嗎？ |
|---|---|---|
| ibus | `ibus restart` | 已透過 IBus API 實機測試（見下方） |
| fcitx5 | `fcitx5-remote -r`（重新載入）。若方案沒有出現或看起來是舊的，請完整重新啟動 Fcitx5，或使用 Rime 托盤選單中的**部署** | **未驗證**（沒有 fcitx5 可用） |
| fcitx (4) | `fcitx-remote -r` | **未驗證** |

第一次部署會編譯詞典（在測試機器上約 5 秒，產生 15 MB 的碼表）。

**切換方案：** 按 `Ctrl+`` （重音符）或 `F4`，選「倉頡三代整句」（`cangjie3_fluency`）。

**確認語言模型已載入。** 切換到該方案後查看 Rime 日誌（指令見下方英文區塊）。

正常情況：有一行 `octagram.cc:29] use grammar: zh-hant-t-essay-bgw`，且**沒有** `failed to load grammar database`。
`.gram` 檔案不存在時也會印出 `use grammar` 這一行；真正的失敗會緊接著出現
`E... octagram.cc:180] failed to load grammar database: zh-hant-t-essay-bgw`。完全沒有 `use grammar` 這一行，
代表 octagram 外掛沒有載入。日誌位置：**ibus-rime 已驗證**，在 Ubuntu 24.04 上為
`/tmp/rime.ibus.<host>.<user>.log.INFO.<date>-<time>.<pid>`；fcitx5-rime 則**未驗證**。glog 會緩衝 INFO 檔案，
所以那一行可能較晚才出現（約等 30 秒，或停止引擎）。

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

## Typing notes / 打法說明

* 只要一直打碼：`dhedhkb` 會變成 板橋，繼續輸入時前面的字會被自動修正，不需要選字。
* 字碼**只有單一字母**的字後面需要空格：「中」是 `l`，所以「中午」要打 `l oj`。其他字碼可以連著打，
  碼與碼之間的空格可有可無。
* **Enter** 上屏整句。`,` `.` `!` `?` 會先上屏整句，再輸入（全形）標點。
  緩衝區內的空格只用來分隔字碼；連按兩次空格會上屏整句再加一個空格。
* Backspace 刪掉一個碼（並重新斷詞），Esc 清空緩衝區。Page Up/Down 與方向鍵可在候選字間移動；
  同碼字（例如三代中 `okr` 的 佑 / 知）依詞頻排序，可能需要選一下候選字。
* `` ` `` 後接拼音會做反查（需要 `luna_pinyin`，即 rime-data 套件）。
* 三代對同碼的第二個字沒有「難」（X）前綴（那是五代的功能）。

**語言模型。** 我們的測試句（51 句日常句、40 句同碼困難句，共 91 句整句，以及
34 組同碼詞對，例如 手感/手怠 與 頻率/顏率）在有無語言模型時結果相同，因為這些詞在 `essay.txt` 中已有詞頻。
我們沒有找到能量測出模型效果的案例。模型檔（`zh-hant-t-essay-bgw.gram`）隨主倉庫提供，仍會安裝。

**實機測試，ibus-rime（2026-11-10）。** Ubuntu 24.04 aarch64、IBus 1.5.29-rc2、ibus-rime 1.5.0、librime 1.10.0 搭配 Ubuntu 的
`librime-plugin-octagram`，透過 IBus API 驅動（`tests/ibus_live_test.py`：對綁定到 `rime` 引擎的輸入環境送出真實按鍵事件，
讀回預編輯（preedit）、候選字與已上屏文字）。**10 項案例全數通過**：面 `mwyl`、非 `lmyyy`、作 `ohs`；
`okr` 依序提供 佑、知；板橋 `dhedhkb`；中午 `l oj`；另有四個整句，連續輸入、不打空格、不選候選字，結果與原文完全一致。
日誌顯示 `loaded plugin: octagram`、`use grammar: zh-hant-t-essay-bgw`，沒有 `failed to load grammar`，也沒有 `E` 行。
這**不是**圖形介面測試（沒有文字方塊、沒有候選視窗）。

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

## Known limits / 已知限制

* **fcitx5-rime 與 fcitx-rime 未測試；ibus-rime 只透過 IBus API 測試**（沒有圖形介面，只有一台機器：Ubuntu
  24.04 aarch64、Xorg 上的 GNOME）。方案以 librime 1.10 編譯並逐鍵驅動，見 `docs/test-log.md`。
* 套件管理員那一步只用假指令測試，沒有對照發行版的真實套件庫（apt 名稱已用 `apt-cache` 核對；
  dnf、pacman 與 zypper 的名稱未驗證）。
* 三代碼表 `tables/mscj3.cin` 是否與 Windows XP 的碼表完全相同：**未驗證**（只核對了 面、非、作、知/佑）。
* 同碼字只靠詞頻決定（例如 雙/隻、佑/知、冇/有 在主倉庫的困難測試集中是錯的）。
* 在空緩衝區中輸入的數字、符號與大寫字母會進入緩衝區，而不是直接送到應用程式
  （承襲主倉庫的設計，見其文件）。
* 只有區塊式的 `schema_list:` 會被自動編輯；行內的 `schema_list: [ ... ]` 或 `schema_list/+:` 補丁則不會動，
  並附上操作說明。
* x86_64 與其他發行版未測試（編譯測試只在 aarch64 上跑過）。

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

## Uninstall / 解除安裝

指令見下方英文區塊。

只移除安裝腳本寫入的檔案（列在 Rime 目錄中的 `.cangjie-fluency-linux.manifest`），保留所有
`*.bak-*` 備份，且只有在 `default.custom.yaml` 是由安裝腳本建立、並且沒有被改動時才會移除它。若安裝腳本只是
編輯了你既有的 `default.custom.yaml`，請自行刪掉 `- schema: cangjie3_fluency` 那一行（編輯前的副本是
`default.custom.yaml.bak-<time>`）。透過套件管理員安裝的引擎套件不會被移除。之後請重新部署。

```sh
bash install.sh --uninstall                 # or: --frontend ibus / --rime-dir DIR to pick the directory
```

Removes only what the installer wrote (listed in `.cangjie-fluency-linux.manifest` in the Rime directory), keeps every
`*.bak-*` backup, and removes `default.custom.yaml` only if the installer created it and it is unchanged. If it merely
edited your existing `default.custom.yaml`, delete the `- schema: cangjie3_fluency` line yourself (the pre-edit copy is
`default.custom.yaml.bak-<time>`). Engine packages installed through the package manager are not removed. Then redeploy.

## Tests and releases / 測試與發行

指令與其註解見下方英文區塊：`tests/test_install.sh` 離線執行，使用假的輸入法框架／curl／sudo，搭配真實碼表與模型，共 84 項檢查；
`tests/compile_test.sh` 以倉庫自己的碼表／essay／模型實際用 librime 建置方案；`make-release.sh` 產生
`dist/*-full.zip` 與 `*-slim.zip`（需要主倉庫的 checkout）。

```sh
bash tests/test_install.sh          # offline, stubbed front end/curl/sudo, real tables + model, 84 checks
bash tests/compile_test.sh [DIR]    # real librime build of the schema with the repo's own table/essay/model
./make-release.sh ~/projects/cangjie-fluency v0.5.1   # dist/*-full.zip and *-slim.zip (needs the main repo checkout)
```

## Credits and licensing / 來源與授權

* 朱邦復（Chu Bong-Foo），倉頡的發明人，已於 1982 年公開放棄專利權。
* [rime/rime-cangjie](https://github.com/rime/rime-cangjie) 與 [rime/rime-quick](https://github.com/rime/rime-quick)（LGPL-3.0），
  以及 eight04 的 `quick5_fluency` 原型，[rime/rime-quick#2](https://github.com/rime/rime-quick/issues/2)：本專案建立在這些想法之上。
* [cangjie-system/rime-cangjie-integrated](https://github.com/cangjie-system/rime-cangjie-integrated)（MIT）：一套供 Rime 使用的
  倉頡碼表集合，也是多數 Linux 使用者依循的指南；它是單純的碼表輸入法，本專案則加入整句模式。
* 碼表、詞表與語言模型的來源與授權：見主倉庫的 `tables/README.md` 與 `data/README.md`。
* 本倉庫：LGPL-3.0，見 `LICENSE`。

引擎與方案文件：[githubhjs/cangjie-fluency](https://github.com/githubhjs/cangjie-fluency)
（`weasel/README.zh-TW.md`、`weasel/docs/`）。

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
`raw.githubusercontent.com/githubhjs/cangjie-fluency/<版本>/`（預設 `v0.5.1`）下載；碼表、詞彙表、語言模型都會核對 **SHA-256** →
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

## 鄰鍵容錯（隨附，預設不啟用）/ Adjacent-key typo tolerance (included, not the default)

安裝時會一併裝入「鄰鍵容錯」方案 `cangjie3_fuzzy`（有選五代時還有 `cangjie5_fuzzy`），排在清單第二位；預設方案仍是 `cangjie3_fluency`。打錯一個相鄰按鍵（例如把 `yhmbc` 打成 `yhmbv`）時，也會列出「顏」，正確的候選永遠排在最前面。
選項：`--no-fuzzy` 不裝；`--fuzzy-range narrow|normal|wide` 範圍；`--fuzzy-default` 讓它排第一。
想要它變成預設方案（不必按 Ctrl+` 或 F4 切換），請改用獨立專案 **cangjie-fuzzy-linux**（同樣內含完整的 cj*fluency，一行指令安裝）。依據與預設值：<https://github.com/githubhjs/cangjie-fuzzy-core/blob/main/DEFAULTS.md>

The adjacent-key schema `cangjie3_fuzzy` (and `cangjie5_fuzzy` with Cangjie 5) is installed too, listed second; `cangjie3_fluency` stays the default. When one key is wrong and it is a physical neighbour (`yhmbv` for `yhmbc`) the intended character is offered as well, and exact candidates always come first.
Options: `--no-fuzzy` skip it; `--fuzzy-range narrow|normal|wide` range; `--fuzzy-default` list it first.
To make it the default schema (no Ctrl+` / F4 needed) use the separate project **cangjie-fuzzy-linux** (it contains the full cj*fluency too; one-line install). Evidence for the defaults: the DEFAULTS.md linked above.

## Cangjie Sweep Pad / 倉頡滑行輸入板

預設會安裝倉頡滑行輸入板（Cangjie Sweep Pad，來自 [githubhjs/cangjie-fuzzy-core](https://github.com/githubhjs/cangjie-fuzzy-core) 的 release 資產 `cangjie-sweep-pad-<PadRef>.zip`）：
- 安裝位置：`~/.local/share/cangjie-sweep`（包含 `cangjie_sweep_pad.py`）。
- 啟動程式：`~/.local/bin/cangjie-sweep-pad`。
- 桌面選單項目：`~/.local/share/applications/cangjie-sweep-pad.desktop`（名稱：「Cangjie Sweep 倉頡滑行」，不自動啟動）。
- 相依套件：Python 3.8+ 與 `python3-tk`，以及按鍵模擬程式（X11 使用 `xdotool`，Wayland 使用 `ydotool`）。
- **Wayland 注意事項**：Wayland 下按鍵注入需要 `ydotool` 與 `/dev/uinput` 的寫入權限（例如執行 `ydotoold` 常駐程式或加入 `uinput` 群組）。在 Wayland 下點擊滑行板視窗時可能會暫時取得視窗焦點。
- 安裝後會自動執行 `python3 cangjie_sweep_pad.py --self-check` 確認環境。
- 選項：使用 `--no-sweep` 可跳過安裝滑行板；`--pad-ref REF` 可指定下載版本。執行 `--uninstall` 會一併移除滑行板資料夾、啟動器與桌面圖示。

The Cangjie Sweep Pad is installed by default (a release asset of [githubhjs/cangjie-fuzzy-core](https://github.com/githubhjs/cangjie-fuzzy-core), `cangjie-sweep-pad-<PadRef>.zip`):
- Install directory: `~/.local/share/cangjie-sweep` (contains `cangjie_sweep_pad.py`).
- Launcher: `~/.local/bin/cangjie-sweep-pad`.
- Desktop entry: `~/.local/share/applications/cangjie-sweep-pad.desktop` ("Cangjie Sweep 倉頡滑行", no autostart).
- Dependencies: Python 3.8+ with `python3-tk`, plus a key injector (`xdotool` on X11, `ydotool` on Wayland).
- **Wayland notice**: Wayland requires `ydotool` and write permissions to `/dev/uinput` (e.g. `ydotoold` daemon or `uinput` group). Note that on Wayland the pad window may take focus when clicked.
- Runs `python3 cangjie_sweep_pad.py --self-check` after installation to verify the environment.
- Options: pass `--no-sweep` to skip installing the pad; pass `--pad-ref REF` to specify a release tag. Running `--uninstall` removes the pad directory, launcher, and desktop entry.

## Changelog / 更新紀錄

- **v0.4.4** — Sweep Pad v0.5.0: optional `--mode commit` types the clicked candidate (Linux/macOS), default unchanged. / 滑行輸入板 v0.5.0：可選的 `--mode commit` 會直接輸入點選的候選字（Linux/macOS），預設行為不變。
- **v0.4.3** — Sweep Pad v0.4.1: candidate row no longer resizes, the sweep trail stays visible. / 滑行輸入板 v0.4.1：候選列不再變高，滑行軌跡不會消失。
- **v0.4.2** — Sweep Pad v0.4.0: single-character backtrack slips decode correctly (decode_auto), word floor 1000. / 滑行輸入板 v0.4.0：單字回頭滑行也能正確解碼（decode_auto），詞頻下限 1000。
- **v0.4.1** — Sweep Pad v0.3.0: tolerance for backtracks. / 滑行輸入板 v0.3.0：容許回頭滑行。
- **v0.4.0** — Sweep Pad added; default on, `--no-sweep` to skip. / 新增倉頡滑行輸入板；預設安裝，加 `--no-sweep` 可略過。
