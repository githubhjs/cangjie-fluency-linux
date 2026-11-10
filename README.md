# cangjie-fluency-linux

Microsoft-style sentence input for full Cangjie on Linux: type a whole phrase of Cangjie codes, the buffer
re-segments and auto-corrects as you type, Enter commits. No picking a character after every code.
It is a [Rime](https://rime.im) schema set up for **fcitx5-rime, fcitx-rime and ibus-rime**.

This repository is only the Linux installer and notes. The schema, the engine settings and the converter live in the
main repository, [githubhjs/cangjie-fluency](https://github.com/githubhjs/cangjie-fluency) (Windows/Weasel first); the
installer downloads them from there at a pinned tag (`v0.2.0`), nothing is duplicated here.

繁體中文說明在[文件後半](#繁體中文)。

## Why the 3rd generation (三代)

The "新倉頡" that ships with Windows XP is a modified **3rd-generation** Cangjie. The 5th-generation table that most
Rime schemas use differs in roughly a fifth of the codes (面 is `mwyl` in 3rd gen and `mwsl` in 5th gen; 作 `ohs` vs `oos`;
非 `lmyyy` vs `lmsy`). So the default schema here is **`cangjie3_fluency`**. The 5th-generation variant
`cangjie5_fluency` is available as an option (`--with-cangjie5`).

## Install

One line (normal user, no sudo; it only writes into your Rime user directory):

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

What it does: checks `python3` and `curl`/`wget` -> finds your front end and Rime user directory -> checks that the
`librime-octagram` plugin is present (tells you how to install it if not) -> downloads the schema files and
`tools/cin2rime.py` from the main repo at the pinned tag -> downloads PIME's `mscj3.cin` and converts it **on your
machine** into `cangjie3.base.dict.yaml` using `essay.txt` frequencies -> downloads the 41,415,724-byte language model
`zh-hant-t-essay-bgw.gram` (size-checked) -> puts `cangjie3_fluency` first in `default.custom.yaml` -> redeploys.

Options:

| option | meaning |
|---|---|
| `--frontend fcitx5\|fcitx\|ibus\|auto` | default `auto` (running daemon, then existing directory, then installed program) |
| `--rime-dir DIR` (or env `RIME_DIR`) | install into `DIR`, for testing or unusual setups; nothing is restarted unless you also give `--frontend` |
| `--ref TAG` | which tag/branch of the main repo to take the schema files from (default `v0.2.0`) |
| `--with-cangjie5` | also install `cangjie5_fluency` (+ `cangjie5.base.dict.yaml` from rime/rime-cangjie master) |
| `--no-model` | skip the 41 MB language model |
| `--no-deploy` | copy files only |
| `--dry-run` | print what would happen, change and download nothing |
| `--uninstall` | remove only the files this installer created (it keeps a manifest); backups are kept |

Safety properties (covered by `tests/test_install.sh`, 66 checks): re-running with identical content rewrites nothing and
makes no backup; a changed file gets exactly one `NAME.bak-<timestamp>`; your `default.custom.yaml` is never overwritten.
If it already has a `schema_list:`, the installer backs the file up and inserts `- schema: cangjie3_fluency` as the
**first** entry, keeping your indentation, line endings (LF/CRLF), the `- {schema: x}` brace style and a missing final
newline. If `cangjie3_fluency` is already listed nothing is added (exact id match). If the file has no block-style
`schema_list:` it is not touched and the installer prints what to add. Without a `default.custom.yaml` it creates one
listing `cangjie3_fluency` and `luna_pinyin` (a patched `schema_list` replaces the stock list, so add the schemas you
use).

## Prerequisites per distribution

You need Rime for your input method framework, the shared data (`default.yaml`, `luna_pinyin`, ...) and the
**octagram plugin** for the language model. Without the plugin the schema still types correctly, only the sentence
correction is weaker (on the test sentences the difference was small, see `docs/test-log.md`).

| | install | status |
|---|---|---|
| Debian / Ubuntu | `sudo apt install fcitx5-rime librime-plugin-octagram` (or `ibus-rime` / `fcitx-rime`) | packages `fcitx5-rime`, `ibus-rime`, `fcitx-rime`, `librime-plugin-octagram`, `librime-data` seen with `apt-cache` on Ubuntu 24.04 (noble); not installed or run on a desktop here |
| Fedora | `sudo dnf install fcitx5-rime librime-octagram` | `librime-octagram` exists in rawhide (checked via mdapi.fedoraproject.org); `fcitx5-rime` name **unverified** |
| Arch Linux | `sudo pacman -S fcitx5-rime` (or `ibus-rime`) | the official `librime` package (1.17.0) contains `librime-octagram.so` (checked in its file list), so no extra package; `fcitx5-rime` exists in `extra` |
| openSUSE, Gentoo, NixOS, others | look for `librime-octagram` | **unverified** |
| Flatpak Fcitx5 | `--frontend fcitx5-flatpak` uses `~/.var/app/org.fcitx.Fcitx5/data/fcitx5/rime` | path **unverified**, never run; whether the Flatpak's bundled librime has octagram is unknown |

User directories used (override with `--rime-dir`): fcitx5-rime `~/.local/share/fcitx5/rime`, fcitx-rime
`~/.config/fcitx/rime`, ibus-rime `~/.config/ibus/rime`. These are the standard locations from the Rime documentation and
the packages' defaults; the installer itself only ran against throwaway directories here, **not against a live fcitx5,
fcitx or ibus**.

## Deploy, switch, verify

The installer ends with a deploy step unless you pass `--no-deploy`:

| front end | command run | verified here? |
|---|---|---|
| fcitx5 | `fcitx5-remote -r` (reload). If the schema does not show up or looks old, restart Fcitx5 completely, or use **Deploy** in the Rime tray menu | **unverified** (no fcitx5 available); a full restart may be needed |
| ibus | `ibus restart` (ibus-rime redeploys on start when files changed); alternatively **Deploy** from its menu, or `rime_deployer --build <user dir> /usr/share/rime-data` | **unverified** |
| fcitx (4) | `fcitx-remote -r` | **unverified** |

The first deploy compiles the dictionary (about 5 seconds on the test machine for both schemas, producing a 15 MB table).

**Switch schema:** press `Ctrl+`` (grave) or `F4`, pick "倉頡三代整句" (`cangjie3_fluency`). In fcitx5 you can also use
the Rime menu in the tray. (Hotkeys are Rime's defaults; another program may grab them.)

**Verify the language model loaded.** Look at the Rime log after switching to the schema:

```sh
grep -h 'use grammar\|failed to load grammar' $(ls -t /tmp/rime.*INFO* 2>/dev/null | head -3)
```

Healthy: a line `octagram.cc:29] use grammar: zh-hant-t-essay-bgw` and **no** `failed to load grammar database`.
Careful: the `use grammar` line is also printed when the `.gram` file is missing; the real failure shows up as
`E... octagram.cc:180] failed to load grammar database: zh-hant-t-essay-bgw` right after it (seen in `docs/test-log.md`,
section 2i). No `use grammar` line at all means the octagram plugin was not loaded.

Where the logs are: librime writes `rime.<app>.<host>.<user>.log.INFO.<date>-<time>.<pid>` files (glog). For **ibus-rime
this is verified**: `/tmp/rime.ibus.<host>.<user>.log.INFO.<date>-<time>.<pid>` (plus `rime.ibus.INFO` symlinks), Ubuntu 24.04. For
fcitx5-rime (`rime.fcitx5`) it is **unverified**. glog buffers the INFO file, so the `use grammar` line can show up late: it was
written at the first schema load but only appeared in the file once the engine had run for a while or exited. If you see nothing,
wait about 30 s or stop the engine, then grep again. If `/tmp` has nothing, run
`find / -name 'rime.*INFO*' -mmin -30 2>/dev/null` after switching to the schema. The same check on Windows is in the
main repo's README.

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

(Typing behaviour is the engine's; these notes come from the main repo's tests on Linux librime 1.10 and a Windows 11
run of the 5th-gen variant, plus the live ibus test below.)

**Live test, ibus-rime (2026-11-10).** Ubuntu 24.04 aarch64, IBus 1.5.29-rc2, ibus-rime 1.5.0, librime 1.10.0 with the Ubuntu
`librime-plugin-octagram`, installed with this repo's one-line installer (`--frontend ibus`) and driven through the IBus API
(`tests/ibus_live_test.py`: real key events into an input context bound to the `rime` engine, preedit, candidates and committed
text read back). **10 of 10 cases passed**: 面 `mwyl`, 非 `lmyyy`, 作 `ohs`; `okr` offers 佑 then 知; 板橋 `dhedhkb`; 中午 `l oj`;
and four whole sentences typed continuously with no space and no candidate selection came out exactly as written
(我們明天中午去板橋吃飯, 今天天氣很好, 請問這個問題怎麼解決, 他說的話我不太明白; codes taken from the generated table).
The log shows `loaded plugin: octagram`, `use grammar: zh-hant-t-essay-bgw`, no `failed to load grammar` and no `E` lines.
It was **not** a GUI test (no text box, no candidate window): see the limits below.

## Known limits

* **fcitx5-rime and fcitx-rime were not tested; ibus-rime was tested through the IBus API only** (no GUI, no candidate window,
  one machine: Ubuntu 24.04 aarch64 with GNOME on Xorg, ibus-daemon started by hand). The installer also ran for real
  (offline unit tests + real downloads + a real run on that machine); the schema was also compiled and driven key by key
  with librime 1.10, see `docs/test-log.md`.
* Whether PIME's `mscj3.cin` is identical to Windows XP's table is **unverified** (only 面, 非, 作, 知/佑 were checked).
* Same-code characters are decided by frequency only (e.g. 雙/隻, 佑/知, 冇/有 are wrong in the main repo's hard test set).
* Digits, symbols and uppercase letters typed into an empty buffer land in the buffer instead of going straight to the
  application (inherited from the main repo's design, see its docs).
* Only a `block style` `schema_list:` is edited automatically; an inline `schema_list: [ ... ]` or `schema_list/+:` patch
  is left alone with instructions.
* x86_64 and other distributions are untested (the compile test ran on aarch64 only).

## Uninstall

```sh
bash install.sh --uninstall                 # or: --frontend ibus / --rime-dir DIR to pick the directory
```

Removes only what the installer wrote (listed in `.cangjie-fluency-linux.manifest` in the Rime directory), keeps every
`*.bak-*` backup, and removes `default.custom.yaml` only if the installer created it and it is unchanged. If it merely
edited your existing `default.custom.yaml`, delete the `- schema: cangjie3_fluency` line yourself (the pre-edit copy is
`default.custom.yaml.bak-<time>`). Then redeploy.

## Tests

```sh
bash tests/test_install.sh          # offline, stubbed front end, 66 checks
bash tests/compile_test.sh [DIR]    # real downloads + librime build; needs the main repo checkout (rimebin/, rime_driver.py)
```

## Credits and licensing

* Chu Bong-Foo (朱邦復), inventor of Cangjie, publicly waived the patent in 1982.
* [rime/rime-cangjie](https://github.com/rime/rime-cangjie) and [rime/rime-quick](https://github.com/rime/rime-quick) (LGPL-3.0).
* [cangjie-system/rime-cangjie-integrated](https://github.com/cangjie-system/rime-cangjie-integrated) (MIT): a collection of Cangjie tables
  for Rime (3rd generation, Microsoft-style, Yahoo, 5th and 6th generation) and the guide most Linux users follow. It is a plain table
  input method; this project adds the sentence-style (auto-correcting buffer) mode on top of the same ideas. Its
  `cangjie.3-ms.dict.yaml` (a Vista Microsoft Cangjie table) agrees with the PIME `mscj3.cin` we download on 98% of the shared
  characters and on the candidate order, which is why we trust that table to be the Microsoft 3rd-generation one.
* eight04's `quick5_fluency` prototype, [rime/rime-quick#2](https://github.com/rime/rime-quick/issues/2).
* The 3rd-generation table comes from [PIME](https://github.com/EasyIME/PIME)'s `mscj3.cin`.
  **That file carries no licence header, so it is not stored or redistributed in this repository.** The installer
  downloads it from PIME on your machine and converts it there; the generated `cangjie3.base.dict.yaml` is listed in
  `.gitignore` for the same reason. Do not commit either.
* Language model: [lotem/rime-octagram-data](https://github.com/lotem/rime-octagram-data) (`hant` branch),
  vocabulary: [rime/rime-essay](https://github.com/rime/rime-essay).
* This repository: LGPL-3.0, see `LICENSE`.

Engine and schema documentation: [githubhjs/cangjie-fluency](https://github.com/githubhjs/cangjie-fluency)
(`weasel/README.zh-TW.md`, `weasel/docs/`).

---

# 繁體中文

## 這是什麼

在 Linux（fcitx5-rime、fcitx-rime、ibus-rime）上提供「微軟新倉頡」手感的整句輸入：連續打完一整串倉頡碼，
緩衝區會自動重新斷詞、修正前面的字，Enter 上屏，不必每個字選字。方案和引擎設定放在主倉庫
[githubhjs/cangjie-fluency](https://github.com/githubhjs/cangjie-fluency)（先做 Windows 小狼毫版），本倉庫只有 Linux 安裝腳本，
安裝時從主倉庫的固定標籤（`v0.2.0`）下載，不複製檔案。

## 為什麼是三代

Windows XP 內建的「新倉頡」是改良過的**三代**倉頡。多數 Rime 方案用的五代碼表和三代約有兩成字碼不同
（「面」三代 `mwyl`、五代 `mwsl`；「作」`ohs` / `oos`；「非」`lmyyy` / `lmsy`）。所以預設方案是 **`cangjie3_fluency`**，
五代版 `cangjie5_fluency` 用 `--with-cangjie5` 另外裝。

## 安裝

一行（一般使用者，不需要 sudo，只寫入 Rime 使用者資料夾）：

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

腳本會：檢查 `python3`、`curl`/`wget` → 偵測前端與 Rime 資料夾 → 檢查 `librime-octagram` 外掛（沒有會告訴你怎麼裝）→
從主倉庫下載方案檔與 `tools/cin2rime.py` → 從 PIME 下載 `mscj3.cin`，在**你的電腦上**用 `essay.txt` 詞頻轉成
`cangjie3.base.dict.yaml` → 下載語言模型 `zh-hant-t-essay-bgw.gram`（41,415,724 位元組，會核對大小）→
把 `cangjie3_fluency` 放進 `default.custom.yaml` 方案清單的**第一個** → 重新部署。

重複執行是安全的：內容相同的檔案不會重寫、不會備份；內容不同的檔案只備份一次（`檔名.bak-時間`）。
你已有的 `default.custom.yaml` 不會被覆蓋：有 `schema_list:` 就先備份再插入第一項（保留縮排、LF/CRLF、`- {schema: x}`
寫法與結尾沒有換行的狀況）；已經列了就不動；沒有 `schema_list:` 就不碰，只印出要加什麼。

## 各發行版套件

| | 指令 | 狀態 |
|---|---|---|
| Debian / Ubuntu | `sudo apt install fcitx5-rime librime-plugin-octagram`（或 `ibus-rime`、`fcitx-rime`） | 套件名稱已在 Ubuntu 24.04 用 `apt-cache` 確認；沒有在實際桌面上安裝執行 |
| Fedora | `sudo dnf install fcitx5-rime librime-octagram` | `librime-octagram` 已查證存在（rawhide）；`fcitx5-rime` 名稱**未驗證** |
| Arch Linux | `sudo pacman -S fcitx5-rime`（或 `ibus-rime`） | 官方 `librime` 套件已內含 `librime-octagram.so`（已查檔案清單），不必另外裝 |
| 其他、Flatpak | 找 `librime-octagram` | **未驗證** |

資料夾：fcitx5-rime `~/.local/share/fcitx5/rime`、fcitx-rime `~/.config/fcitx/rime`、ibus-rime `~/.config/ibus/rime`
（Flatpak Fcitx5 的路徑 `~/.var/app/org.fcitx.Fcitx5/data/fcitx5/rime` **未驗證**）。

## 部署、切換、確認語言模型

* fcitx5：腳本執行 `fcitx5-remote -r`；若方案沒出現，請完整重啟 Fcitx5，或在托盤的 Rime 選單按「部署」（**未驗證**）。
* ibus：腳本執行 `ibus restart`，或在選單按「部署」（**未驗證**）。fcitx 4：`fcitx-remote -r`（**未驗證**）。
* 切換方案：`Ctrl+`` 或 `F4`，選「倉頡三代整句」。
* 確認語言模型：切到方案後看 Rime 日誌，
  `grep -h 'use grammar\|failed to load grammar' $(ls -t /tmp/rime.*INFO* 2>/dev/null | head -3)`。
  正常：有 `use grammar: zh-hant-t-essay-bgw`，而且**沒有** `failed to load grammar database`。
  注意：`.gram` 檔不見時 `use grammar` 這行仍會出現，緊接著才是 `failed to load grammar database` 錯誤（測試紀錄 2i）。
  完全沒有 `use grammar` = 外掛沒載入。日誌通常在 `/tmp`（`rime.ibus.*`、`rime.fcitx5.*`），這點是憑印象，**未驗證**。

## 打法

* 一路打字根：`dhedhkb` → `板橋`，繼續打會自動修正前面的字。
* **只有一個字根的字後面要接空格**：「中」是 `l`，「中午」打 `l oj`；其他字碼之間空格可有可無。
* Enter 上屏整句；`，` `。` `！` `？`（`,` `.` `!` `?`）會先上屏整句再接標點。
* Backspace 退一個字根，Esc 清空；同碼字（三代的 佑/知 同為 `okr`）靠詞頻排序，錯了就選第二候選。
* 三代沒有「難」（X）前綴，那是五代的設計。

## 已知限制

* **沒有在實際的 fcitx5／fcitx／ibus 裡測過。** 測過的是安裝腳本（離線單元測試加真實下載）和用 librime 1.10 在
  Ubuntu 24.04 aarch64 逐鍵編譯、輸入（見 `docs/test-log.md`）。
* PIME 的 `mscj3.cin` 是否與 Windows XP 的碼表完全一致：**未驗證**（只核對了 面、非、作、知/佑）。
* 同碼字只靠詞頻（雙/隻、佑/知、冇/有 在主倉庫的困難測試集中會錯）。
* 空緩衝區時打的數字、符號、大寫字母會進緩衝區，不會直接送到應用程式。

## 解除安裝

`bash install.sh --uninstall`：只刪除本腳本建立的檔案（記錄在 Rime 資料夾的 `.cangjie-fluency-linux.manifest`），保留所有
`*.bak-*` 備份。若只是改了你原本的 `default.custom.yaml`，請自己刪掉 `- schema: cangjie3_fluency` 那行（原檔備份在
`default.custom.yaml.bak-時間`），再重新部署。

## 來源與授權

* 倉頡由朱邦復先生創製，他已於 1982 年公開放棄專利權。
* 另外感謝 [cangjie-system/rime-cangjie-integrated](https://github.com/cangjie-system/rime-cangjie-integrated)（MIT）：
  整理了三代、微軟、雅虎、五代、六代等 Rime 倉頡碼表，也是多數 Linux 使用者照著做的指南。它是一般的碼表輸入法，本專案在同樣的基礎上補上整句自動修正。
  它的 `cangjie.3-ms.dict.yaml`（Vista 微軟倉頡碼表）和我們下載的 PIME `mscj3.cin` 在共同的字上有 98% 碼相同、候選順序也相同。
* 基於 [rime/rime-cangjie](https://github.com/rime/rime-cangjie)、[rime/rime-quick](https://github.com/rime/rime-quick)，
  以及 eight04 在 [rime-quick#2](https://github.com/rime/rime-quick/issues/2) 的 `quick5_fluency` 原型；三代碼表來自 PIME 的 `mscj3.cin`。
* **`mscj3.cin` 沒有授權聲明，所以不放在本倉庫**，安裝時才從 PIME 下載並在你的電腦上轉換；轉出的
  `cangjie3.base.dict.yaml` 也在 `.gitignore` 裡，請不要提交。
* 授權：LGPL-3.0，見 `LICENSE`。引擎與方案細節請看主倉庫 `weasel/README.zh-TW.md`。
