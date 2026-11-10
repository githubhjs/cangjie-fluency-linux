# Test log (Linux, 2026-11-10)

Machine: Ubuntu 24.04 aarch64 (GX10), librime 1.10 + librime-plugin-octagram from the extracted debs in the main
repo's `rimebin/root` (read-only use), driven by the main repo's `weasel/docs/rime_driver.py` (ctypes, Return is never
pressed, so no user-dictionary learning). No fcitx5 / ibus / fcitx-rime GUI was available: the front end
integration (restart commands, real log locations) is NOT tested here, only install.sh + the librime engine.

Everything below was produced by `bash tests/compile_test.sh` (this repo) and `bash tests/test_install.sh`.
Real downloads: schema files from `githubhjs/cangjie-fluency` at tag `v0.2.0`, `mscj3.cin` from PIME master,
`essay.txt` from rime/rime-essay, `zh-hant-t-essay-bgw.gram` (41,415,724 bytes, size-checked by the installer),
`cangjie5.base.dict.yaml` from rime-cangjie master. Throwaway Rime dir: `testenv/real` (git-ignored).

## 1. Static checks and unit tests

```
shellcheck -x install.sh tests/test_install.sh tests/compile_test.sh      -> no findings (shellcheck 0.11.0 via pip --target, scratch dir)
bash tests/test_install.sh                                               -> passed: 66  failed: 0
```
`tests/test_install.sh` is offline: fake mirror directory (env `CJF_MIRROR_DIR`), stub `fcitx5-remote`/`ibus` on PATH.
It covers fresh install, identical re-run (nothing rewritten, no backup), changed-file re-run (exactly one backup),
default.custom.yaml merges (missing file, LF list, CRLF list without trailing newline, `- {schema: x}` brace style,
different indentation, no schema_list left byte-identical, already listed, only cangjie5_fluency listed),
`--with-cangjie5`, `--no-model`, `--no-deploy`, `--dry-run` (nothing created/changed/run), `--uninstall`.
The fake converter there is not the real one; the real converter is exercised in section 2.

## 2. Real install + librime build + typing

Commands (all inside `tests/compile_test.sh`; `$M` = main repo checkout, `$R` = `$M/rimebin/root`):

```
bash install.sh --frontend fcitx5 --rime-dir testenv/real --with-cangjie5 --no-deploy
rime_deployer --build testenv/real testenv/shared          # shared = prelude yamls only (default.yaml, luna_pinyin, ...)
python3 -I $M/weasel/docs/rime_driver.py --root $R --shared testenv/shared --user testenv/real \
        --base testenv/real/cangjie3.base.dict.yaml --schema cangjie3_fluency --no-commit [--no-grammar] CASES...
```
The shared dir deliberately has no essay.txt / .gram / cangjie base table, so everything the build used was put into
the user dir by install.sh.


### 2a. install.sh output (real downloads; the two warnings are real: this machine has no librime-octagram system plugin and no rime-data in /usr/share)

```
[cangjie-fluency-linux] Rime user directory: /home/hjs/projects/cangjie-fluency-linux/testenv/real (front end: fcitx5)
[cangjie-fluency-linux] WARNING: librime-octagram plugin not found in the usual places.
    Without it the schema still works, but sentence correction is weaker.  Install the plugin:
      Debian / Ubuntu : sudo apt install librime-plugin-octagram        (package exists on Ubuntu 24.04, checked with apt-cache)
      Fedora          : sudo dnf install librime-octagram               (package exists in Fedora rawhide, checked via mdapi)
      Arch Linux      : nothing to install: the official librime package ships librime-octagram.so (checked in librime 1.17.0 file list)
      openSUSE, Gentoo, NixOS, Flatpak, others: unverified, look for a package called librime-octagram / rime-octagram
    Then restart the input method.  librime must load the plugin from its own rime-plugins directory.
[cangjie-fluency-linux] WARNING: rime-data (luna_pinyin, default.yaml) not found. Install it: Debian/Ubuntu 'librime-data' + 'librime-data-luna-pinyin' (checked names: librime-data); Fedora 'rime-data' (unverified); Arch 'librime-data'.
[cangjie-fluency-linux] schema files come from githubhjs/cangjie-fluency at v0.2.0
[cangjie-fluency-linux] installed: cangjie3_fluency.schema.yaml
[cangjie-fluency-linux] installed: cangjie3_fluency.dict.yaml
[cangjie-fluency-linux] essay.txt not found in /home/hjs/projects/cangjie-fluency-linux/testenv/real or /usr/share/rime-data: downloading rime-essay
[cangjie-fluency-linux] installed: essay.txt
[cangjie-fluency-linux] downloading mscj3.cin from PIME and converting it (not redistributed, see README)
[cangjie-fluency-linux] converter: chardef_entries: 22182 multi_char_skipped: 0 duplicates_skipped: 8 malformed_skipped: 0 written: 22174 distinct_chars: 21010 
[cangjie-fluency-linux] installed: cangjie3.base.dict.yaml
[cangjie-fluency-linux] installed: cangjie5_fluency.schema.yaml
[cangjie-fluency-linux] installed: cangjie5_fluency.dict.yaml
[cangjie-fluency-linux] installed: cangjie5.base.dict.yaml
[cangjie-fluency-linux] downloading zh-hant-t-essay-bgw.gram (~41 MB)
[cangjie-fluency-linux] installed: zh-hant-t-essay-bgw.gram
[cangjie-fluency-linux] created default.custom.yaml (cangjie3_fluency cangjie5_fluency first)
[cangjie-fluency-linux] --no-deploy: not restarting the input method.
[cangjie-fluency-linux] Done. Switch to the schema with Ctrl+` (or F4) and pick 'cangjie3_fluency'.
[cangjie-fluency-linux] Check the language model: grep -h 'use grammar' in the Rime log (see README) should show zh-hant-t-essay-bgw.gram.
[cangjie-fluency-linux] finished with 2 warning(s), see above.
```

### 2b. rime_deployer --build (exit 0)

```

real	0m4.868s
user	0m4.664s
sys	0m0.183s
688936 cangjie3_fluency.prism.bin
171704 cangjie3_fluency.reverse.bin
6358 cangjie3_fluency.schema.yaml
15186292 cangjie3_fluency.table.bin
743792 cangjie5_fluency.prism.bin
181944 cangjie5_fluency.reverse.bin
6302 cangjie5_fluency.schema.yaml
17464416 cangjie5_fluency.table.bin
5078 default.yaml
31728 luna_pinyin.prism.bin
252760 luna_pinyin.reverse.bin
42023 luna_pinyin.schema.yaml
13011364 luna_pinyin.table.bin
16936 luna_quanpin.prism.bin
41734 luna_quanpin.schema.yaml
```

### 2c. Accuracy (main repo's sentences.txt 51 + hard.txt 40; model ON then OFF per block)

```
### sentences.txt (51)
== schema=cangjie3_fluency grammar=ON
SUMMARY grammar=ON ok=51 miss=0
== schema=cangjie3_fluency grammar=OFF
SUMMARY grammar=OFF ok=51 miss=0
### hard.txt (40)
== schema=cangjie3_fluency grammar=ON
MISS want=一雙新鞋子 got=一隻新鞋子 keys='m ogeydhmltjggnd'
MISS want=佑你平安 got=知你平安 keys='okronfmfjjv'
MISS want=冇有人知道答案 got=有有人知道答案 keys='kbkbo okrythuhomrjvd'
SUMMARY grammar=ON ok=37 miss=3
== schema=cangjie3_fluency grammar=OFF
MISS want=一雙新鞋子 got=一隻新鞋子 keys='m ogeydhmltjggnd'
MISS want=佑你平安 got=知你平安 keys='okronfmfjjv'
MISS want=冇有人知道答案 got=有有人知道答案 keys='kbkbo okrythuhomrjvd'
SUMMARY grammar=OFF ok=37 miss=3
```

### 2d. Per-key trace: 面 (mwyl) and 板橋 (codes from the generated 3rd-gen table)

```
== schema=cangjie3_fluency grammar=ON
-- trace 面 keys='mwyl'
  after 'm': top='不'
  after 'w': top='要'
  after 'y': top='面'
  after 'l': top='面'
-- trace 板橋 keys='dhedhkb'
  after 'd': top='來'
  after 'h': top='才'
  after 'e': top='皮'
  after 'd': top='才沐'
  after 'h': top='皮才'
  after 'k': top='皮枖'
  after 'b': top='板橋'
```

### 2e. Per-key trace: sentence 我們明天中午去板橋 (model ON, then OFF)

```
== schema=cangjie3_fluency grammar=ON
-- trace 板橋 keys='dhedhkb'
  after 'd': top='來'
  after 'h': top='才'
  after 'e': top='皮'
  after 'd': top='才沐'
  after 'h': top='皮才'
  after 'k': top='皮枖'
  after 'b': top='板橋'
-- trace 我們明天中午去板橋 keys='hqioanabmkl ojgidhedhkb'
  after 'h': top='的'
  after 'q': top='牛'
  after 'i': top='我'
  after 'o': top='牛庂'
  after 'a': top='牛庂是'
  after 'n': top='我們'
  after 'a': top='我僴'
  after 'b': top='我們明'
  after 'm': top='我僴且'
  after 'k': top='我們明天'
  after 'l': top='我們明天中'
  after ' ': top='我們明天中'
  after 'o': top='我們明天中午'
  after 'j': top='我們明天中午'
  after 'g': top='我們明天中午去'
  after 'i': top='我們明天中午去'
  after 'd': top='我們明天中午槷'
  after 'h': top='我們明天中午去才'
  after 'e': top='我們明天中午去皮'
  after 'd': top='我們明天中午去才沐'
  after 'h': top='我們明天中午去皮才'
  after 'k': top='我們明天中午去皮枖'
  after 'b': top='我們明天中午去板橋'
== schema=cangjie3_fluency grammar=OFF
-- trace 板橋 keys='dhedhkb'
  after 'd': top='來'
  after 'h': top='才'
  after 'e': top='皮'
  after 'd': top='才沐'
  after 'h': top='皮才'
  after 'k': top='皮枖'
  after 'b': top='板橋'
-- trace 我們明天中午去板橋 keys='hqioanabmkl ojgidhedhkb'
  after 'h': top='的'
  after 'q': top='牛'
  after 'i': top='我'
  after 'o': top='牛庂'
  after 'a': top='牛庂是'
  after 'n': top='我們'
  after 'a': top='我僴'
  after 'b': top='我們明'
  after 'm': top='我僴且'
  after 'k': top='我們明天'
  after 'l': top='我們明天補'
  after ' ': top='我們明天中'
  after 'o': top='我們明天中午'
  after 'j': top='我們明天中午'
  after 'g': top='我們明天中午去'
  after 'i': top='我們明天中午去'
  after 'd': top='我們明天中午槷'
  after 'h': top='我們明天中午去才'
  after 'e': top='我們明天中午去皮'
  after 'd': top='我們明天中午去才沐'
  after 'h': top='我們明天中午去皮才'
  after 'k': top='我們明天中午去皮枖'
  after 'b': top='我們明天中午去板橋'
```

### 2f. Whole-buffer results (docs/test-log-cangjie3.md examples)

```
== schema=cangjie3_fluency grammar=ON
-- 板橋  keys='dhedhkb'
  buffer: preedit='木竹水 木竹大月' candidates=['板橋', '皮', '板']
-- 中午  keys='l oj'
  buffer: preedit='中 人十' candidates=['中午', '中', '丨']
-- 已經  keys='suvfmvm'
  buffer: preedit='尸山 女火一女一' candidates=['已經', '己經', '妀', '媐', '己']
-- 恐怖  keys='mnppklb'
  buffer: preedit='一弓心 心大中月' candidates=['恐怖', '死', '恐', '丁', '乛']
-- 知道  keys='okrythu'
  buffer: preedit='人大口 卜廿竹山' candidates=['知道', '佑', '知']
-- 我們明天中午去板橋吃飯  keys='hqioanabmkl ojgidhedhkbronoihe'
  buffer: preedit='竹手戈 人日弓 日月 一大 中 人十 土戈 木竹水 木竹大月 口人弓 人戈竹水' candidates=['我們明天中午去板橋吃飯', '我們', '我', '牫', '牛']
-- 這個週末我想要去台北看電影  keys='yymrowjrybgrdjhqidupmwvgiirlmphqbumbwuafhhh'
  buffer: preedit='卜卜一口 人田十口 卜月土口 木十 竹手戈 木山心 一田女 土戈 戈口 中一心 竹手月山 一月田山 日火竹竹竹' candidates=['這個週末我想要去台北看電影', '這個週末', '這個', '這', '卞']
```

### 2g. Compatibility keys: cangjie3_fluency, then cangjie5_fluency

```
== schema=cangjie3_fluency grammar=ON
-- keys='mwyl'
  buffer: preedit='一田卜中' candidates=['面']
-- keys='mwsl'
  buffer: preedit='mwsl' candidates=[]
-- keys='lmyyy'
  buffer: preedit='中一卜卜卜' candidates=['非', '卝']
-- keys='lmsy'
  buffer: preedit='中一 尸卜' candidates=['丄习', '丄']
-- keys='ohs'
  buffer: preedit='人竹尸' candidates=['作']
-- keys='oos'
  buffer: preedit='人人 尸' candidates=['仌區', '仌', '从']
-- keys='okr'
  buffer: preedit='人大口' candidates=['佑', '知']
-- keys='xokr'
  buffer: preedit='xokr' candidates=[]
-- keys='dhedhkb'
  buffer: preedit='木竹水 木竹大月' candidates=['板橋', '皮', '板']
-- keys='l oj'
  buffer: preedit='中 人十' candidates=['中午', '中', '丨']
== schema=cangjie5_fluency grammar=ON
-- keys='mwyl'
  buffer: preedit='mwyl' candidates=[]
-- keys='mwsl'
  buffer: preedit='一田尸中' candidates=['面']
-- keys='lmyyy'
  buffer: preedit='中一卜 卜卜' candidates=['卝卞', '卝']
-- keys='lmsy'
  buffer: preedit='中一尸卜' candidates=['非']
-- keys='ohs'
  buffer: preedit='人竹 尸' candidates=['入駐', '入局', '入耳', '入聖', '入羣']
-- keys='oos'
  buffer: preedit='人人尸' candidates=['作']
-- keys='okr'
  buffer: preedit='人大口' candidates=['知', '佑']
-- keys='xokr'
  buffer: preedit='難人大口' candidates=['佑']
-- keys='dhedhkb'
  buffer: preedit='木竹水 木竹大月' candidates=['板橋', '板', '皮']
-- keys='l oj'
  buffer: preedit='中 人十' candidates=['中午', '中', '丨']
```

### 2h. Rime log (testenv/real/log/rime.cangjie-fluency-test.INFO)

```
I20261110 18:13:05.006874 2501273 octagram.cc:29] use grammar: zh-hant-t-essay-bgw
I20261110 18:13:05.011658 2501273 octagram.cc:29] use grammar: zh-hant-t-essay-bgw
```

### 2i. --no-model install, plugin loaded but no .gram (51 sentences; last line = count of 'use grammar' log lines)

```
E20261110 18:13:09.951716 2501952 mapped_file.cc:78] attempt to open non-existent file '"/home/hjs/projects/cangjie-fluency-linux/testenv/nomodel/zh-hant-t-essay-bgw.gram"'.
E20261110 18:13:09.951771 2501952 gram_db.cc:20] error opening gram db '"/home/hjs/projects/cangjie-fluency-linux/testenv/nomodel/zh-hant-t-essay-bgw.gram"'.
E20261110 18:13:09.951776 2501952 octagram.cc:180] failed to load grammar database: zh-hant-t-essay-bgw
E20261110 18:13:09.956383 2501952 mapped_file.cc:78] attempt to open non-existent file '"/home/hjs/projects/cangjie-fluency-linux/testenv/nomodel/zh-hant-t-essay-bgw.gram"'.
E20261110 18:13:09.956393 2501952 gram_db.cc:20] error opening gram db '"/home/hjs/projects/cangjie-fluency-linux/testenv/nomodel/zh-hant-t-essay-bgw.gram"'.
E20261110 18:13:09.956399 2501952 octagram.cc:180] failed to load grammar database: zh-hant-t-essay-bgw
== schema=cangjie3_fluency grammar=ON
SUMMARY grammar=ON ok=51 miss=0
2
```

## 3. What this shows, and what it does not

* Same numbers as the main repo log (docs/test-log-cangjie3.md): 51/51 sentences, 37/40 hard (the 3 misses are same-code collisions 雙/隻, 佑/知, 冇/有), 面 = `mwyl`, 板橋 = `dhedhkb`, 中午 = `l oj`. The installer-built table behaves like the one built by hand there.
* Model effect: the model-ON and model-OFF runs agree on every sentence in the test sets; the language model matters little on these sentences (it only changes some intermediate states, e.g. after the `l` key of the long trace).
* **`use grammar:` alone is not proof that the model loaded.** In 2i the .gram file is missing, yet the log still contains `octagram.cc:29] use grammar: zh-hant-t-essay-bgw` (2 lines) and, right after it, `E ... octagram.cc:180] failed to load grammar database: zh-hant-t-essay-bgw`. The README therefore checks for BOTH: the `use grammar` line present and no `failed to load grammar database` line.
* A missing .gram does not break typing (2i: 51/51).
* NOT tested: fcitx5-rime, fcitx-rime, ibus-rime themselves (no GUI session/package here), `fcitx5-remote -r` and `ibus restart` behaviour, Flatpak paths, real log file locations of those front ends, other distributions, x86_64 (only aarch64 run), the `curl | bash` one-liner against the published repo (only `cat install.sh | bash -s` locally, because the GitHub repo does not exist yet).
* Not compared: whether mscj3.cin equals Windows XP 新倉頡 exactly (inherited limitation, see the main repo).


## 5. Self-contained rework (2026-11-10): everything from the main repo, no third party

Sections above describe the earlier installer that downloaded the table, word list and model from PIME, rime-essay and
rime-octagram-data. The installer now takes **every** file from the main repo (bundle layout next to the script, else
`raw.githubusercontent.com/githubhjs/cangjie-fluency/<ref>/`, default `v0.4.0`), checks SHA-256 of the tables, essay.txt and model,
always converts with the repo's `data/essay.txt` (so the table is identical everywhere), and installs engine packages with the
distribution's own package manager unless `--no-deps`. `--offline` never touches the network.

### 5a. Installer tests, `bash tests/test_install.sh`: 84 passed, 0 failed

Uses the real main-repo files (real tables, real 41,415,724-byte model, real hashes) as the bundle (`CJF_SRC_DIR`), a throwaway Rime dir
and stub `curl`/`wget`/`sudo`/`apt-get`. Highlights (all passed):

* full bundle `--offline`: exit 0, model installed (41,415,724 B), **zero calls to the curl/wget stubs**, table byte-identical to
  `python3 tools/cin2rime.py tables/mscj3.cin ... --essay data/essay.txt`;
* `--offline` without a bundle: fails with a message naming `--offline`, still zero network calls;
* online without a bundle (`--ref main`, stubs fail): curl was asked for
  `https://raw.githubusercontent.com/githubhjs/cangjie-fluency/main/weasel/cangjie3_fluency.schema.yaml`, and every URL contacted
  contains `githubhjs/cangjie-fluency` (nothing else);
* a table with one extra line: `SHA-256 mismatch`, install stops, no generated table;
* a system `essay.txt` present: not copied to the user dir, table still byte-identical (built from the repo essay);
* engine packages: `--dry-run` names `sudo apt-get install -y ibus-rime` and runs nothing; a real run calls the stubbed
  `sudo apt-get install -y ibus-rime`; `--no-deps` does not call the package manager;
* the earlier checks (re-run changes nothing, one backup per changed file, `default.custom.yaml` merge cases LF/CRLF/brace/indent/
  no list/already listed/only cangjie5_fluency, dry-run, uninstall) still pass;
* `install.sh` contains no `EasyIME|PIME|rime/rime-|lotem/|Homebrew|winget`.

### 5b. Real librime compile test, `bash tests/compile_test.sh /home/hjs/projects/cangjie-fluency`

`install.sh --offline --no-deps` from the main-repo files into a fresh dir (no system essay.txt visible), `rime_deployer --build`
(5.1 s; cangjie3_fluency.table.bin 15,186,292 B, prism 688,936 B; the same two schemas as before), then the driver key by key:

```
### sentences.txt (51):  SUMMARY grammar=ON ok=51 miss=0     SUMMARY grammar=OFF ok=51 miss=0
### hard.txt (40):       SUMMARY grammar=ON ok=37 miss=3     SUMMARY grammar=OFF ok=37 miss=3
   (misses: 一雙新鞋子 got 一隻, 佑你平安 got 知你平安, 冇有人知道答案 got 有有人知道答案: same-code collisions, identical to before)
-- trace 面 keys='mwyl':   after 'm' top='不', 'w' '要', 'y' '面'; final keys='mwyl' candidates=['面']
-- trace 板橋 keys='dhedhkb': 來, 才, 皮, 才沐, 皮才, 皮枖, 板橋
-- keys='l oj': preedit='中 人十' candidates=['中午', '中', '丨']
log: octagram.cc:29] use grammar: zh-hant-t-essay-bgw
--no-model install: builds and types; 'failed to load grammar database' logged as expected (no .gram present)
```

An earlier run of this test showed 39/51 because this machine has a system `/usr/share/rime-data/essay.txt`, so the installer
(correctly) did not copy essay.txt into the user dir while the test's librime build looked only in the test's own shared dir;
`compile_test.sh` now hides system dirs from the installer (`RIME_SHARED_DIRS`), which is what a machine without a system essay.txt sees.

### 5c. Release zips, `./make-release.sh /home/hjs/projects/cangjie-fluency v0.4.0`

```
38367253 dist/cangjie-fluency-linux-v0.4.0-full.zip
   29027 dist/cangjie-fluency-linux-v0.4.0-slim.zip
```

The builder refuses to run if the SHA-256 of a shipped table/essay/model is not the one pinned in `install.sh`.
Full zip unzipped into a temp dir, then `bash install.sh --offline --no-deps --frontend fcitx5 --rime-dir <tmp> --no-deploy` with
stub curl/wget/sudo first in PATH: installed `cangjie3_fluency.schema.yaml`, `.dict.yaml`, `essay.txt` (5,887,319), `cangjie3.base.dict.yaml`
(286,151), `zh-hant-t-essay-bgw.gram` (41,415,724), `default.custom.yaml`; stub log empty (0 network calls); the table is byte-identical to the
python converter's output.

### 5d. Not verified

* `shellcheck` is not installed on this machine: only `bash -n` was run on the scripts.
* The package-manager step was never run against real repositories (stubs only); dnf/pacman/zypper names unverified.
* No fcitx5/fcitx test; GUI typing not tested; x86_64 untested.
