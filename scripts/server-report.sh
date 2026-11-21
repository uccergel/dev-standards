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
#
# Yalnızca /proc, df ve `docker stats` okur; hiçbir şey değiştirmez. Root gerekmez,
# ama docker grubunda olmayan kullanıcıyla konteyner bilgisi gelmez.
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

body="$(printf '{"cpuPct":%s,"cpuCount":%s,"load":[%s,%s,%s],"memTotalBytes":%s,"memAvailableBytes":%s,"swapTotalBytes":%s,"swapFreeBytes":%s,"diskPath":"%s","diskTotalBytes":%s,"diskUsedBytes":%s,"uptimeSec":%s,"containers":%s}' \
  "$cpu_pct" "$cpu_count" "$load1" "$load5" "$load15" \
  "$mem_total" "$mem_avail" "$swap_total" "$swap_free" \
  "$(json_str "$DISK_PATH")" "$disk_total" "$disk_used" "$uptime_sec" "$containers")"

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
