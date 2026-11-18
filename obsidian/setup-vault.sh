#!/bin/bash
# Merkezi Obsidian vault'unu kurar (macOS / Linux).
#
# Kullanim:  ./setup-vault.sh KOD_KLASORU [VAULT_KLASORU]
#   KOD_KLASORU   : tum repolarin durdugu klasor (ornek: ~/kod)
#   VAULT_KLASORU : vault'un olusturulacagi yer (varsayilan: ~/Obsidian/dev)
#
# KOD_KLASORU altindaki her repo icin:
#   - wiki/ klasoru varsa      -> VAULT/<repo>  ->  <repo>/wiki  (symlink)
#   - repo dev-standards ise   -> VAULT/standards -> dev-standards (symlink)
# Tekrar calistirmak guvenlidir: var olan baglantilara ve dosyalara dokunmaz.
# Yeni bir repo klonladiginda script'i yeniden calistirman yeterli.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Kullanim: $0 KOD_KLASORU [VAULT_KLASORU]" >&2
  exit 1
fi

CODE="$(cd "$1" && pwd)"
VAULT="${2:-$HOME/Obsidian/dev}"
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$VAULT"

link() {  # link HEDEF_YOL KAYNAK_KLASOR
  if [ -e "$1" ] || [ -L "$1" ]; then
    echo "Atlandi:  $1 zaten var"
  else
    ln -s "$2" "$1"
    echo "Baglandi: $1 -> $2"
  fi
}

for repo in "$CODE"/*/; do
  repo="${repo%/}"
  name="$(basename "$repo")"
  if [ "$name" = "dev-standards" ]; then
    link "$VAULT/standards" "$repo"
  elif [ -d "$repo/wiki" ]; then
    link "$VAULT/$name" "$repo/wiki"
  fi
done

if [ ! -d "$VAULT/.obsidian" ]; then
  mkdir -p "$VAULT/.obsidian"
  echo '{"useMarkdownLinks": true, "newLinkFormat": "relative", "alwaysUpdateLinks": true}' \
    > "$VAULT/.obsidian/app.json"
  echo '{"folder": "standards/templates/wiki"}' > "$VAULT/.obsidian/templates.json"
  echo "Obsidian ayarlari yazildi: $VAULT/.obsidian"
fi

if [ ! -f "$VAULT/ana-sayfa.md" ]; then
  cp "$HERE/ana-sayfa.md" "$VAULT/ana-sayfa.md"
  echo "Ana sayfa olusturuldu: $VAULT/ana-sayfa.md"
fi

echo "Vault hazir: $VAULT"
