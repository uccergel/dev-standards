# shellcheck shell=bash
# pg-backup.sh ve pg-restore-test.sh için ortak parçalar. Doğrudan çalıştırılmaz.

# Ortam dosyası (ilk argüman) yüklenir: cron satırı tek dosya yolu verir.
#   APP_SLUG           zorunlu; yedek dosyası öneki ve log adı (ör. lectio)
#   COMPOSE_PROJECT    Dokploy compose proje adı; db konteyneri bununla bulunur
#   DB_SERVICE         compose'taki veritabanı servisi (varsayılan: db)
#   DB_CONTAINER       doluysa COMPOSE_PROJECT yerine doğrudan bu konteyner
#   BACKUP_DIR         yedek klasörü (varsayılan: /var/backups/$APP_SLUG)
#   DASH_URL           doluysa sonuç dash'e bildirilir (ör. https://dash.uccergel.com)
#   DASH_BACKUP_TOKEN  dash'te uygulamanın "Yedek izlemeyi aç" ile verilen token'ı
load_env() {
  if [ -n "${1:-}" ]; then
    if [ ! -r "$1" ]; then
      echo "Ortam dosyası okunamıyor: $1" >&2
      exit 2
    fi
    set -a
    # shellcheck disable=SC1090
    . "$1"
    set +a
  fi
  : "${APP_SLUG:?APP_SLUG gerekli}"
  case "$APP_SLUG" in *[!a-z0-9-]*) echo "APP_SLUG yalnızca küçük harf, rakam ve tire" >&2; exit 2 ;; esac
  DB_SERVICE="${DB_SERVICE:-db}"
  BACKUP_DIR="${BACKUP_DIR:-/var/backups/$APP_SLUG}"
}

log() { echo "$(date -Iseconds) [$APP_SLUG] $*"; }

# Veritabanı konteynerini bulur: tam bir tane olmalı, yoksa durur (yanlış DB'yi
# yedeklemek yedeksiz kalmaktan kötü: aynı sunucuda birden çok Postgres var).
find_db_container() {
  if [ -n "${DB_CONTAINER:-}" ]; then
    echo "$DB_CONTAINER"
    return
  fi
  : "${COMPOSE_PROJECT:?COMPOSE_PROJECT ya da DB_CONTAINER gerekli}"
  local ids count
  ids="$(docker ps -q \
    --filter "label=com.docker.compose.project=$COMPOSE_PROJECT" \
    --filter "label=com.docker.compose.service=$DB_SERVICE")"
  count="$(printf '%s' "$ids" | grep -c . || true)"
  if [ "$count" -ne 1 ]; then
    echo "db konteyneri bulunamadı ya da birden çok ($count): COMPOSE_PROJECT=$COMPOSE_PROJECT DB_SERVICE=$DB_SERVICE" >&2
    return 1
  fi
  echo "$ids"
}

now_ms() { date +%s%3N; }

# JSON için metin kaçışı: yalnızca " ve \ ; kontrol karakterleri boşluğa.
json_str() { printf '%s' "$1" | tr '\000-\037' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# dash'e sonuç bildirir: report <kind> <ok:true|false> <sizeBytes|null> <durationMs> <not>
# Token komut satırında değil, stdin'den başlık olarak gider (ps çıktısında görünmesin).
# Bildirim düşerse yedeğin sonucu değişmez; yalnızca uyarı yazılır.
report() {
  [ -n "${DASH_URL:-}" ] && [ -n "${DASH_BACKUP_TOKEN:-}" ] || return 0
  local body
  body="$(printf '{"kind":"%s","ok":%s,"sizeBytes":%s,"durationMs":%s,"note":"%s"}' \
    "$1" "$2" "$3" "$4" "$(json_str "$5")")"
  if ! printf 'Authorization: Bearer %s\n' "$DASH_BACKUP_TOKEN" | curl -sS --max-time 15 --fail \
      -H @- -H 'Content-Type: application/json' --data "$body" \
      "${DASH_URL%/}/api/backups/report" >/dev/null; then
    log "UYARI: sonuç dash'e bildirilemedi"
  fi
}
