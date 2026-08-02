#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

lua_bin="${LUA_BIN:-}"
luac_bin="${LUAC_BIN:-}"

if [[ -z "$lua_bin" ]]; then
    if command -v lua5.1 >/dev/null 2>&1; then
        lua_bin="lua5.1"
    else
        lua_bin="lua"
    fi
fi

if [[ -z "$luac_bin" ]]; then
    if command -v luac5.1 >/dev/null 2>&1; then
        luac_bin="luac5.1"
    else
        luac_bin="luac"
    fi
fi

mapfile -t lua_files < <(find . -type f -name '*.lua' -not -path './.git/*' -print | sort)
for file in "${lua_files[@]}"; do
    "$luac_bin" -p "$file"
done

for test_file in tests/test_*.lua; do
    "$lua_bin" "$test_file"
done

vanilla_files="$(sed -n '/^[^#[:space:]].*\.lua$/p' SimpleArsenalSwap.toc)"
tbc_files="$(sed -n '/^[^#[:space:]].*\.lua$/p' SimpleArsenalSwap_TBC.toc)"

if [[ "$vanilla_files" != "$tbc_files" ]]; then
    echo "TOC Lua load orders differ between Vanilla and TBC." >&2
    exit 1
fi

while IFS= read -r toc_file; do
    source_file="${toc_file//\\//}"
    if [[ ! -f "$source_file" ]]; then
        echo "TOC references missing file: $source_file" >&2
        exit 1
    fi
done <<< "$vanilla_files"

grep -qx '## Interface: 11509' SimpleArsenalSwap.toc
grep -qx '## Version: 0.1.0' SimpleArsenalSwap.toc
grep -qx '## X-Curse-Project-ID: 1636432' SimpleArsenalSwap.toc
grep -qx '## SavedVariablesPerCharacter: SimpleArsenalSwapDB' SimpleArsenalSwap.toc
grep -qx '## X-Flavor: Vanilla' SimpleArsenalSwap.toc
grep -qx '## AllowLoadGameType: vanilla' SimpleArsenalSwap.toc
grep -Fqx '## IconTexture: Interface\AddOns\SimpleArsenalSwap\assets\logo' SimpleArsenalSwap.toc
grep -qx '## Interface: 20506' SimpleArsenalSwap_TBC.toc
grep -qx '## Version: 0.1.0' SimpleArsenalSwap_TBC.toc
grep -qx '## X-Curse-Project-ID: 1636432' SimpleArsenalSwap_TBC.toc
grep -qx '## SavedVariablesPerCharacter: SimpleArsenalSwapDB' SimpleArsenalSwap_TBC.toc
grep -qx '## X-Flavor: TBC' SimpleArsenalSwap_TBC.toc
grep -qx '## AllowLoadGameType: tbc' SimpleArsenalSwap_TBC.toc
grep -Fqx '## IconTexture: Interface\AddOns\SimpleArsenalSwap\assets\logo' SimpleArsenalSwap_TBC.toc
test -f assets/logo.png
test -f tools/windows/Deploy-WoW-Addons.cmd
test -f tools/windows/Deploy-WoW-Addons.ps1

echo "All Lua 5.1 and TOC checks passed."
