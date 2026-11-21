#!/usr/bin/env bash
# Sunucu kaynak raporu: CPU, RAM, disk, çalışma süresi ve konteyner kullanımını okur,
# dash'e bildirir. dash sunucuya bağlanmaz; yalnızca bu raporu kabul eder.
# Kullanım ve kurulum: scripts/README.md → "Sunucu raporu"
#
#   server-report.sh /etc/dash-server/server.env      (cron: 5 dakikada bir)
#   server-report.sh --print /etc/dash-server/server.env   (göndermeden JSON'u yazdır)
#
# Ortam dosyası:
#   DASH_URL           dash adresi (ör. https://dash.uccergel.com)
#   DASH_SERVER_TOKEN  dash → Sunucu → "Sunucu ekle" ile verilen token (dsr_…)
#   DISK_PATH          izlenen dosya sistemi (varsayılan /)
#   CPU_SAMPLE_SEC     CPU ölçüm süresi, saniye (varsayılan 3)
#   APP_LOGS           giriş olayları sayılacak uygulamalar (isteğe bağlı), boşlukla ayrılmış
#                      "<dash-slug>=<compose-proje>:<servis>" (ör. "lectio=lectio-ab12:app")
#   STATE_DIR          son log okuma anının tutulduğu klasör (varsayılan /var/lib/dash-server)
#
# Yalnızca /proc, df, `docker stats` ve `docker logs` okur; sunucuda yalnızca kendi durum
# dosyasını yazar. Root gerekmez, ama docker grubunda olmayan kullanıcıyla konteyner
# bilgisi ve giriş sayıları gelmez.
set -euo pipefail

PRINT=0
if [ "${1:-}" = "--print" ]; then
  PRINT=1
  shift
fi
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
DISK_PATH="${DISK_PATH:-/}"
CPU_SAMPLE_SEC="${CPU_SAMPLE_SEC:-3}"
STATE_DIR="${STATE_DIR:-/var/lib/dash-server}"

log() { echo "$(date -Iseconds) [server-report] $*" >&2; }

# JSON için metin kaçışı: yalnızca " ve \ ; kontrol karakterleri boşluğa.
json_str() { printf '%s' "$1" | tr '\000-\037' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# CPU: /proc/stat'ın iki okuması arasındaki boşta olmayan oran (iowait boşta sayılır).
cpu_times() { awk '/^cpu /{ idle=$5+$6; total=0; for(i=2;i<=NF;i++) total+=$i; print idle, total }' /proc/stat; }
read -r idle1 total1 < <(cpu_times)
sleep "$CPU_SAMPLE_SEC"
read -r idle2 total2 < <(cpu_times)
cpu_pct="$(awk -v i="$((idle2 - idle1))" -v t="$((total2 - total1))" 'BEGIN { v = t > 0 ? (1 - i / t) * 100 : 0; if (v < 0) v = 0; if (v > 100) v = 100; printf "%.1f", v }')"
cpu_count="$(nproc)"
read -r load1 load5 load15 _ < /proc/loadavg

# Bellek: kB → bayt. MemAvailable önbelleği "kullanılabilir" sayar.
meminfo() { awk -v k="$1:" '$1 == k { print $2 * 1024; exit }' /proc/meminfo; }
mem_total="$(meminfo MemTotal)"
mem_avail="$(meminfo MemAvailable)"
swap_total="$(meminfo SwapTotal)"
swap_free="$(meminfo SwapFree)"

read -r disk_total disk_used < <(df -B1 --output=size,used "$DISK_PATH" | tail -n 1)
uptime_sec="$(awk '{ printf "%d", $1 }' /proc/uptime)"

# Konteynerler: docker stats metinleri olduğu gibi gider ("1.2%", "120MiB / 7.6GiB");
# dash sayıya çevirir. Docker yoksa ya da erişilemezse boş dizi (rapor yine gider).
containers="[]"
if command -v docker >/dev/null 2>&1; then
  if stats="$(timeout 20 docker stats --no-stream --format '{{.Name}}	{{.CPUPerc}}	{{.MemUsage}}' 2>/dev/null)"; then
    items=()
    while IFS=$'\t' read -r name cpu mem; do
      [ -n "$name" ] || continue
      items+=("$(printf '{"name":"%s","cpu":"%s","mem":"%s"}' "$(json_str "$name")" "$(json_str "$cpu")" "$(json_str "$mem")")")
      [ "${#items[@]}" -lt 60 ] || break
    done <<< "$stats"
    if [ "${#items[@]}" -gt 0 ]; then
      containers="[$(IFS=,; echo "${items[*]}")]"
    fi
  else
    log "UYARI: docker stats okunamadı (yetki?) — konteyner bilgisi gönderilmiyor"
  fi
fi

# Giriş olayları (APP_LOGS doluysa): her uygulamanın konteyner loglarında son rapordan
# bu yana yazılan güvenlik olayları sayılır. dash'e yalnızca sayılar gider; kullanıcı
# adı, IP ve ham log sunucudan çıkmaz. Son okuma anı STATE_DIR'de tutulur ve yalnızca
# rapor dash'e ulaşınca ilerletilir: gönderim düşerse aynı aralık bir sonraki çalışmada
# yeniden sayılır, olay kaybolmaz.
#
# Olay adı yalnızca SABİT KONUMDAN okunur; kullanıcının yazdığı metin (kullanıcı adı)
# satırın daha sonraki alanlarında durur ve sayımı taklit edemez.
#   Node (Lectio, dash):  <ts> [security] <olay> {...}
#   Django (Bereket):     <ts> <tarih> <saat> <SEVİYE> bereket.security <olay> ...
COUNT_AWK='
{
  ev = ""
  if ($2 == "[security]") ev = $3
  else if ($5 == "bereket.security") ev = $6
  if (ev == "login_ok") { ok++; last = $1 }
  else if (ev == "login_failed") failed++
  else if (ev == "login_locked") locked++
  else if (ev == "login_denied") denied++
  else if (ev == "throttled") throttled++
}
END { printf "%d %d %d %d %d %s\n", ok, failed, locked, denied, throttled, (last == "" ? "-" : last) }'

logins="[]"
logs_until=""
if [ -n "${APP_LOGS:-}" ] && command -v docker >/dev/null 2>&1; then
  logs_until="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  since=""
  [ -r "$STATE_DIR/logs-since" ] && since="$(cat "$STATE_DIR/logs-since")"
  # İlk çalışmada, bozuk ya da bir günden eski durumda son 5 dakika.
  if ! since_s="$(date -u -d "$since" +%s 2>/dev/null)" || [ -z "$since" ] \
      || [ "$since_s" -lt "$(( $(date -u +%s) - 86400 ))" ]; then
    since="$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)"
  fi
  items=()
  for entry in $APP_LOGS; do
    slug="${entry%%=*}"
    target="${entry#*=}"
    project="${target%%:*}"
    service="${target#*:}"
    case "$slug" in ''|*[!a-z0-9-]*) log "UYARI: APP_LOGS girdisi geçersiz: $entry"; continue ;; esac
    if [ "$target" = "$entry" ] || [ "$service" = "$target" ]; then
      log "UYARI: APP_LOGS girdisi <slug>=<proje>:<servis> biçiminde olmalı: $entry"
      continue
    fi
    ids="$(docker ps -q \
      --filter "label=com.docker.compose.project=$project" \
      --filter "label=com.docker.compose.service=$service" 2>/dev/null || true)"
    count="$(printf '%s' "$ids" | grep -c . || true)"
    if [ "$count" -ne 1 ]; then
      log "UYARI: $slug için konteyner bulunamadı ya da birden çok ($count): $project:$service"
      continue
    fi
    if ! read -r ok failed locked denied throttled last < <(
        timeout 30 docker logs --timestamps --since "$since" --until "$logs_until" "$ids" 2>&1 | awk "$COUNT_AWK"); then
      log "UYARI: $slug logları okunamadı"
      continue
    fi
    last_json="null"
    if [ "$last" != "-" ]; then
      # docker zaman damgası nanosaniyeli (…:06.123456789Z): saniyeye kısaltılır.
      t="${last%%.*}"
      last_json="\"${t%Z}Z\""
    fi
    items+=("$(printf '{"app":"%s","ok":%s,"failed":%s,"locked":%s,"denied":%s,"throttled":%s,"lastOkAt":%s}' \
      "$slug" "$ok" "$failed" "$locked" "$denied" "$throttled" "$last_json")")
  done
  if [ "${#items[@]}" -gt 0 ]; then
    logins="[$(IFS=,; echo "${items[*]}")]"
  fi
fi

body="$(printf '{"cpuPct":%s,"cpuCount":%s,"load":[%s,%s,%s],"memTotalBytes":%s,"memAvailableBytes":%s,"swapTotalBytes":%s,"swapFreeBytes":%s,"diskPath":"%s","diskTotalBytes":%s,"diskUsedBytes":%s,"uptimeSec":%s,"containers":%s,"logins":%s}' \
  "$cpu_pct" "$cpu_count" "$load1" "$load5" "$load15" \
  "$mem_total" "$mem_avail" "$swap_total" "$swap_free" \
  "$(json_str "$DISK_PATH")" "$disk_total" "$disk_used" "$uptime_sec" "$containers" "$logins")"

if [ "$PRINT" = 1 ]; then
  printf '%s\n' "$body"
  exit 0
fi

: "${DASH_URL:?DASH_URL gerekli}"
: "${DASH_SERVER_TOKEN:?DASH_SERVER_TOKEN gerekli}"
# Token komut satırında değil, stdin'den başlık olarak gider (ps çıktısında görünmesin).
if ! printf 'Authorization: Bearer %s\n' "$DASH_SERVER_TOKEN" | curl -sS --max-time 15 --fail \
    -H @- -H 'Content-Type: application/json' --data "$body" \
    "${DASH_URL%/}/api/server/report" >/dev/null; then
  log "UYARI: rapor dash'e gönderilemedi"
  exit 1
fi

# Rapor ulaştı: log sayımı bir sonraki çalışmada buradan devam etsin.
if [ -n "$logs_until" ]; then
  (umask 077 && mkdir -p "$STATE_DIR" && printf '%s\n' "$logs_until" > "$STATE_DIR/logs-since") \
    || log "UYARI: durum dosyası yazılamadı: $STATE_DIR/logs-since"
fi
