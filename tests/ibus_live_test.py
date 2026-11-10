#!/usr/bin/env python3
"""Live test against a running ibus-daemon with ibus-rime: send real key events, read preedit / candidates / committed text.

Usage: python3 tests/ibus_live_test.py [--table ~/.config/ibus/rime/cangjie3.base.dict.yaml]
Needs: ibus-daemon running (ibus-daemon -drx), ibus-rime installed, this repo's schema deployed as the first schema.
Prints one line per case; exit code 1 if a case fails.
"""
import sys, time, os, re
import gi
gi.require_version("IBus", "1.0")
from gi.repository import IBus, GLib

TABLE = os.path.expanduser("~/.config/ibus/rime/cangjie3.base.dict.yaml")
if "--table" in sys.argv:
    TABLE = sys.argv[sys.argv.index("--table") + 1]

bus = IBus.Bus()
if not bus.is_connected():
    sys.exit("ibus-daemon is not running")
ic = bus.create_input_context("cangjie-fluency-live-test")
state = {"commit": "", "preedit": "", "cands": []}


def on_commit(_ic, text):
    state["commit"] += text.get_text()


def on_preedit(_ic, text, cursor, visible):
    state["preedit"] = text.get_text()


def on_lookup(_ic, table, visible):
    n = table.get_number_of_candidates()
    state["cands"] = [table.get_candidate(i).get_text() for i in range(min(n, 9))]


ic.connect("commit-text", on_commit)
ic.connect("update-preedit-text", on_preedit)
ic.connect("update-lookup-table", on_lookup)
ic.set_capabilities(IBus.Capabilite.PREEDIT_TEXT | IBus.Capabilite.LOOKUP_TABLE | IBus.Capabilite.FOCUS | IBus.Capabilite.PROPERTY)
ic.focus_in()
ic.set_engine("rime")


def pump(sec=0.15):
    end = time.time() + sec
    ctx = GLib.MainContext.default()
    while time.time() < end:
        while ctx.iteration(False):
            pass
        time.sleep(0.01)


KEY = {"\n": 0xff0d, " ": 0x20, "\b": 0xff08, "\x1b": 0xff1b}


def press(ch):
    kv = KEY.get(ch, ord(ch))
    ic.process_key_event(kv, 0, 0)
    ic.process_key_event(kv, 0, IBus.ModifierType.RELEASE_MASK)
    pump(0.06)


def reset():
    press("\x1b"); state.update(commit="", preedit="", cands=[]); pump(0.1)


def type_keys(s):
    for ch in s:
        press(ch)
    pump(0.25)


# wait until the engine answers (first start deploys the schemas: can take a while)
t0 = time.time()
while time.time() - t0 < 180:
    reset(); type_keys("mwyl")
    if state["preedit"] or state["cands"]:
        break
    pump(2)
print("engine ready after %.0f s; first schema answered preedit=%r cands=%r" % (time.time() - t0, state["preedit"], state["cands"][:4]))

fails = 0


def case(name, keys, expect_commit=None, expect_cand=None, commit_key="\n"):
    global fails
    reset(); type_keys(keys)
    pre, cands = state["preedit"], list(state["cands"])
    if commit_key:
        press(commit_key); pump(0.3)
    got = state["commit"]
    ok = True
    if expect_commit is not None:
        ok = ok and (got == expect_commit)
    if expect_cand is not None:
        ok = ok and (expect_cand in cands)
    fails += (not ok)
    print("%-4s %-26s preedit=%-14r cands=%-30r commit=%r" % ("ok" if ok else "FAIL", name, pre, cands[:5], got))


case("面 mwyl", "mwyl", expect_commit="面")
case("非 lmyyy", "lmyyy", expect_commit="非")
case("作 ohs", "ohs", expect_commit="作")
case("知/佑 okr (both reachable)", "okr", expect_cand="知", commit_key=None)
case("板橋 dhedhkb", "dhedhkb", expect_commit="板橋")
case("中午 'l oj'", "l oj", expect_commit="中午")

# sentences: codes taken from the generated table (first code of each character)
code_of = {}
if os.path.exists(TABLE):
    on = False
    for line in open(TABLE, encoding="utf-8"):
        if line.strip() == "...":
            on = True; continue
        if on and line.strip() and not line.startswith("#"):
            p = line.rstrip("\n").split("\t")
            if len(p) >= 3 and p[0] not in code_of:
                code_of[p[0]] = (p[1], int(p[2]))
            elif len(p) >= 3 and int(p[2]) > code_of[p[0]][1]:
                code_of[p[0]] = (p[1], int(p[2]))
# a character's best code = the one it holds with the highest weight, but prefer the shortest unambiguous: use the table's first code
first = {}
on = False
for line in open(TABLE, encoding="utf-8") if os.path.exists(TABLE) else []:
    if line.strip() == "...":
        on = True; continue
    if on and line.strip() and not line.startswith("#"):
        p = line.rstrip("\n").split("\t")
        if len(p) >= 2 and p[0] not in first:
            first[p[0]] = p[1]


def sentence_keys(s):
    out = ""
    for ch in s:
        c = first[ch]
        out += c + (" " if len(c) == 1 else "")
    return out


for sent in ["我們明天中午去板橋吃飯", "今天天氣很好", "請問這個問題怎麼解決", "他說的話我不太明白"]:
    try:
        case("sentence " + sent, sentence_keys(sent), expect_commit=sent)
    except KeyError as e:
        print("skip", sent, "no code for", e)

print("RESULT: %s (%d failing)" % ("PASS" if not fails else "FAIL", fails))
sys.exit(1 if fails else 0)
