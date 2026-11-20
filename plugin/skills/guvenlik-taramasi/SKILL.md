---
name: guvenlik-taramasi
description: Projeyi uccergel/dev-standards güvenlik kontrol listesine (standards/security.md) karşı madde madde tarar; her madde için kanıtlı (dosya:satır) sonuç ve önem sırasıyla bulgular üretir, düzeltmeyi onaya bırakır. Kullanıcı "güvenlik taraması", "güvenlik denetimi", "açık var mı", "/guvenlik-taramasi" dediğinde ya da internete açılacak / deploy'a dokunan bir değişiklik öncesinde kullan.
---

# Güvenlik taraması

Liste: `docs/standards/standards/security.md` (submodule yoksa
`https://github.com/uccergel/dev-standards/blob/main/standards/security.md`). Bu dosya
yalnızca **nasıl** tarayacağını anlatır; maddelerin kendisi orada.

## Kurallar

- **Kanıtsız sonuç yok.** Her ✅/❌ bir dosya:satır, komut çıktısı ya da yapılandırma
  değeri gösterir. Göremiyorsan ⚠️ "doğrulanamadı" de (ör. canlı başlıklar, Dokploy env'i).
- **Uygulanmayan madde** (ör. Django admin olmayan projede) `—` ve kısa gerekçe.
- **Düzeltme yok.** Tarama raporla biter; düzeltme ayrı iş, kullanıcı onayıyla.
- Secret değeri görürsen (repoda, geçmişte, logda) **değeri yazma**, yerini yaz.

## Madde başına nereye bakılır

| Alan | Bakılacak yer / komut |
|------|------------------------|
| Secret'lar | `git ls-files \| grep -iE '(^\|/)\.env($\|\.)\|\.pem$\|\.p12$\|Local\.xcconfig$'`; `.gitignore`; `.env.example`'da gerçek değer var mı; `SECRET_KEY`/`AUTH_SECRET` okunduğu yer — tanımsızsa fırlatıyor mu, varsayılana mı düşüyor; `VITE_*` / `EXPO_PUBLIC_*` içinde anahtar var mı |
| Geçmişte sızıntı | `git log -p -S 'SECRET_KEY' --all -- '*.py' '*.ts' '*.env*'` (sığ klonda sınırlı derinlikle; söyle) |
| Hız sınırı | login/token/refresh/parola/kayıt uçları; sınır var mı, anahtar ne. **İstemci IP'si nasıl alınıyor:** `X-Forwarded-For`'un ilk (sol) girdisi = sahte IP ile atlatılır (h3 `getRequestIP({xForwardedFor:true})`, Express `req.ip` + `trust proxy: true`). Doğrusu sağdan proxy sayısı kadar. Django'da `NUM_PROXIES` |
| Kayıt | Kayıt ucu var mı; ortam değişkeni tanımsızken açık mı; compose / Dokploy varsayılanı |
| Nesne düzeyinde yetki | Liste ve tekil sorgular sahip koşulu içeriyor mu; ilişki alanlarında (profil, kitap…) başkasının id'si kabul ediliyor mu |
| Oturum iptali | Refresh token blacklist / rotasyon; çıkış ve parola değişimi diğer oturumları düşürüyor mu |
| Yönetim yüzeyleri | Django admin, Swagger/OpenAPI, Prisma Studio, debug uçları — prod'da kapalı mı |
| HTTP başlıkları | Reverse proxy (Caddyfile, nginx.conf, Traefik etiketleri) ya da uygulama middleware'inde CSP, `X-Frame-Options`/`frame-ancestors`, `X-Content-Type-Options`, `Referrer-Policy`, HSTS. Canlı adres biliniyor ve ağ izin veriyorsa `curl -sI https://<alan>`; yoksa ⚠️ |
| CORS | İzinli origin listesi; `*` var mı |
| Girdi | İstek gövdesi üst sınırı, dosya yükleme tür/boyut sınırı, geçersiz parametrede 500 yerine 400 |
| Hata sızıntısı | Hata yanıtlarında stack trace / dış servisin ham gövdesi |
| Bağımlılıklar | `package.json`'da `"latest"` / `*`; `requirements.txt`'te sabitlenmemiş sürüm; `npm audit --omit=dev` ve `pip-audit` (kuruluysa; ağ yoksa ⚠️); Dockerfile/compose'da `:latest` imaj; CDN script'lerinde `@latest` |
| Konteyner | `docker.sock` bağlayan servis; root olarak çalışan imaj |
| Loglama | Başarısız giriş ve 429'lar ayrı/etiketli loglanıyor mu |
| Yedek | Veritabanı yedeği script'i / Dokploy yedeği belgelenmiş mi, geri yükleme denenmiş mi (genelde ⚠️) |
| Mobil / iOS | Token deposu (Keychain/SecureStore), erişim sınıfı, privacy cover, `DEVELOPMENT_TEAM` repoda mı |
| Veri bütünlüğü | Çok satırlı yazımlar transaction içinde mi; yarışa açık kurallar constraint/kilitle mi korunuyor |

Projenin kendi önceki denetimi varsa (`wiki/referans/guvenlik-denetimi.md`,
`security_error.md` vb.) oku: kapanmış bulguların regresyon testi hâlâ var mı, açık
olanlar hâlâ açık mı.

## Rapor

1. **Özet tablosu:** madde · durum (✅ ❌ ⚠️ —) · kanıt (dosya:satır / komut) · önem
   (🔴 hesap ele geçirme / kalıcı yetkisiz erişim, 🟠 savunma katmanı yok, 🟡 sınırlı etki,
   ⚪ hijyen).
2. **Bulgular** önem sırasıyla: belirti, neden önemli, önerilen düzeltme, tahmini boyut.
3. **Doğrulanamayanlar** ve kullanıcının kontrol etmesi gerekenler (Dokploy env'i, canlı
   başlıklar, yedek).
4. Kullanıcıya sor: rapor wiki'ye yazılsın mı (projede denetim belgesi varsa onu güncelle,
   yoksa `wiki/referans/guvenlik-denetimi.md`), hangi bulgular düzeltilsin. Wiki'ye
   yazarken özet tablosu `standards/security.md` → "Denetim belgesi" biçiminde olur
   (kimlik · önem · bulgu · `Durum`); mevcut belgede `Durum` sütunu yoksa ekle ve her
   bulgunun durumunu belgedeki kanıttan doldur, tahmin etme.
