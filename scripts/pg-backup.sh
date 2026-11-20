#!/usr/bin/env bash
# PostgreSQL yedeği: çalışan db konteynerinden pg_dump → gzip → BACKUP_DIR,
# eski yedekleri siler, isteğe bağlı sunucu dışına kopyalar ve sonucu dash'e bildirir.
# Kullanım ve kurulum: scripts/README.md
#
#   pg-backup.sh /etc/dash-backup/lectio.env
#
# Ek ortam (ortaklar için bkz. lib/common.sh):
#   KEEP_DAYS      bundan eski yedekler silinir (varsayılan 14)
#   RCLONE_REMOTE  doluysa yedek rclone ile oraya da kopyalanır (ör. b2:yedek/lectio)
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "$(readlink -f "$0")")/lib/common.sh"
load_env "${1:-}"
KEEP_DAYS="${KEEP_DAYS:-14}"

started="$(now_ms)"
step="başlangıç"
fail() {
  local code=$?
  log "BAŞARISIZ: $step"
  # Not yalnızca adımın adı: ham komut çıktısı (bağlantı dizesi vb.) dash'e gitmez.
  report backup false null "$(( $(now_ms) - started ))" "$step adımı başarısız"
  exit "$code"
}
trap fail ERR

step="db konteyneri"
container="$(find_db_container)"

umask 077 # yedek uygulama verisi: yalnızca sahibi okuyabilsin
mkdir -p "$BACKUP_DIR"
out="$BACKUP_DIR/$APP_SLUG-$(date +%Y%m%d-%H%M%S).sql.gz"

step="pg_dump"
# pipefail: pg_dump düşerse yarım dosya "başarılı" sayılmaz (.tmp olarak kalır, sonra silinir).
docker exec "$container" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --no-privileges' \
  | gzip > "$out.tmp"
step="gzip doğrulama"
gzip -t "$out.tmp"
mv "$out.tmp" "$out"
size="$(stat -c %s "$out")"

if [ -n "${RCLONE_REMOTE:-}" ]; then
  step="sunucu dışı kopya"
  rclone copy "$out" "$RCLONE_REMOTE"
fi

step="eski yedekleri silme"
find "$BACKUP_DIR" -name "$APP_SLUG-*.sql.gz" -mtime +"$KEEP_DAYS" -delete
find "$BACKUP_DIR" -name "$APP_SLUG-*.sql.gz.tmp" -mmin +60 -delete

trap - ERR
log "yedek: $out ($size bayt)"
report backup true "$size" "$(( $(now_ms) - started ))" "${RCLONE_REMOTE:+sunucu dışına kopyalandı}"
