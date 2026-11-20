#!/usr/bin/env bash
# Geri yükleme denemesi: en yeni yedeği geçici, ağsız bir Postgres konteynerine açar,
# tablo sayısını kontrol eder, konteyneri siler ve sonucu dash'e bildirir.
# Uygulamanın veritabanına DOKUNMAZ. Kullanım: scripts/README.md
#
#   pg-restore-test.sh /etc/dash-backup/lectio.env
#
# Ek ortam (ortaklar için bkz. lib/common.sh):
#   MIN_TABLES      en az bu kadar tablo açılmalı (varsayılan 1)
#   RESTORE_IMAGE   geçici konteyner imajı; boşsa uygulamanın db konteynerinin imajı
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "$(readlink -f "$0")")/lib/common.sh"
load_env "${1:-}"
MIN_TABLES="${MIN_TABLES:-1}"

started="$(now_ms)"
step="başlangıç"
tmp=""
cleanup() { [ -n "$tmp" ] && docker rm -f "$tmp" >/dev/null 2>&1 || true; }
fail() {
  local code=$?
  log "BAŞARISIZ: $step"
  report restore-test false null "$(( $(now_ms) - started ))" "$step adımı başarısız"
  exit "$code"
}
trap cleanup EXIT
trap fail ERR

step="yedek dosyası"
# Dosya adlarını bu script üretir (APP_SLUG doğrulanmış + tarih): ls burada güvenli.
# shellcheck disable=SC2012
latest="$(ls -1t "$BACKUP_DIR"/"$APP_SLUG"-*.sql.gz 2>/dev/null | head -n1)"
[ -n "$latest" ]

step="imaj"
if [ -z "${RESTORE_IMAGE:-}" ]; then
  RESTORE_IMAGE="$(docker inspect --format '{{.Config.Image}}' "$(find_db_container)")"
fi

step="geçici konteyner"
# Ağsız (--network none): yedek içeriği dışarı çıkamaz, dışarıdan erişilemez.
tmp="restore-test-$APP_SLUG-$$"
docker run -d --rm --network none --name "$tmp" \
  -e POSTGRES_PASSWORD="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')" \
  -e POSTGRES_DB=restore "$RESTORE_IMAGE" >/dev/null

step="postgres açılışı"
ready=""
for _ in $(seq 1 60); do
  if docker exec "$tmp" pg_isready -U postgres -d restore >/dev/null 2>&1; then ready=1; break; fi
  sleep 1
done
[ -n "$ready" ]

step="geri yükleme"
gunzip -c "$latest" | docker exec -i "$tmp" psql -v ON_ERROR_STOP=1 -q -U postgres -d restore >/dev/null

step="tablo kontrolü"
tables="$(docker exec "$tmp" psql -U postgres -d restore -tAc \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'")"
[ "$tables" -ge "$MIN_TABLES" ]

trap - ERR
log "geri yükleme başarılı: $(basename "$latest") → $tables tablo"
report restore-test true "$(stat -c %s "$latest")" "$(( $(now_ms) - started ))" "$(basename "$latest"): $tables tablo"
