# Yedek script'leri

Docker Compose ile çalışan bir uygulamanın PostgreSQL'ini yedekler, yedeğin gerçekten
geri yüklenebildiğini haftada bir dener ve sonuçları **dash**'e (`dash.uccergel.com`)
bildirir. dash yedek almaz; yalnızca izler ve gecikince uyarır.
Güvenlik listesi: `standards/security.md` → "Loglama ve kurtarma" (G-12).

| Script | Ne yapar | Ne sıklıkla |
|--------|----------|-------------|
| `pg-backup.sh` | `pg_dump` → gzip → `BACKUP_DIR`; eskileri siler; isteğe bağlı sunucu dışı kopya | Her gece |
| `pg-restore-test.sh` | En yeni yedeği **geçici, ağsız** bir Postgres konteynerine açar, tablo sayısını kontrol eder, konteyneri siler | Haftada bir |

İkisi de sonucu (başarılı/başarısız, boyut, süre, kısa not) dash'e gönderir. Not yalnızca
**hangi adımın** düştüğünü söyler; ham hata çıktısı (bağlantı dizesi vb.) sunucudan çıkmaz,
cron loguna yazılır.

## Kurulum (sunucuda, uygulama başına bir kez)

1. **Script'ler** (tüm uygulamalar için bir kez):

   ```bash
   sudo git clone https://github.com/uccergel/dev-standards.git /opt/dev-standards
   ```

   Güncellemek için: `sudo git -C /opt/dev-standards pull`.

2. **dash'te token:** uygulamanın sayfası → Yedek → "Yedek izlemeyi aç". Gösterilen satırlar
   ortam dosyasına gider; token **yalnızca bir kez** gösterilir (dash yalnızca hash'ini tutar).

3. **Ortam dosyası** — yalnızca root okuyabilsin (token içerir):

   ```bash
   sudo install -d -m 700 /etc/dash-backup
   ```

   ```bash
   sudo install -m 600 /dev/null /etc/dash-backup/lectio.env
   ```

   İçeriği (dash'in verdiği satırlar + proje adı):

   ```bash
   APP_SLUG=lectio
   DASH_URL=https://dash.uccergel.com
   DASH_BACKUP_TOKEN=dbk_…
   COMPOSE_PROJECT=lectio-abc123   # Dokploy'daki compose proje adı (aşağıya bak)
   # BACKUP_DIR=/var/backups/lectio   (varsayılan)
   # KEEP_DAYS=14
   # RCLONE_REMOTE=b2:yedek/lectio    (sunucu dışı kopya)
   ```

   **`COMPOSE_PROJECT` nasıl bulunur:** sunucuda

   ```bash
   docker ps --format '{{.Names}}\t{{.Label "com.docker.compose.project"}}' | grep db
   ```

   Script `COMPOSE_PROJECT` + `DB_SERVICE` (varsayılan `db`) etiketleriyle **tam bir**
   konteyner bulmalı; bulamazsa ya da birden çok bulursa yedek almadan durur ve dash'e
   "başarısız" bildirir. Aynı sunucuda birden çok Postgres olduğu için imaj adına göre arama
   yapılmaz.

4. **İlk deneme** (elle):

   ```bash
   sudo /opt/dev-standards/scripts/pg-backup.sh /etc/dash-backup/lectio.env
   ```

   ```bash
   sudo /opt/dev-standards/scripts/pg-restore-test.sh /etc/dash-backup/lectio.env
   ```

   dash'teki Yedek bölümü "Sağlıklı" göstermeli.

5. **Cron** (`sudo crontab -e`; saatler sunucu saat diliminde):

   ```
   0 3 * * *  /opt/dev-standards/scripts/pg-backup.sh       /etc/dash-backup/lectio.env >> /var/log/dash-backup.log 2>&1
   30 4 * * 0 /opt/dev-standards/scripts/pg-restore-test.sh /etc/dash-backup/lectio.env >> /var/log/dash-backup.log 2>&1
   ```

   Her uygulama için aynı iki satır, kendi `.env` dosyasıyla. Saatleri birkaç dakika kaydır
   (üçü aynı anda çalışmasın).

## dash'in uyarıları

| Durum | dash'te | Telegram |
|-------|---------|----------|
| Son yedek başarısız | yüksek öneri | günde bir (sessiz saatlerde ertelenir) |
| 26 saattir başarılı yedek yok | yüksek öneri | günde bir |
| Geri yükleme hiç denenmedi / 8 günden eski / başarısız | orta öneri | günlük özette |

## Elle geri yükleme (gerçek kurtarma)

Önce uygulamayı durdur (yazma olmasın), sonra boş bir veritabanına:

```bash
gunzip -c /var/backups/lectio/lectio-YYYYMMDD-HHMMSS.sql.gz | docker exec -i <db-konteyneri> sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

Yedek `--no-owner --no-privileges` ile alınır: hedefteki kullanıcıya göre geri yüklenir.

## Dikkat

- **Aynı sunucudaki yedek, sunucunun kaybına karşı korumaz.** `RCLONE_REMOTE` ile sunucu
  dışına kopyala; hedefte şifreli depolama (rclone `crypt`) kullan.
- Yedekler `umask 077` ile yazılır (yalnızca sahibi okur): uygulama verisi içerir.
- `pg_dump` düşerse yarım dosya "başarılı" sayılmaz (`set -o pipefail` + `gzip -t`).
- Geri yükleme denemesi uygulamanın veritabanına dokunmaz; geçici konteyner `--network none`
  ile açılır ve iş bitince (hata olsa bile) silinir. İmajı, uygulamanın db konteyneriyle aynıdır.
- dash'e bildirim düşerse yedeğin sonucu değişmez; cron loguna uyarı yazılır. Token komut
  satırına değil curl'ün stdin'ine verilir (`ps` çıktısında görünmez).
